<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasTable('cotizaciones')) {
            return;
        }

        DB::transaction(function () {
            $rows = DB::table('cotizaciones')
                ->select('id')
                ->orderBy('id')
                ->lockForUpdate()
                ->get();

            foreach ($rows as $index => $row) {
                $code = sprintf('COT-%03d', $index + 1);

                DB::table('cotizaciones')
                    ->where('id', $row->id)
                    ->update([
                        'numero' => $code,
                        'codigo' => $code,
                    ]);
            }
        });
    }

    public function down(): void
    {
        // El formato previo no se puede reconstruir de forma segura.
    }
};
