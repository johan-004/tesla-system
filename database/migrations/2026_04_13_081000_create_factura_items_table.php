<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('factura_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('factura_id')->constrained('facturas')->cascadeOnDelete();
            $table->foreignId('producto_id')->constrained('productos');
            $table->unsignedInteger('orden')->default(1);
            $table->text('descripcion');
            $table->string('unidad', 80);
            $table->decimal('cantidad', 14, 2)->default(0);
            $table->decimal('precio_unitario', 14, 2)->default(0);
            $table->decimal('iva_porcentaje', 6, 2)->default(0);
            $table->decimal('iva_valor', 14, 2)->default(0);
            $table->decimal('subtotal_linea', 14, 2)->default(0);
            $table->decimal('total_linea', 14, 2)->default(0);
            $table->timestamps();

            $table->index(['factura_id', 'orden']);
            $table->index('producto_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('factura_items');
    }
};
