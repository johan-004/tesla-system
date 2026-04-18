<?php

namespace App\Http\Requests\Api\Cliente;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateClienteRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        $clienteId = $this->route('cliente')->id;

        return [
            'nombre' => ['sometimes', 'required', 'string', 'max:255'],
            'documento' => ['nullable', 'string', 'max:50', Rule::unique('clientes', 'documento')->ignore($clienteId)],
            'telefono' => ['nullable', 'string', 'max:50'],
            'email' => ['nullable', 'email', 'max:255'],
            'direccion' => ['nullable', 'string', 'max:255'],
            'notas' => ['nullable', 'string'],
            'activo' => ['nullable', 'boolean'],
        ];
    }
}
