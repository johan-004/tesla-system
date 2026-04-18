<?php

use App\Models\Cotizacion;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        $this->normalizeLegacyEstados();

        Schema::table('cotizaciones', function (Blueprint $table) {
            if (! Schema::hasColumn('cotizaciones', 'numero')) {
                $table->string('numero', 20)->nullable()->after('id')->unique();
            }
            if (! Schema::hasColumn('cotizaciones', 'ciudad')) {
                $table->string('ciudad', 120)->nullable()->after('fecha');
            }
            if (! Schema::hasColumn('cotizaciones', 'cliente_nombre')) {
                $table->string('cliente_nombre')->nullable()->after('ciudad');
            }
            if (! Schema::hasColumn('cotizaciones', 'cliente_nit')) {
                $table->string('cliente_nit', 80)->nullable()->after('cliente_nombre');
            }
            if (! Schema::hasColumn('cotizaciones', 'cliente_contacto')) {
                $table->string('cliente_contacto', 150)->nullable()->after('cliente_nit');
            }
            if (! Schema::hasColumn('cotizaciones', 'cliente_cargo')) {
                $table->string('cliente_cargo', 150)->nullable()->after('cliente_contacto');
            }
            if (! Schema::hasColumn('cotizaciones', 'cliente_direccion')) {
                $table->string('cliente_direccion')->nullable()->after('cliente_cargo');
            }
            if (! Schema::hasColumn('cotizaciones', 'referencia')) {
                $table->string('referencia')->nullable()->after('cliente_direccion');
            }
            if (! Schema::hasColumn('cotizaciones', 'created_by')) {
                $table->foreignId('created_by')->nullable()->after('referencia')->constrained('users')->nullOnDelete();
            }
            if (! Schema::hasColumn('cotizaciones', 'updated_by')) {
                $table->foreignId('updated_by')->nullable()->after('created_by')->constrained('users')->nullOnDelete();
            }
        });

        if (Schema::hasColumn('cotizaciones', 'estado')) {
            Schema::table('cotizaciones', function (Blueprint $table) {
                $table->enum('estado', Cotizacion::ESTADOS)->default(Cotizacion::ESTADO_PENDIENTE)->change();
            });
        }

        $this->backfillExternalFields();
    }

    public function down(): void
    {
        if (Schema::hasColumn('cotizaciones', 'updated_by')) {
            Schema::table('cotizaciones', function (Blueprint $table) {
                $table->dropConstrainedForeignId('updated_by');
            });
        }

        if (Schema::hasColumn('cotizaciones', 'created_by')) {
            Schema::table('cotizaciones', function (Blueprint $table) {
                $table->dropConstrainedForeignId('created_by');
            });
        }

        Schema::table('cotizaciones', function (Blueprint $table) {
            $columns = [
                'numero',
                'ciudad',
                'cliente_nombre',
                'cliente_nit',
                'cliente_contacto',
                'cliente_cargo',
                'cliente_direccion',
                'referencia',
            ];

            foreach ($columns as $column) {
                if (Schema::hasColumn('cotizaciones', $column)) {
                    $table->dropColumn($column);
                }
            }
        });
    }

    private function normalizeLegacyEstados(): void
    {
        if (! Schema::hasColumn('cotizaciones', 'estado')) {
            return;
        }

        DB::table('cotizaciones')
            ->where('estado', 'borrador')
            ->update(['estado' => Cotizacion::ESTADO_PENDIENTE]);
        DB::table('cotizaciones')
            ->where('estado', 'revisada')
            ->update(['estado' => Cotizacion::ESTADO_VISTO]);
        DB::table('cotizaciones')
            ->where('estado', 'aprobada')
            ->update(['estado' => Cotizacion::ESTADO_REALIZADA]);
        DB::table('cotizaciones')
            ->where('estado', 'anulada')
            ->update(['estado' => Cotizacion::ESTADO_NULA]);
    }

    private function backfillExternalFields(): void
    {
        $rows = DB::table('cotizaciones')
            ->select([
                'id',
                'cliente_id',
                'user_id',
                'codigo',
                'fecha',
                'estado',
                'obra',
                'descripcion',
                'numero',
                'ciudad',
                'cliente_nombre',
                'cliente_nit',
                'cliente_contacto',
                'cliente_direccion',
                'referencia',
                'created_by',
                'updated_by',
            ])
            ->orderBy('id')
            ->get();

        $sequenceByYear = [];

        foreach ($rows as $row) {
            $fecha = $row->fecha ? Carbon::parse($row->fecha) : now();
            $year = $fecha->year;
            $sequenceByYear[$year] = ($sequenceByYear[$year] ?? 0) + 1;

            $cliente = $row->cliente_id
                ? DB::table('clientes')
                    ->select(['nombre', 'documento', 'telefono', 'direccion'])
                    ->where('id', $row->cliente_id)
                    ->first()
                : null;

            DB::table('cotizaciones')
                ->where('id', $row->id)
                ->update([
                    'numero' => $row->numero ?: sprintf('COT-%d-%06d', $year, $sequenceByYear[$year]),
                    'ciudad' => $row->ciudad ?? '',
                    'cliente_nombre' => $row->cliente_nombre ?: ($cliente->nombre ?? 'Cliente pendiente'),
                    'cliente_nit' => $row->cliente_nit ?: ($cliente->documento ?? null),
                    'cliente_contacto' => $row->cliente_contacto ?: ($cliente->telefono ?? null),
                    'cliente_direccion' => $row->cliente_direccion ?: ($cliente->direccion ?? null),
                    'referencia' => $row->referencia ?: ($row->obra ?: ($row->descripcion ?: 'Sin referencia')),
                    'created_by' => $row->created_by ?? $row->user_id,
                    'updated_by' => $row->updated_by ?? $row->user_id,
                    'codigo' => $row->codigo ?: sprintf('COT-%d-%06d', $year, $sequenceByYear[$year]),
                    'estado' => in_array($row->estado, Cotizacion::ESTADOS, true)
                        ? $row->estado
                        : Cotizacion::ESTADO_PENDIENTE,
                ]);
        }
    }
};
