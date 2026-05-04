<?php

use App\Models\Cliente;
use App\Models\User;
use App\Services\Alerts\AdminBusinessPushNotifier;
use Laravel\Sanctum\Sanctum;

test('notifies admins by push when vendedor creates cotizacion and factura', function () {
    $vendedor = User::factory()->create([
        'role' => User::ROLE_VENDEDOR,
    ]);

    $cliente = Cliente::query()->create([
        'nombre' => 'Cliente alerta',
        'documento' => '1234567890',
        'telefono' => '3005551111',
        'email' => 'cliente.alerta@test.local',
        'direccion' => 'Calle alerta',
        'notas' => null,
        'activo' => true,
        'created_by' => User::factory()->create()->id,
    ]);

    $pushNotifier = Mockery::mock(AdminBusinessPushNotifier::class);
    $pushNotifier->shouldReceive('notifyCotizacionCreatedBySeller')->once();
    $pushNotifier->shouldReceive('notifyFacturaCreatedBySeller')->once();
    app()->instance(AdminBusinessPushNotifier::class, $pushNotifier);

    Sanctum::actingAs($vendedor);

    $this->postJson('/api/v1/cotizaciones', [
        'cliente_id' => $cliente->id,
        'fecha' => now()->toDateString(),
        'ciudad' => 'Villavicencio',
        'cliente_nombre' => 'Cliente alerta',
        'referencia' => 'Proyecto alerta',
        'subtotal' => 100,
        'total' => 100,
        'detalles' => [
            [
                'descripcion' => 'Servicio alerta',
                'unidad' => 'Un.',
                'cantidad' => 1,
                'precio_unitario' => 100,
                'subtotal' => 100,
            ],
        ],
    ])->assertCreated();

    $this->postJson('/api/v1/facturas', [
        'cliente_id' => $cliente->id,
        'fecha' => now()->toDateString(),
        'cliente_nombre' => 'Cliente alerta',
        'items' => [
            [
                'descripcion' => 'Servicio alerta',
                'unidad' => 'Un.',
                'cantidad' => 1,
                'precio_unitario' => 120,
            ],
        ],
    ])->assertCreated();
});
