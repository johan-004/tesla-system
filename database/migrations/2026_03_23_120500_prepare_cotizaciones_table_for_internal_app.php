<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('cotizaciones', function (Blueprint $table) {
            $table->foreignId('cliente_id')->nullable()->after('id')->constrained('clientes')->nullOnDelete();
            $table->foreignId('user_id')->nullable()->after('cliente_id')->constrained('users')->nullOnDelete();
            $table->string('codigo')->nullable()->after('user_id');
            $table->enum('estado', ['pendiente', 'visto', 'realizada'])->default('pendiente')->after('fecha');
            $table->text('observaciones')->nullable()->after('estado');
            $table->decimal('subtotal', 12, 2)->default(0)->after('observaciones');
            $table->decimal('impuestos', 12, 2)->default(0)->after('subtotal');
            $table->decimal('total', 12, 2)->default(0)->after('impuestos');
        });
    }

    public function down(): void
    {
        Schema::table('cotizaciones', function (Blueprint $table) {
            $table->dropConstrainedForeignId('cliente_id');
            $table->dropConstrainedForeignId('user_id');
            $table->dropColumn(['codigo', 'estado', 'observaciones', 'subtotal', 'impuestos', 'total']);
        });
    }
};
