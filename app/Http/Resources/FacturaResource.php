<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class FacturaResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'codigo' => $this->codigo,
            'numero' => $this->numero ?: $this->codigo,
            'fecha' => optional($this->fecha)->toDateString(),
            'cliente_id' => $this->cliente_id,
            'cliente_nombre' => $this->cliente_nombre,
            'cliente_nit' => $this->cliente_nit,
            'cliente_contacto' => $this->cliente_contacto,
            'cliente_direccion' => $this->cliente_direccion,
            'observaciones' => $this->observaciones,
            'estado' => $this->estado,
            'subtotal' => $this->subtotal,
            'iva_total' => $this->iva_total,
            'impuestos' => $this->iva_total,
            'total' => $this->total,
            'created_by' => $this->created_by,
            'updated_by' => $this->updated_by,
            'created_by_name' => $this->creator?->name,
            'updated_by_name' => $this->updater?->name,
            'emitida_at' => optional($this->emitida_at)->toDateTimeString(),
            'emitida_by' => $this->emitida_by,
            'emitida_by_name' => $this->emitter?->name,
            'anulada_at' => optional($this->anulada_at)->toDateTimeString(),
            'anulada_by' => $this->anulada_by,
            'anulada_by_name' => $this->annuller?->name,
            'items' => $this->whenLoaded('items', function () {
                return $this->items->values()->map(function ($item) {
                    return [
                        'id' => $item->id,
                        'factura_id' => $item->factura_id,
                        'producto_id' => $item->producto_id,
                        'orden' => $item->orden,
                        'descripcion' => $item->descripcion,
                        'unidad' => $item->unidad,
                        'cantidad' => $item->cantidad,
                        'precio_unitario' => $item->precio_unitario,
                        'iva_porcentaje' => $item->iva_porcentaje,
                        'iva_valor' => $item->iva_valor,
                        'subtotal_linea' => $item->subtotal_linea,
                        'total_linea' => $item->total_linea,
                    ];
                })->all();
            }, []),
            'created_at' => optional($this->created_at)->toDateTimeString(),
            'updated_at' => optional($this->updated_at)->toDateTimeString(),
        ];
    }
}
