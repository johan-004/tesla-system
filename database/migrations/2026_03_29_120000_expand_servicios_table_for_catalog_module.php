<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('servicios', function (Blueprint $table) {
            if (! Schema::hasColumn('servicios', 'categoria')) {
                $table->string('categoria', 120)->default('general')->after('descripcion');
            }

            if (! Schema::hasColumn('servicios', 'unidad')) {
                $table->string('unidad', 50)->default('servicio')->after('categoria');
            }

            if (! Schema::hasColumn('servicios', 'precio_unitario')) {
                $table->decimal('precio_unitario', 14, 2)->default(0)->after('unidad');
            }

            if (! Schema::hasColumn('servicios', 'iva')) {
                $table->decimal('iva', 14, 2)->default(0)->after('precio_unitario');
            }

            if (! Schema::hasColumn('servicios', 'precio_con_iva')) {
                $table->decimal('precio_con_iva', 14, 2)->default(0)->after('iva');
            }

            if (! Schema::hasColumn('servicios', 'observaciones')) {
                $table->text('observaciones')->nullable()->after('precio_con_iva');
            }
        });

        $categorias = DB::table('categorias_servicio')
            ->pluck('nombre', 'id');

        DB::table('servicios')
            ->orderBy('id')
            ->get()
            ->each(function (object $servicio) use ($categorias) {
                $codigo = $servicio->codigo ?: sprintf('SER-%03d', $servicio->id);
                $descripcion = trim((string) ($servicio->descripcion ?: $servicio->nombre ?: 'Servicio ' . $servicio->id));
                $categoria = trim((string) ($servicio->categoria ?: $categorias[$servicio->categoria_servicio_id] ?? 'general'));
                $precioUnitario = $servicio->precio_unitario ?? $servicio->precio_base ?? 0;
                $iva = $servicio->iva ?? 0;
                $precioConIva = $servicio->precio_con_iva ?? ($precioUnitario + $iva);

                DB::table('servicios')
                    ->where('id', $servicio->id)
                    ->update([
                        'codigo' => $codigo,
                        'nombre' => mb_substr($descripcion, 0, 255),
                        'descripcion' => $descripcion,
                        'categoria' => $categoria,
                        'unidad' => trim((string) ($servicio->unidad ?: 'servicio')),
                        'precio_unitario' => $precioUnitario,
                        'iva' => $iva,
                        'precio_con_iva' => $precioConIva,
                    ]);
            });
    }

    public function down(): void
    {
        Schema::table('servicios', function (Blueprint $table) {
            if (Schema::hasColumn('servicios', 'observaciones')) {
                $table->dropColumn('observaciones');
            }

            if (Schema::hasColumn('servicios', 'precio_con_iva')) {
                $table->dropColumn('precio_con_iva');
            }

            if (Schema::hasColumn('servicios', 'iva')) {
                $table->dropColumn('iva');
            }

            if (Schema::hasColumn('servicios', 'precio_unitario')) {
                $table->dropColumn('precio_unitario');
            }

            if (Schema::hasColumn('servicios', 'unidad')) {
                $table->dropColumn('unidad');
            }

            if (Schema::hasColumn('servicios', 'categoria')) {
                $table->dropColumn('categoria');
            }
        });
    }
};
