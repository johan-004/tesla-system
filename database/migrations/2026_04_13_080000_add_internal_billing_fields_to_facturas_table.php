<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('facturas', function (Blueprint $table) {
            $table->string('codigo', 40)->nullable()->after('id');
            $table->string('cliente_nombre')->nullable()->after('fecha');
            $table->string('cliente_nit', 80)->nullable()->after('cliente_nombre');
            $table->string('cliente_contacto', 150)->nullable()->after('cliente_nit');
            $table->string('cliente_direccion')->nullable()->after('cliente_contacto');
            $table->decimal('iva_total', 14, 2)->default(0)->after('subtotal');
            $table->foreignId('created_by')->nullable()->after('estado')->constrained('users')->nullOnDelete();
            $table->foreignId('updated_by')->nullable()->after('created_by')->constrained('users')->nullOnDelete();
            $table->timestamp('emitida_at')->nullable()->after('updated_by');
            $table->foreignId('emitida_by')->nullable()->after('emitida_at')->constrained('users')->nullOnDelete();
            $table->timestamp('anulada_at')->nullable()->after('emitida_by');
            $table->foreignId('anulada_by')->nullable()->after('anulada_at')->constrained('users')->nullOnDelete();

            $table->index(['estado', 'fecha']);
            $table->unique('codigo');
        });

        DB::table('facturas')
            ->select(['id', 'numero', 'codigo', 'impuestos'])
            ->orderBy('id')
            ->chunkById(200, function ($facturas) {
                foreach ($facturas as $factura) {
                    $codigo = trim((string) ($factura->codigo ?? ''));
                    $numero = trim((string) ($factura->numero ?? ''));
                    $resolved = $codigo !== '' ? $codigo : ($numero !== '' ? $numero : sprintf('FAC-%03d', $factura->id));
                    $alreadyExists = DB::table('facturas')
                        ->where('codigo', $resolved)
                        ->where('id', '!=', $factura->id)
                        ->exists();

                    if ($alreadyExists) {
                        $resolved = sprintf('%s-%d', $resolved, $factura->id);
                    }

                    DB::table('facturas')
                        ->where('id', $factura->id)
                        ->update([
                            'codigo' => $resolved,
                            'numero' => $resolved,
                            'iva_total' => (float) ($factura->impuestos ?? 0),
                        ]);
                }
            });
    }

    public function down(): void
    {
        Schema::table('facturas', function (Blueprint $table) {
            $table->dropUnique(['codigo']);
            $table->dropIndex(['estado', 'fecha']);

            $table->dropConstrainedForeignId('anulada_by');
            $table->dropColumn('anulada_at');
            $table->dropConstrainedForeignId('emitida_by');
            $table->dropColumn('emitida_at');
            $table->dropConstrainedForeignId('updated_by');
            $table->dropConstrainedForeignId('created_by');
            $table->dropColumn('iva_total');
            $table->dropColumn('cliente_direccion');
            $table->dropColumn('cliente_contacto');
            $table->dropColumn('cliente_nit');
            $table->dropColumn('cliente_nombre');
            $table->dropColumn('codigo');
        });
    }
};
