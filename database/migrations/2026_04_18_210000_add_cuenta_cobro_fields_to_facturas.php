<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('facturas', function (Blueprint $table) {
            $table->string('ciudad_expedicion', 120)->nullable()->after('fecha');
            $table->string('cliente_ciudad', 120)->nullable()->after('cliente_direccion');
            $table->string('firma_path')->nullable()->after('observaciones');
            $table->string('firma_nombre', 150)->nullable()->after('firma_path');
            $table->string('firma_cargo', 150)->nullable()->after('firma_nombre');
            $table->string('firma_empresa', 180)->nullable()->after('firma_cargo');
        });
    }

    public function down(): void
    {
        Schema::table('facturas', function (Blueprint $table) {
            $table->dropColumn([
                'ciudad_expedicion',
                'cliente_ciudad',
                'firma_path',
                'firma_nombre',
                'firma_cargo',
                'firma_empresa',
            ]);
        });
    }
};
