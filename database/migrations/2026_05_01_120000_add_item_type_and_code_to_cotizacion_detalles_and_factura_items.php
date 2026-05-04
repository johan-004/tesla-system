<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('cotizacion_detalles', function (Blueprint $table) {
            if (! Schema::hasColumn('cotizacion_detalles', 'producto_id')) {
                $table->foreignId('producto_id')->nullable()->after('servicio_id')->constrained('productos')->nullOnDelete();
            }

            if (! Schema::hasColumn('cotizacion_detalles', 'codigo')) {
                $table->string('codigo', 80)->nullable()->after('categoria');
            }
        });

        Schema::table('factura_items', function (Blueprint $table) {
            if (! Schema::hasColumn('factura_items', 'servicio_id')) {
                $table->foreignId('servicio_id')->nullable()->after('producto_id')->constrained('servicios')->nullOnDelete();
            }

            if (! Schema::hasColumn('factura_items', 'tipo_item')) {
                $table->string('tipo_item', 20)->default('producto')->after('servicio_id');
            }

            if (! Schema::hasColumn('factura_items', 'codigo')) {
                $table->string('codigo', 80)->nullable()->after('tipo_item');
            }
        });
    }

    public function down(): void
    {
        Schema::table('factura_items', function (Blueprint $table) {
            if (Schema::hasColumn('factura_items', 'codigo')) {
                $table->dropColumn('codigo');
            }

            if (Schema::hasColumn('factura_items', 'tipo_item')) {
                $table->dropColumn('tipo_item');
            }

            if (Schema::hasColumn('factura_items', 'servicio_id')) {
                $table->dropConstrainedForeignId('servicio_id');
            }
        });

        Schema::table('cotizacion_detalles', function (Blueprint $table) {
            if (Schema::hasColumn('cotizacion_detalles', 'codigo')) {
                $table->dropColumn('codigo');
            }

            if (Schema::hasColumn('cotizacion_detalles', 'producto_id')) {
                $table->dropConstrainedForeignId('producto_id');
            }
        });
    }
};
