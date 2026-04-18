<?php

namespace App\Http\Requests\Api\Servicio;

use Illuminate\Foundation\Http\FormRequest;

class StoreServicioRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'codigo' => ['required', 'string', 'max:50', 'unique:servicios,codigo'],
            'descripcion' => ['required', 'string'],
            'categoria' => ['required', 'string', 'max:120'],
            'unidad' => ['required', 'string', 'max:50'],
            'precio_unitario' => ['required', 'numeric', 'min:0'],
            'iva' => ['required', 'numeric', 'min:0'],
            'precio_con_iva' => ['required', 'numeric', 'min:0'],
            'observaciones' => ['nullable', 'string'],
            'activo' => ['nullable', 'boolean'],
        ];
    }
}
