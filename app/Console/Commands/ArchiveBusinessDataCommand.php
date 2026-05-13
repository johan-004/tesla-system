<?php

namespace App\Console\Commands;

use Carbon\CarbonImmutable;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;

class ArchiveBusinessDataCommand extends Command
{
    protected $signature = 'maintenance:archive-business-data
        {--years=5 : Mantener en producción los últimos N años}
        {--chunk=500 : Cantidad de registros por lote}
        {--output=storage/app/archives : Carpeta base para archivos históricos}
        {--execute : Ejecuta el archivo y limpieza (sin este flag solo simula)}';

    protected $description = 'Archiva y limpia facturas/cotizaciones antiguas con modo seguro (dry-run por defecto).';

    public function handle(): int
    {
        $years = max(1, (int) $this->option('years'));
        $chunk = max(100, (int) $this->option('chunk'));
        $execute = (bool) $this->option('execute');
        $cutoff = CarbonImmutable::now()->subYears($years)->startOfDay();

        $this->info('Mantenimiento histórico de negocio');
        $this->line("Cutoff: {$cutoff->toDateString()} (conserva {$years} años)");
        $this->line($execute
            ? 'Modo: EJECUCIÓN REAL (archiva y limpia)'
            : 'Modo: SIMULACIÓN (no modifica datos)');

        $facturaIds = $this->collectOldIds('facturas', 'fecha', $cutoff, $chunk);
        $cotizacionIds = $this->collectOldIds('cotizaciones', 'fecha', $cutoff, $chunk);

        $resumen = $this->buildSummary($facturaIds, $cotizacionIds);
        $this->table(
            ['Tabla', 'Registros'],
            [
                ['facturas', (string) $resumen['facturas']],
                ['factura_items', (string) $resumen['factura_items']],
                ['cotizaciones', (string) $resumen['cotizaciones']],
                ['cotizacion_detalles', (string) $resumen['cotizacion_detalles']],
            ]
        );

        if (! $execute) {
            $this->warn('No se aplicaron cambios. Para ejecutar realmente usa: --execute');

            return self::SUCCESS;
        }

        if ($resumen['facturas'] === 0 && $resumen['cotizaciones'] === 0) {
            $this->info('No hay datos antiguos para archivar.');

            return self::SUCCESS;
        }

        $folder = $this->prepareArchiveFolder((string) $this->option('output'));
        $this->line("Carpeta de archivo: {$folder}");

        $this->exportTableByIds('facturas', $facturaIds, $chunk, $folder);
        $this->exportTableByForeign('factura_items', 'factura_id', $facturaIds, $chunk, $folder);
        $this->exportTableByIds('cotizaciones', $cotizacionIds, $chunk, $folder);
        $this->exportTableByForeign('cotizacion_detalles', 'cotizacion_id', $cotizacionIds, $chunk, $folder);

        $this->cleanupArchivedData($facturaIds, $cotizacionIds, $chunk);

        $this->info('Archivo y limpieza completados correctamente.');
        $this->line("Respaldo generado en: {$folder}");

        return self::SUCCESS;
    }

    /**
     * @return array<int>
     */
    private function collectOldIds(string $table, string $dateColumn, CarbonImmutable $cutoff, int $chunk): array
    {
        $ids = [];

        DB::table($table)
            ->select('id')
            ->where(function ($query) use ($dateColumn, $cutoff): void {
                $query
                    ->where(function ($sub) use ($dateColumn, $cutoff): void {
                        $sub->whereNotNull($dateColumn)->whereDate($dateColumn, '<', $cutoff->toDateString());
                    })
                    ->orWhere(function ($sub) use ($cutoff): void {
                        $sub->whereNull('fecha')->whereDate('created_at', '<', $cutoff->toDateString());
                    });
            })
            ->orderBy('id')
            ->chunkById($chunk, function ($rows) use (&$ids): void {
                foreach ($rows as $row) {
                    $ids[] = (int) $row->id;
                }
            });

        return $ids;
    }

    /**
     * @param array<int> $facturaIds
     * @param array<int> $cotizacionIds
     * @return array<string,int>
     */
    private function buildSummary(array $facturaIds, array $cotizacionIds): array
    {
        return [
            'facturas' => count($facturaIds),
            'factura_items' => $this->countByForeign('factura_items', 'factura_id', $facturaIds),
            'cotizaciones' => count($cotizacionIds),
            'cotizacion_detalles' => $this->countByForeign('cotizacion_detalles', 'cotizacion_id', $cotizacionIds),
        ];
    }

    /**
     * @param array<int> $ids
     */
    private function countByForeign(string $table, string $column, array $ids): int
    {
        if ($ids === []) {
            return 0;
        }

        return (int) DB::table($table)->whereIn($column, $ids)->count();
    }

    private function prepareArchiveFolder(string $outputBase): string
    {
        $base = base_path(trim($outputBase, '/'));
        $folder = $base.'/archive_'.now()->format('Ymd_His');
        File::ensureDirectoryExists($folder);

        return $folder;
    }

    /**
     * @param array<int> $ids
     */
    private function exportTableByIds(string $table, array $ids, int $chunk, string $folder): void
    {
        if ($ids === []) {
            return;
        }

        $path = "{$folder}/{$table}.ndjson";
        $handle = fopen($path, 'wb');

        if ($handle === false) {
            throw new \RuntimeException("No fue posible crear {$path}");
        }

        foreach (array_chunk($ids, $chunk) as $batch) {
            $rows = DB::table($table)->whereIn('id', $batch)->orderBy('id')->get();
            foreach ($rows as $row) {
                fwrite($handle, json_encode((array) $row, JSON_UNESCAPED_UNICODE).PHP_EOL);
            }
        }

        fclose($handle);
    }

    /**
     * @param array<int> $ids
     */
    private function exportTableByForeign(string $table, string $column, array $ids, int $chunk, string $folder): void
    {
        if ($ids === []) {
            return;
        }

        $path = "{$folder}/{$table}.ndjson";
        $handle = fopen($path, 'wb');

        if ($handle === false) {
            throw new \RuntimeException("No fue posible crear {$path}");
        }

        foreach (array_chunk($ids, $chunk) as $batch) {
            $rows = DB::table($table)->whereIn($column, $batch)->orderBy('id')->get();
            foreach ($rows as $row) {
                fwrite($handle, json_encode((array) $row, JSON_UNESCAPED_UNICODE).PHP_EOL);
            }
        }

        fclose($handle);
    }

    /**
     * @param array<int> $facturaIds
     * @param array<int> $cotizacionIds
     */
    private function cleanupArchivedData(array $facturaIds, array $cotizacionIds, int $chunk): void
    {
        DB::transaction(function () use ($facturaIds, $cotizacionIds, $chunk): void {
            foreach (array_chunk($facturaIds, $chunk) as $batch) {
                DB::table('factura_items')->whereIn('factura_id', $batch)->delete();
                DB::table('facturas')->whereIn('id', $batch)->delete();
            }

            foreach (array_chunk($cotizacionIds, $chunk) as $batch) {
                DB::table('cotizacion_detalles')->whereIn('cotizacion_id', $batch)->delete();
                DB::table('cotizaciones')->whereIn('id', $batch)->delete();
            }
        });
    }
}
