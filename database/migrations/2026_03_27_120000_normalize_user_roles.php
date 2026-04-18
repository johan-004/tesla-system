<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('role', 50)->default('vendedor')->change();
        });

        DB::table('users')
            ->where('role', 'administradora')
            ->update(['role' => 'administrador']);

        DB::table('users')
            ->where('role', 'vendedora')
            ->update(['role' => 'vendedor']);
    }

    public function down(): void
    {
        DB::table('users')
            ->where('role', 'administrador')
            ->update(['role' => 'administradora']);

        DB::table('users')
            ->where('role', 'vendedor')
            ->update(['role' => 'vendedora']);

        Schema::table('users', function (Blueprint $table) {
            $table->string('role', 50)->default('vendedora')->change();
        });
    }
};
