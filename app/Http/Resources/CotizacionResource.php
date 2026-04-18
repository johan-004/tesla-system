<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class CotizacionResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'numero' => $this->numero,
            'ciudad' => $this->ciudad,
            'cliente_nombre' => $this->cliente_nombre,
            'cliente_nit' => $this->cliente_nit,
            'cliente_contacto' => $this->cliente_contacto,
            'cliente_cargo' => $this->cliente_cargo,
            'cliente_ciudad' => $this->cliente_ciudad,
            'cliente_direccion' => $this->cliente_direccion,
            'referencia' => $this->referencia,
            'created_by' => $this->created_by,
            'updated_by' => $this->updated_by,
            'created_by_name' => $this->creator?->name,
            'updated_by_name' => $this->updater?->name,
            'codigo' => $this->codigo,
            'cliente_id' => $this->cliente_id,
            'user_id' => $this->user_id,
            'fecha' => optional($this->fecha)->toDateString(),
            'estado' => $this->estado,
            'observaciones' => $this->observaciones,
            'alcance_items' => collect($this->alcance_items ?? [])->values()->all(),
            'oferta_dias_totales' => (int) ($this->oferta_dias_totales ?? 30),
            'oferta_dias_ejecucion' => (int) ($this->oferta_dias_ejecucion ?? 15),
            'oferta_dias_tramitologia' => (int) ($this->oferta_dias_tramitologia ?? 15),
            'oferta_pago_1_pct' => (string) ($this->oferta_pago_1_pct ?? '50'),
            'oferta_pago_2_pct' => (string) ($this->oferta_pago_2_pct ?? '25'),
            'oferta_pago_3_pct' => (string) ($this->oferta_pago_3_pct ?? '25'),
            'oferta_garantia_meses' => (int) ($this->oferta_garantia_meses ?? 6),
            'firma_path' => $this->firma_path,
            'firma_nombre' => $this->firma_nombre,
            'firma_cargo' => $this->firma_cargo,
            'firma_empresa' => $this->firma_empresa,
            'subtotal' => $this->subtotal,
            'impuestos' => $this->impuestos,
            'total' => $this->total,
            'detalles' => $this->whenLoaded('detalles', function () {
                return $this->detalles->values()->map(function ($detalle, $index) {
                    return [
                        'id' => $detalle->id,
                        'item' => $index + 1,
                        'servicio_id' => $detalle->servicio_id,
                        'categoria' => $detalle->categoria,
                        'descripcion' => $detalle->descripcion,
                        'unidad' => $detalle->unidad,
                        'cantidad' => $detalle->cantidad,
                        'precio_unitario' => $detalle->precio_unitario,
                        'subtotal' => $detalle->subtotal,
                    ];
                })->all();
            }, []),
            'created_at' => optional($this->created_at)->toDateTimeString(),
            'updated_at' => optional($this->updated_at)->toDateTimeString(),
        ];
    }
}
