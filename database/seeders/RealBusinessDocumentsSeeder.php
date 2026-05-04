<?php

namespace Database\Seeders;

use App\Models\Cotizacion;
use App\Models\CotizacionDetalle;
use App\Models\Factura;
use App\Models\FacturaItem;
use App\Models\Producto;
use App\Models\Servicio;
use App\Models\User;
use Carbon\CarbonImmutable;
use Illuminate\Database\Seeder;

class RealBusinessDocumentsSeeder extends Seeder
{
    public function run(): void
    {
        $user = User::query()->orderBy('id')->first();
        $userId = $user?->id;
        $today = CarbonImmutable::now();
        $year = $today->year;

        $productos = Producto::query()->where('activo', true)->orderBy('id')->limit(6)->get();
        $servicios = Servicio::query()->where('activo', true)->orderBy('id')->limit(6)->get();

        if ($productos->count() < 3) {
            for ($i = 1; $i <= 6; $i++) {
                $productos->push(
                    Producto::query()->updateOrCreate(
                        ['codigo' => sprintf('PRO-%03d', 900 + $i)],
                        [
                            'nombre' => "Producto demo {$i}",
                            'descripcion' => 'Producto de prueba para facturas y cotizaciones.',
                            'precio_compra' => 10000 + ($i * 1500),
                            'precio_venta' => 18000 + ($i * 2500),
                            'iva_porcentaje' => 0,
                            'stock' => 120,
                            'unidad_medida' => 'unidad',
                            'activo' => true,
                        ]
                    )
                );
            }
            $productos = Producto::query()->where('activo', true)->orderBy('id')->limit(6)->get();
        }

        if ($servicios->count() < 3) {
            for ($i = 1; $i <= 6; $i++) {
                $precio = 75000 + ($i * 22000);
                $servicios->push(
                    Servicio::query()->updateOrCreate(
                        ['codigo' => sprintf('SER-%03d', 900 + $i)],
                        [
                            'nombre' => "Servicio demo {$i}",
                            'descripcion' => "Servicio de prueba {$i} para cotizaciones y facturas.",
                            'categoria' => 'general',
                            'unidad' => 'servicio',
                            'precio_unitario' => $precio,
                            'iva' => 0,
                            'precio_con_iva' => $precio,
                            'observaciones' => null,
                            'precio_base' => $precio,
                            'activo' => true,
                        ]
                    )
                );
            }
            $servicios = Servicio::query()->where('activo', true)->orderBy('id')->limit(6)->get();
        }

        $clienteNombre = 'MAURICION ANDRES BENITO';
        $clienteNit = '8765678-2';
        $clienteContacto = '3100000000';
        $clienteDireccion = 'Villavicencio, Meta';
        $ciudad = 'Villavicencio';

        $facturaBlueprints = [
            ['codigo' => "FAC-{$year}-000201", 'fecha' => CarbonImmutable::create($year, 1, 9), 'estado' => Factura::ESTADO_EMITIDA, 'lineas' => [[0, 'producto', 12], [0, 'servicio', 1]]],
            ['codigo' => "FAC-{$year}-000202", 'fecha' => CarbonImmutable::create($year, 2, 14), 'estado' => Factura::ESTADO_EMITIDA, 'lineas' => [[1, 'producto', 8], [1, 'servicio', 1]]],
            ['codigo' => "FAC-{$year}-000203", 'fecha' => CarbonImmutable::create($year, 3, 8), 'estado' => Factura::ESTADO_EMITIDA, 'lineas' => [[2, 'producto', 18], [2, 'servicio', 2]]],
            ['codigo' => "FAC-{$year}-000204", 'fecha' => CarbonImmutable::create($year, 4, 22), 'estado' => Factura::ESTADO_EMITIDA, 'lineas' => [[3, 'producto', 10], [3, 'servicio', 2]]],
            ['codigo' => "FAC-{$year}-000205", 'fecha' => CarbonImmutable::create($year, 5, 24), 'estado' => Factura::ESTADO_EMITIDA, 'lineas' => [[4, 'producto', 22], [4, 'servicio', 1]]],
            ['codigo' => "FAC-{$year}-000206", 'fecha' => CarbonImmutable::create($year, 5, 27), 'estado' => Factura::ESTADO_PENDIENTE, 'lineas' => [[5, 'producto', 6], [5, 'servicio', 1]]],
            ['codigo' => "FAC-{$year}-000207", 'fecha' => CarbonImmutable::create($year, 5, 30), 'estado' => Factura::ESTADO_ANULADA, 'lineas' => [[0, 'producto', 5], [2, 'servicio', 1]]],
        ];

        foreach ($facturaBlueprints as $blueprint) {
            $factura = Factura::query()->updateOrCreate(
                ['codigo' => $blueprint['codigo']],
                [
                    'numero' => $blueprint['codigo'],
                    'fecha' => $blueprint['fecha']->toDateString(),
                    'ciudad_expedicion' => $ciudad,
                    'cliente_nombre' => $clienteNombre,
                    'cliente_nit' => $clienteNit,
                    'cliente_contacto' => $clienteContacto,
                    'cliente_direccion' => $clienteDireccion,
                    'cliente_ciudad' => $ciudad,
                    'observaciones' => 'Documento demo real para pruebas de dashboard.',
                    'subtotal' => 0,
                    'iva_total' => 0,
                    'impuestos' => 0,
                    'total' => 0,
                    'estado' => $blueprint['estado'],
                    'created_by' => $userId,
                    'updated_by' => $userId,
                    'emitida_at' => $blueprint['estado'] === Factura::ESTADO_EMITIDA ? $blueprint['fecha']->endOfDay() : null,
                    'emitida_by' => $blueprint['estado'] === Factura::ESTADO_EMITIDA ? $userId : null,
                    'anulada_at' => $blueprint['estado'] === Factura::ESTADO_ANULADA ? $blueprint['fecha']->endOfDay() : null,
                    'anulada_by' => $blueprint['estado'] === Factura::ESTADO_ANULADA ? $userId : null,
                    'user_id' => $userId,
                ]
            );

            FacturaItem::query()->where('factura_id', $factura->id)->delete();

            $subtotal = 0.0;
            $orden = 1;

            foreach ($blueprint['lineas'] as [$idx, $tipo, $cantidad]) {
                if ($tipo === 'producto') {
                    $producto = $productos[$idx % $productos->count()];
                    $precio = (float) $producto->precio_venta;
                    $descripcion = $producto->nombre;
                    $unidad = $producto->unidad_medida ?: 'unidad';
                    $codigo = $producto->codigo;

                    FacturaItem::query()->create([
                        'factura_id' => $factura->id,
                        'producto_id' => $producto->id,
                        'servicio_id' => null,
                        'tipo_item' => 'producto',
                        'codigo' => $codigo,
                        'orden' => $orden++,
                        'descripcion' => $descripcion,
                        'unidad' => $unidad,
                        'cantidad' => $cantidad,
                        'precio_unitario' => $precio,
                        'iva_porcentaje' => 0,
                        'iva_valor' => 0,
                        'subtotal_linea' => $cantidad * $precio,
                        'total_linea' => $cantidad * $precio,
                    ]);

                    $subtotal += $cantidad * $precio;
                } else {
                    $servicio = $servicios[$idx % $servicios->count()];
                    $precio = (float) ($servicio->precio_con_iva ?: $servicio->precio_unitario);
                    $descripcion = $servicio->descripcion ?: $servicio->nombre;
                    $unidad = $servicio->unidad ?: 'servicio';
                    $codigo = $servicio->codigo;

                    FacturaItem::query()->create([
                        'factura_id' => $factura->id,
                        'producto_id' => null,
                        'servicio_id' => $servicio->id,
                        'tipo_item' => 'servicio',
                        'codigo' => $codigo,
                        'orden' => $orden++,
                        'descripcion' => $descripcion,
                        'unidad' => $unidad,
                        'cantidad' => $cantidad,
                        'precio_unitario' => $precio,
                        'iva_porcentaje' => 0,
                        'iva_valor' => 0,
                        'subtotal_linea' => $cantidad * $precio,
                        'total_linea' => $cantidad * $precio,
                    ]);

                    $subtotal += $cantidad * $precio;
                }
            }

            $factura->forceFill([
                'subtotal' => $subtotal,
                'iva_total' => 0,
                'impuestos' => 0,
                'total' => $subtotal,
            ])->save();
        }

        $cotizacionBlueprints = [
            ['codigo' => "COT-{$year}-000301", 'fecha' => CarbonImmutable::create($year, 3, 11), 'estado' => Cotizacion::ESTADO_REALIZADA, 'lineas' => [[0, 'servicio', 1], [0, 'producto', 4]]],
            ['codigo' => "COT-{$year}-000302", 'fecha' => CarbonImmutable::create($year, 4, 16), 'estado' => Cotizacion::ESTADO_VISTO, 'lineas' => [[1, 'servicio', 2], [1, 'producto', 6]]],
            ['codigo' => "COT-{$year}-000303", 'fecha' => CarbonImmutable::create($year, 5, 6), 'estado' => Cotizacion::ESTADO_PENDIENTE, 'lineas' => [[2, 'servicio', 1], [2, 'producto', 10]]],
            ['codigo' => "COT-{$year}-000304", 'fecha' => CarbonImmutable::create($year, 5, 18), 'estado' => Cotizacion::ESTADO_REALIZADA, 'lineas' => [[3, 'servicio', 2], [3, 'producto', 3]]],
        ];

        foreach ($cotizacionBlueprints as $index => $blueprint) {
            $cotizacion = Cotizacion::query()->updateOrCreate(
                ['codigo' => $blueprint['codigo']],
                [
                    'numero' => $blueprint['codigo'],
                    'fecha' => $blueprint['fecha']->toDateString(),
                    'ciudad' => $ciudad,
                    'cliente_nombre' => $clienteNombre,
                    'cliente_nit' => $clienteNit,
                    'cliente_contacto' => $clienteContacto,
                    'cliente_cargo' => 'Administrador',
                    'cliente_ciudad' => $ciudad,
                    'cliente_direccion' => $clienteDireccion,
                    'referencia' => 'Cotización demo para panel comercial',
                    'item' => (string) ($index + 1),
                    'obra' => 'Proyecto eléctrico comercial',
                    'descripcion' => 'Documento demo real para listado y dashboard.',
                    'unidad' => 'Global',
                    'estado' => $blueprint['estado'],
                    'observaciones' => 'Documento sembrado para pruebas reales de escritorio.',
                    'subtotal' => 0,
                    'impuestos' => 0,
                    'total' => 0,
                    'created_by' => $userId,
                    'updated_by' => $userId,
                    'user_id' => $userId,
                ]
            );

            CotizacionDetalle::query()->where('cotizacion_id', $cotizacion->id)->delete();

            $subtotal = 0.0;
            foreach ($blueprint['lineas'] as [$lineIdx, $tipo, $cantidad]) {
                if ($tipo === 'producto') {
                    $producto = $productos[$lineIdx % $productos->count()];
                    $precio = (float) $producto->precio_venta;
                    $descripcion = $producto->nombre;
                    $unidad = $producto->unidad_medida ?: 'unidad';
                    $codigo = $producto->codigo;

                    CotizacionDetalle::query()->create([
                        'cotizacion_id' => $cotizacion->id,
                        'servicio_id' => null,
                        'producto_id' => $producto->id,
                        'categoria' => 'producto',
                        'codigo' => $codigo,
                        'descripcion' => $descripcion,
                        'unidad' => $unidad,
                        'cantidad' => $cantidad,
                        'precio_unitario' => $precio,
                        'subtotal' => $cantidad * $precio,
                    ]);

                    $subtotal += $cantidad * $precio;
                } else {
                    $servicio = $servicios[$lineIdx % $servicios->count()];
                    $precio = (float) ($servicio->precio_con_iva ?: $servicio->precio_unitario);
                    $descripcion = $servicio->descripcion ?: $servicio->nombre;
                    $unidad = $servicio->unidad ?: 'servicio';
                    $codigo = $servicio->codigo;

                    CotizacionDetalle::query()->create([
                        'cotizacion_id' => $cotizacion->id,
                        'servicio_id' => $servicio->id,
                        'producto_id' => null,
                        'categoria' => 'servicio',
                        'codigo' => $codigo,
                        'descripcion' => $descripcion,
                        'unidad' => $unidad,
                        'cantidad' => $cantidad,
                        'precio_unitario' => $precio,
                        'subtotal' => $cantidad * $precio,
                    ]);

                    $subtotal += $cantidad * $precio;
                }
            }

            $cotizacion->forceFill([
                'subtotal' => $subtotal,
                'impuestos' => 0,
                'total' => $subtotal,
            ])->save();
        }
    }
}

