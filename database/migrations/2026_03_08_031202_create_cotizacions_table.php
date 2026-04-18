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
    Schema::create('cotizaciones', function (Blueprint $table) {
       $table->id();
       $table->string('item');
       $table->string('obra');
       $table->text('descripcion');
       $table->string('unidad');
       $table->date('fecha');
       $table->decimal('factor_zona', 8, 2)->default(1);
       $table->decimal('aiu', 8, 2)->default(0);
       $table->decimal('total_costo_directo', 12, 2)->default(0);
       $table->decimal('total_costo_unitario', 12, 2)->default(0);
       $table->timestamps();
      });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('cotizaciones');
    }
};
