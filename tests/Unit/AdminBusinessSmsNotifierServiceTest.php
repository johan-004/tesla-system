<?php

use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use App\Models\Cotizacion;
use App\Models\Factura;
use App\Models\User;
use App\Services\Alerts\AdminBusinessSmsNotifier;
use App\Services\Sms\SmsSender;

uses(TestCase::class, RefreshDatabase::class);

test('sends sms to admin phones when vendedor creates cotizacion', function () {
    $admin = User::factory()->create([
        'role' => User::ROLE_ADMINISTRADOR,
        'phone' => '+573001234567',
    ]);

    $vendedor = User::factory()->create([
        'role' => User::ROLE_VENDEDOR,
    ]);

    $cotizacion = new Cotizacion([
        'id' => 77,
        'codigo' => 'COT-077',
        'cliente_nombre' => 'Cliente Demo',
        'total' => 560000,
    ]);

    $smsSender = Mockery::mock(SmsSender::class);
    $smsSender->shouldReceive('send')
        ->once()
        ->with(
            $admin->phone,
            Mockery::pattern('/nueva cotizacion COT-077/i')
        );

    $service = new AdminBusinessSmsNotifier($smsSender);
    $service->notifyCotizacionCreatedBySeller($cotizacion, $vendedor);
});

test('does not send sms when actor is administrador', function () {
    User::factory()->create([
        'role' => User::ROLE_ADMINISTRADOR,
        'phone' => '+573009998877',
    ]);

    $adminActor = User::factory()->create([
        'role' => User::ROLE_ADMINISTRADOR,
    ]);

    $factura = new Factura([
        'id' => 19,
        'codigo' => 'FAC-019',
        'cliente_nombre' => 'Cliente Admin',
        'total' => 120000,
    ]);

    $smsSender = Mockery::mock(SmsSender::class);
    $smsSender->shouldNotReceive('send');

    $service = new AdminBusinessSmsNotifier($smsSender);
    $service->notifyFacturaCreatedBySeller($factura, $adminActor);
});
