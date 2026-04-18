<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ProductoResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'codigo' => $this->codigo,
            'nombre' => $this->nombre,
            'descripcion' => $this->descripcion,
            'precio_compra' => $this->precio_compra,
            'precio_venta' => $this->precio_venta,
            'iva_porcentaje' => $this->iva_porcentaje,
            'stock' => $this->stock,
            'unidad_medida' => $this->unidad_medida,
            'activo' => (bool) $this->activo,
            'created_at' => optional($this->created_at)->toDateTimeString(),
        ];
    }
}
