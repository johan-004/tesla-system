<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasTable('producto_categorias')) {
            Schema::create('producto_categorias', function (Blueprint $table) {
                $table->id();
                $table->string('nombre', 120)->unique();
                $table->boolean('activo')->default(true);
                $table->timestamps();
            });
        }

        Schema::table('productos', function (Blueprint $table) {
            if (! Schema::hasColumn('productos', 'categoria_id')) {
                $table->foreignId('categoria_id')
                    ->nullable()
                    ->after('unidad_medida')
                    ->constrained('producto_categorias')
                    ->nullOnDelete();
            }
        });
    }

    public function down(): void
    {
        Schema::table('productos', function (Blueprint $table) {
            if (Schema::hasColumn('productos', 'categoria_id')) {
                $table->dropConstrainedForeignId('categoria_id');
            }
        });

        Schema::dropIfExists('producto_categorias');
    }
};

