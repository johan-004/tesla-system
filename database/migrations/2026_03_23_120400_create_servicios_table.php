<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('servicios', function (Blueprint $table) {
            $table->id();
            $table->foreignId('categoria_servicio_id')->constrained('categorias_servicio')->cascadeOnDelete();
            $table->string('codigo', 50)->nullable()->unique();
            $table->string('nombre');
            $table->text('descripcion')->nullable();
            $table->decimal('precio_base', 12, 2)->default(0);
            $table->boolean('activo')->default(true);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('servicios');
    }
};
