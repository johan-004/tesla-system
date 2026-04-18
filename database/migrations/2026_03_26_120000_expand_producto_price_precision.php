<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('productos', function (Blueprint $table) {
            $table->decimal('precio_compra', 14, 2)->change();
            $table->decimal('precio_venta', 14, 2)->change();
        });
    }

    public function down(): void
    {
        Schema::table('productos', function (Blueprint $table) {
            $table->decimal('precio_compra', 10, 2)->change();
            $table->decimal('precio_venta', 10, 2)->change();
        });
    }
};
