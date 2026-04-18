<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('productos', function (Blueprint $table) {
            $table->text('descripcion')->nullable()->after('nombre');
            $table->string('unidad_medida')->default('unidad')->after('stock');
            $table->boolean('activo')->default(true)->after('unidad_medida');
        });
    }

    public function down(): void
    {
        Schema::table('productos', function (Blueprint $table) {
            $table->dropColumn(['descripcion', 'unidad_medida', 'activo']);
        });
    }
};
