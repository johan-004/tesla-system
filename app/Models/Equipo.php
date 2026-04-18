<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Equipo extends Model
{
    public function up(): void
    {
    Schema::create('equipos', function (Blueprint $table) {
        $table->id();

        $table->foreignId('cotizacion_id')
              ->constrained()
              ->onDelete('cascade');

        $table->string('descripcion')->nullable();
        $table->string('unidad')->nullable();
        $table->decimal('cantidad', 8,2)->nullable();
        $table->decimal('valor_unitario', 12,2)->nullable();
        $table->decimal('total', 12,2)->nullable();

        $table->timestamps();
    });
    }
    public function cotizacion()
{
    return $this->belongsTo(\App\Models\Cotizacion::class);
}
}
