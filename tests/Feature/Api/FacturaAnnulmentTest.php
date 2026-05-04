<?php

use App\Models\Cliente;
use App\Models\Factura;
use App\Models\User;
use Laravel\Sanctum\Sanctum;

test('anular factura only affects the selected factura', function () {
    $admin = User::factory()->create([
        'role' => User::ROLE_ADMINISTRADOR,
    ]);

    $cliente = Cliente::query()->create([
        'nombre' => 'Cliente prueba anulacion',
        'documento' => '4455667788',
        'telefono' => '3005555555',
        'email' => 'cliente-anulacion@demo.test',
        'direccion' => 'Calle 10',
        'notas' => null,
        'activo' => true,
        'created_by' => $admin->id,
    ]);

    $facturaA = Factura::query()->create([
        'codigo' => 'FAC-ANU-A',
        'numero' => 'FAC-ANU-A',
        'fecha' => now()->toDateString(),
        'cliente_id' => $cliente->id,
        'cliente_nombre' => $cliente->nombre,
        'estado' => Factura::ESTADO_EMITIDA,
        'subtotal' => 100,
        'iva_total' => 0,
        'impuestos' => 0,
        'total' => 100,
        'created_by' => $admin->id,
        'updated_by' => $admin->id,
        'emitida_by' => $admin->id,
        'emitida_at' => now(),
        'user_id' => $admin->id,
    ]);

    $facturaB = Factura::query()->create([
        'codigo' => 'FAC-ANU-B',
        'numero' => 'FAC-ANU-B',
        'fecha' => now()->toDateString(),
        'cliente_id' => $cliente->id,
        'cliente_nombre' => $cliente->nombre,
        'estado' => Factura::ESTADO_EMITIDA,
        'subtotal' => 150,
        'iva_total' => 0,
        'impuestos' => 0,
        'total' => 150,
        'created_by' => $admin->id,
        'updated_by' => $admin->id,
        'emitida_by' => $admin->id,
        'emitida_at' => now(),
        'user_id' => $admin->id,
    ]);

    Sanctum::actingAs($admin);

    $this->patchJson("/api/v1/facturas/{$facturaA->id}/anular")
        ->assertOk()
        ->assertJsonPath('data.id', $facturaA->id)
        ->assertJsonPath('data.estado', Factura::ESTADO_ANULADA);

    expect($facturaA->fresh()->estado)->toBe(Factura::ESTADO_ANULADA);
    expect($facturaB->fresh()->estado)->toBe(Factura::ESTADO_EMITIDA);
});

