<?php

use App\Models\Cotizacion;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasColumn('cotizaciones', 'estado')) {
            Schema::table('cotizaciones', function (Blueprint $table) {
                $table->enum('estado', [
                    'borrador',
                    'revisada',
                    'aprobada',
                    'anulada',
                    Cotizacion::ESTADO_PENDIENTE,
                    Cotizacion::ESTADO_VISTO,
                    Cotizacion::ESTADO_REALIZADA,
                    Cotizacion::ESTADO_NULA,
                ])->default('borrador')->change();
            });

            DB::table('cotizaciones')
                ->where('estado', 'borrador')
                ->update(['estado' => Cotizacion::ESTADO_PENDIENTE]);

            DB::table('cotizaciones')
                ->where('estado', 'revisada')
                ->update(['estado' => Cotizacion::ESTADO_VISTO]);

            DB::table('cotizaciones')
                ->where('estado', 'aprobada')
                ->update(['estado' => Cotizacion::ESTADO_REALIZADA]);

            DB::table('cotizaciones')
                ->where('estado', 'anulada')
                ->update(['estado' => Cotizacion::ESTADO_NULA]);

            Schema::table('cotizaciones', function (Blueprint $table) {
                $table->enum('estado', Cotizacion::ESTADOS)
                    ->default(Cotizacion::ESTADO_PENDIENTE)
                    ->change();
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasColumn('cotizaciones', 'estado')) {
            Schema::table('cotizaciones', function (Blueprint $table) {
                $table->enum('estado', [
                    'borrador',
                    'revisada',
                    'aprobada',
                    'anulada',
                    Cotizacion::ESTADO_PENDIENTE,
                    Cotizacion::ESTADO_VISTO,
                    Cotizacion::ESTADO_REALIZADA,
                    Cotizacion::ESTADO_NULA,
                ])->default(Cotizacion::ESTADO_PENDIENTE)->change();
            });

            DB::table('cotizaciones')
                ->where('estado', Cotizacion::ESTADO_PENDIENTE)
                ->update(['estado' => 'borrador']);

            DB::table('cotizaciones')
                ->where('estado', Cotizacion::ESTADO_VISTO)
                ->update(['estado' => 'revisada']);

            DB::table('cotizaciones')
                ->where('estado', Cotizacion::ESTADO_REALIZADA)
                ->update(['estado' => 'aprobada']);

            DB::table('cotizaciones')
                ->where('estado', Cotizacion::ESTADO_NULA)
                ->update(['estado' => 'anulada']);

            Schema::table('cotizaciones', function (Blueprint $table) {
                $table->enum('estado', ['borrador', 'revisada', 'aprobada', 'anulada'])
                    ->default('borrador')
                    ->change();
            });
        }
    }
};
