<?php

namespace App\Http\Requests\Api\Factura;

use Illuminate\Foundation\Http\FormRequest;

class UpdateFacturaRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'fecha' => ['sometimes', 'required', 'date'],
            'ciudad_expedicion' => ['nullable', 'string', 'max:120'],
            'cliente_id' => ['nullable', 'integer', 'exists:clientes,id'],
            'cliente_nombre' => ['sometimes', 'required', 'string', 'max:255'],
            'cliente_nit' => ['nullable', 'string', 'max:80'],
            'cliente_contacto' => ['nullable', 'string', 'max:150'],
            'cliente_direccion' => ['nullable', 'string', 'max:255'],
            'cliente_ciudad' => ['nullable', 'string', 'max:120'],
            'observaciones' => ['nullable', 'string'],
            'firma_path' => ['nullable', 'string', 'max:2048'],
            'firma_nombre' => ['nullable', 'string', 'max:150'],
            'firma_cargo' => ['nullable', 'string', 'max:150'],
            'firma_empresa' => ['nullable', 'string', 'max:180'],
            'items' => ['sometimes', 'required', 'array', 'min:1'],
            'items.*.producto_id' => ['nullable', 'integer', 'exists:productos,id'],
            'items.*.servicio_id' => ['nullable', 'integer', 'exists:servicios,id'],
            'items.*.tipo_item' => ['nullable', 'string', 'in:servicio,producto'],
            'items.*.codigo' => ['nullable', 'string', 'max:80'],
            'items.*.descripcion' => ['required_with:items', 'string', 'max:1000'],
            'items.*.unidad' => ['nullable', 'string', 'max:80'],
            'items.*.cantidad' => ['required_with:items', 'numeric', 'min:0.01'],
            'items.*.precio_unitario' => ['required_with:items', 'numeric', 'min:0'],
            'items.*.iva_porcentaje' => ['nullable', 'numeric', 'min:0', 'max:100'],
            'codigo' => ['prohibited'],
            'numero' => ['prohibited'],
            'estado' => ['prohibited'],
            'subtotal' => ['prohibited'],
            'iva_total' => ['prohibited'],
            'total' => ['prohibited'],
        ];
    }
}
