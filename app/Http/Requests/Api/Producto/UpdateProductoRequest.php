<?php

namespace App\Http\Requests\Api\Producto;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateProductoRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        $productoId = $this->route('producto')->id;

        return [
            'codigo' => ['sometimes', 'required', 'string', 'max:50', Rule::unique('productos', 'codigo')->ignore($productoId)],
            'nombre' => ['sometimes', 'required', 'string', 'max:255'],
            'descripcion' => ['nullable', 'string'],
            'precio_compra' => ['nullable', 'numeric', 'min:0'],
            'precio_venta' => ['sometimes', 'required', 'numeric', 'min:0'],
            'iva_porcentaje' => ['nullable', 'numeric', 'min:0'],
            'stock' => ['sometimes', 'required', 'integer', 'min:0'],
            'unidad_medida' => ['sometimes', 'required', 'string', 'max:50'],
            'categoria_id' => ['nullable', 'integer', 'exists:producto_categorias,id'],
            'activo' => ['nullable', 'boolean'],
        ];
    }
}
