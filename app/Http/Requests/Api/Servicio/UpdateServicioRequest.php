<?php

namespace App\Http\Requests\Api\Servicio;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateServicioRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        $servicioId = $this->route('servicio')->id;

        return [
            'codigo' => ['sometimes', 'required', 'string', 'max:50', Rule::unique('servicios', 'codigo')->ignore($servicioId)],
            'descripcion' => ['sometimes', 'required', 'string'],
            'categoria' => ['sometimes', 'required', 'string', 'max:120'],
            'unidad' => ['sometimes', 'required', 'string', 'max:50'],
            'precio_unitario' => ['sometimes', 'required', 'numeric', 'min:0'],
            'iva' => ['sometimes', 'required', 'numeric', 'min:0'],
            'precio_con_iva' => ['sometimes', 'required', 'numeric', 'min:0'],
            'observaciones' => ['nullable', 'string'],
            'activo' => ['nullable', 'boolean'],
        ];
    }
}
