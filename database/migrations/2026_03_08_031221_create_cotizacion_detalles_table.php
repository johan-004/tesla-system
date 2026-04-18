<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
   {
     Schema::create('cotizacion_detalles', function (Blueprint $table) {
        $table->id();

        $table->foreignId('cotizacion_id')
              ->constrained('cotizaciones')
              ->onDelete('cascade');

        $table->string('categoria'); 
        // equipo | transporte | mano_obra

        $table->string('descripcion');
        $table->string('unidad');

        $table->decimal('cantidad', 10, 4);
        $table->decimal('precio_unitario', 12, 2);
        $table->decimal('subtotal', 12, 2);

        $table->timestamps();
       });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('cotizacion_detalles');
    }
};
