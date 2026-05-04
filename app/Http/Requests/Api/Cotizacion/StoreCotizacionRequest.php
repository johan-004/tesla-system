<?php

namespace App\Http\Requests\Api\Cotizacion;

use Illuminate\Foundation\Http\FormRequest;

class StoreCotizacionRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'fecha' => ['required', 'date'],
            'ciudad' => ['required', 'string', 'max:120'],
            'cliente_nombre' => ['required', 'string', 'max:255'],
            'cliente_nit' => ['nullable', 'string', 'max:80'],
            'cliente_contacto' => ['nullable', 'string', 'max:150'],
            'cliente_cargo' => ['nullable', 'string', 'max:150'],
            'cliente_ciudad' => ['nullable', 'string', 'max:120'],
            'cliente_direccion' => ['nullable', 'string', 'max:255'],
            'referencia' => ['required', 'string', 'max:255'],
            'observaciones' => ['nullable', 'string'],
            'alcance_items' => ['nullable', 'array'],
            'alcance_items.*' => ['required', 'string', 'max:500'],
            'oferta_dias_totales' => ['nullable', 'integer', 'min:1', 'max:3650'],
            'oferta_dias_ejecucion' => ['nullable', 'integer', 'min:0', 'max:3650'],
            'oferta_dias_tramitologia' => ['nullable', 'integer', 'min:0', 'max:3650'],
            'oferta_pago_1_pct' => ['nullable', 'numeric', 'min:0', 'max:100'],
            'oferta_pago_2_pct' => ['nullable', 'numeric', 'min:0', 'max:100'],
            'oferta_pago_3_pct' => ['nullable', 'numeric', 'min:0', 'max:100'],
            'oferta_garantia_meses' => ['nullable', 'integer', 'min:0', 'max:240'],
            'firma_path' => ['nullable', 'string', 'max:1000'],
            'firma_nombre' => ['nullable', 'string', 'max:255'],
            'firma_cargo' => ['nullable', 'string', 'max:255'],
            'firma_empresa' => ['nullable', 'string', 'max:255'],
            'subtotal' => ['required', 'numeric', 'min:0'],
            'total' => ['required', 'numeric', 'min:0'],
            'detalles' => ['required', 'array', 'min:1'],
            'detalles.*.servicio_id' => ['nullable', 'integer', 'exists:servicios,id'],
            'detalles.*.producto_id' => ['nullable', 'integer', 'exists:productos,id'],
            'detalles.*.tipo_item' => ['nullable', 'string', 'in:servicio,producto'],
            'detalles.*.codigo' => ['nullable', 'string', 'max:80'],
            'detalles.*.descripcion' => ['required', 'string'],
            'detalles.*.unidad' => ['required', 'string', 'max:80'],
            'detalles.*.cantidad' => ['required', 'numeric', 'gt:0'],
            'detalles.*.precio_unitario' => ['required', 'numeric', 'min:0'],
            'detalles.*.subtotal' => ['required', 'numeric', 'min:0'],
            'numero' => ['prohibited'],
            'codigo' => ['prohibited'],
            'estado' => ['prohibited'],
        ];
    }
}
