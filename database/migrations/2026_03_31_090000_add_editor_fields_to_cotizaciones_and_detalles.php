<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('cotizaciones', function (Blueprint $table) {
            if (! Schema::hasColumn('cotizaciones', 'cliente_ciudad')) {
                $table->string('cliente_ciudad', 120)->nullable()->after('cliente_cargo');
            }
        });

        Schema::table('cotizacion_detalles', function (Blueprint $table) {
            if (! Schema::hasColumn('cotizacion_detalles', 'servicio_id')) {
                $table->foreignId('servicio_id')->nullable()->after('cotizacion_id')->constrained('servicios')->nullOnDelete();
            }
        });
    }

    public function down(): void
    {
        Schema::table('cotizacion_detalles', function (Blueprint $table) {
            if (Schema::hasColumn('cotizacion_detalles', 'servicio_id')) {
                $table->dropConstrainedForeignId('servicio_id');
            }
        });

        Schema::table('cotizaciones', function (Blueprint $table) {
            if (Schema::hasColumn('cotizaciones', 'cliente_ciudad')) {
                $table->dropColumn('cliente_ciudad');
            }
        });
    }
};
