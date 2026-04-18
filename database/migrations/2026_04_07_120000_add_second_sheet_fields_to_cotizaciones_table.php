<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('cotizaciones', function (Blueprint $table) {
            if (! Schema::hasColumn('cotizaciones', 'alcance_items')) {
                $table->json('alcance_items')->nullable()->after('observaciones');
            }
            if (! Schema::hasColumn('cotizaciones', 'oferta_dias_totales')) {
                $table->unsignedSmallInteger('oferta_dias_totales')->default(30)->after('alcance_items');
            }
            if (! Schema::hasColumn('cotizaciones', 'oferta_dias_ejecucion')) {
                $table->unsignedSmallInteger('oferta_dias_ejecucion')->default(15)->after('oferta_dias_totales');
            }
            if (! Schema::hasColumn('cotizaciones', 'oferta_dias_tramitologia')) {
                $table->unsignedSmallInteger('oferta_dias_tramitologia')->default(15)->after('oferta_dias_ejecucion');
            }
            if (! Schema::hasColumn('cotizaciones', 'oferta_pago_1_pct')) {
                $table->decimal('oferta_pago_1_pct', 5, 2)->default(50)->after('oferta_dias_tramitologia');
            }
            if (! Schema::hasColumn('cotizaciones', 'oferta_pago_2_pct')) {
                $table->decimal('oferta_pago_2_pct', 5, 2)->default(25)->after('oferta_pago_1_pct');
            }
            if (! Schema::hasColumn('cotizaciones', 'oferta_pago_3_pct')) {
                $table->decimal('oferta_pago_3_pct', 5, 2)->default(25)->after('oferta_pago_2_pct');
            }
            if (! Schema::hasColumn('cotizaciones', 'oferta_garantia_meses')) {
                $table->unsignedSmallInteger('oferta_garantia_meses')->default(6)->after('oferta_pago_3_pct');
            }
            if (! Schema::hasColumn('cotizaciones', 'firma_path')) {
                $table->string('firma_path')->nullable()->after('oferta_garantia_meses');
            }
            if (! Schema::hasColumn('cotizaciones', 'firma_nombre')) {
                $table->string('firma_nombre')->default('María Alejandra Flórez Ocampo.')->after('firma_path');
            }
            if (! Schema::hasColumn('cotizaciones', 'firma_cargo')) {
                $table->string('firma_cargo')->default('Representante.')->after('firma_nombre');
            }
            if (! Schema::hasColumn('cotizaciones', 'firma_empresa')) {
                $table->string('firma_empresa')->default('Proyecciones eléctricas Tesla')->after('firma_cargo');
            }
        });
    }

    public function down(): void
    {
        Schema::table('cotizaciones', function (Blueprint $table) {
            $columns = [
                'alcance_items',
                'oferta_dias_totales',
                'oferta_dias_ejecucion',
                'oferta_dias_tramitologia',
                'oferta_pago_1_pct',
                'oferta_pago_2_pct',
                'oferta_pago_3_pct',
                'oferta_garantia_meses',
                'firma_path',
                'firma_nombre',
                'firma_cargo',
                'firma_empresa',
            ];

            foreach ($columns as $column) {
                if (Schema::hasColumn('cotizaciones', $column)) {
                    $table->dropColumn($column);
                }
            }
        });
    }
};
