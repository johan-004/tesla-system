<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ServicioResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'categoria_servicio_id' => $this->categoria_servicio_id,
            'codigo' => $this->codigo,
            'descripcion' => $this->descripcion,
            'categoria' => $this->categoria,
            'unidad' => $this->unidad,
            'precio_unitario' => $this->precio_unitario,
            'iva' => $this->iva,
            'precio_con_iva' => $this->precio_con_iva,
            'observaciones' => $this->observaciones,
            'activo' => (bool) $this->activo,
            'created_at' => optional($this->created_at)->toDateTimeString(),
        ];
    }
}
