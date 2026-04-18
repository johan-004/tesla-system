<?php

namespace App\Http\Requests\Api\CategoriaServicio;

use Illuminate\Foundation\Http\FormRequest;

class StoreCategoriaServicioRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'nombre' => ['required', 'string', 'max:255'],
            'descripcion' => ['nullable', 'string'],
            'activo' => ['nullable', 'boolean'],
        ];
    }
}
