<?php

use App\Models\Factura;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        DB::table('facturas')
            ->where('estado', Factura::ESTADO_BORRADOR)
            ->update(['estado' => Factura::ESTADO_PENDIENTE]);
    }

    public function down(): void
    {
        DB::table('facturas')
            ->where('estado', Factura::ESTADO_PENDIENTE)
            ->whereNull('emitida_at')
            ->whereNull('anulada_at')
            ->update(['estado' => Factura::ESTADO_BORRADOR]);
    }
};

