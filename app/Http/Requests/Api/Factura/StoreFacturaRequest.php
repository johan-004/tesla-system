<?php

namespace App\Http\Requests\Api\Factura;

use Illuminate\Foundation\Http\FormRequest;

class StoreFacturaRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'fecha' => ['required', 'date'],
            'cliente_id' => ['nullable', 'integer', 'exists:clientes,id'],
            'cliente_nombre' => ['required', 'string', 'max:255'],
            'cliente_nit' => ['nullable', 'string', 'max:80'],
            'cliente_contacto' => ['nullable', 'string', 'max:150'],
            'cliente_direccion' => ['nullable', 'string', 'max:255'],
            'observaciones' => ['nullable', 'string'],
            'items' => ['required', 'array', 'min:1'],
            'items.*.producto_id' => ['required', 'integer', 'exists:productos,id'],
            'items.*.cantidad' => ['required', 'integer', 'min:1'],
            'codigo' => ['prohibited'],
            'numero' => ['prohibited'],
            'estado' => ['prohibited'],
            'subtotal' => ['prohibited'],
            'iva_total' => ['prohibited'],
            'total' => ['prohibited'],
        ];
    }
}
