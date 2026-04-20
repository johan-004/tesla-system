<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('factura_items', function (Blueprint $table) {
            $table->dropForeign(['producto_id']);
        });

        Schema::table('factura_items', function (Blueprint $table) {
            $table->unsignedBigInteger('producto_id')->nullable()->change();
        });

        Schema::table('factura_items', function (Blueprint $table) {
            $table->foreign('producto_id')->references('id')->on('productos')->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::table('factura_items', function (Blueprint $table) {
            $table->dropForeign(['producto_id']);
        });

        $fallbackProductoId = DB::table('productos')->orderBy('id')->value('id');
        if ($fallbackProductoId === null) {
            DB::table('factura_items')->whereNull('producto_id')->delete();
        } else {
            DB::table('factura_items')->whereNull('producto_id')->update([
                'producto_id' => (int) $fallbackProductoId,
            ]);
        }

        Schema::table('factura_items', function (Blueprint $table) {
            $table->unsignedBigInteger('producto_id')->nullable(false)->change();
        });

        Schema::table('factura_items', function (Blueprint $table) {
            $table->foreign('producto_id')->references('id')->on('productos');
        });
    }
};
