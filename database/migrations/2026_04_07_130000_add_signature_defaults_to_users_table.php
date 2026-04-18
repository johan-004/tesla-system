<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            if (! Schema::hasColumn('users', 'firma_path_default')) {
                $table->string('firma_path_default')->nullable()->after('role');
            }
            if (! Schema::hasColumn('users', 'firma_nombre_default')) {
                $table->string('firma_nombre_default')->nullable()->after('firma_path_default');
            }
            if (! Schema::hasColumn('users', 'firma_cargo_default')) {
                $table->string('firma_cargo_default')->nullable()->after('firma_nombre_default');
            }
            if (! Schema::hasColumn('users', 'firma_empresa_default')) {
                $table->string('firma_empresa_default')->nullable()->after('firma_cargo_default');
            }
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $columns = [
                'firma_path_default',
                'firma_nombre_default',
                'firma_cargo_default',
                'firma_empresa_default',
            ];

            foreach ($columns as $column) {
                if (Schema::hasColumn('users', $column)) {
                    $table->dropColumn($column);
                }
            }
        });
    }
};
