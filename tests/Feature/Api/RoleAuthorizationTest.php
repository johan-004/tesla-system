<?php

use App\Models\CategoriaServicio;
use App\Models\Cliente;
use App\Models\Cotizacion;
use App\Models\Factura;
use App\Models\Producto;
use App\Models\Servicio;
use App\Models\User;
use Laravel\Sanctum\Sanctum;

test('auth me returns normalized role and derived permissions', function () {
    $user = User::factory()->create([
        'role' => User::ROLE_ADMINISTRADOR,
    ]);

    Sanctum::actingAs($user);

    $this->getJson('/api/v1/auth/me')
        ->assertOk()
        ->assertJsonPath('data.role', User::ROLE_ADMINISTRADOR)
        ->assertJsonPath('data.permissions.0', 'productos.view')
        ->assertJsonFragment(['permissions' => $user->permissions()]);
});

test('vendedor can view administrative modules and work in cotizaciones/facturacion', function () {
    $producto = Producto::query()->create([
        'codigo' => 'PROD-001',
        'nombre' => 'Producto demo',
        'descripcion' => 'Demo',
        'precio_compra' => 10,
        'precio_venta' => 15,
        'stock' => 4,
        'unidad_medida' => 'unidad',
        'activo' => true,
    ]);

    $cliente = Cliente::query()->create([
        'nombre' => 'Cliente demo',
        'documento' => '100200300',
        'telefono' => '3000000000',
        'email' => 'cliente@demo.test',
        'direccion' => 'Calle demo',
        'notas' => null,
        'activo' => true,
        'created_by' => User::factory()->create()->id,
    ]);

    $categoria = CategoriaServicio::query()->create([
        'nombre' => 'Categoria demo',
        'descripcion' => null,
        'activo' => true,
    ]);

    Servicio::query()->create([
        'categoria_servicio_id' => $categoria->id,
        'codigo' => 'SERV-001',
        'nombre' => 'Servicio demo',
        'descripcion' => null,
        'precio_base' => 120,
        'activo' => true,
    ]);

    $user = User::factory()->create([
        'role' => User::ROLE_VENDEDOR,
    ]);

    Sanctum::actingAs($user);

    $this->getJson('/api/v1/productos')->assertOk();
    $this->getJson("/api/v1/productos/{$producto->id}")->assertOk();
    $this->getJson('/api/v1/clientes')->assertOk();
    $this->getJson("/api/v1/clientes/{$cliente->id}")->assertOk();
    $this->getJson('/api/v1/categorias-servicio')->assertOk();
    $this->getJson('/api/v1/servicios')->assertOk();

    $this->postJson('/api/v1/cotizaciones', [
        'cliente_id' => $cliente->id,
        'codigo' => 'COT-001',
        'fecha' => now()->toDateString(),
        'total' => 100,
    ])->assertCreated();

    $cotizacion = Cotizacion::query()->latest()->firstOrFail();

    $this->putJson("/api/v1/cotizaciones/{$cotizacion->id}", [
        'estado' => 'realizada',
    ])->assertOk();

    $this->postJson('/api/v1/facturas', [
        'cliente_id' => $cliente->id,
        'fecha' => now()->toDateString(),
        'cliente_nombre' => 'Cliente demo',
        'items' => [
            [
                'descripcion' => 'Servicio demo',
                'unidad' => 'Un.',
                'cantidad' => 1,
                'precio_unitario' => 120,
            ],
        ],
    ])->assertCreated();

    $factura = Factura::query()->latest()->firstOrFail();

    $this->patchJson("/api/v1/facturas/{$factura->id}/emitir")->assertOk();
});

test('vendedor cannot modify administrative modules', function () {
    $user = User::factory()->create([
        'role' => User::ROLE_VENDEDOR,
    ]);

    $admin = User::factory()->create([
        'role' => User::ROLE_ADMINISTRADOR,
    ]);

    $producto = Producto::query()->create([
        'codigo' => 'PROD-002',
        'nombre' => 'Producto restringido',
        'descripcion' => null,
        'precio_compra' => 20,
        'precio_venta' => 30,
        'stock' => 8,
        'unidad_medida' => 'unidad',
        'activo' => true,
    ]);

    $cliente = Cliente::query()->create([
        'nombre' => 'Cliente restringido',
        'documento' => '200300400',
        'telefono' => '3001111111',
        'email' => 'cliente2@demo.test',
        'direccion' => 'Calle 2',
        'notas' => null,
        'activo' => true,
        'created_by' => $admin->id,
    ]);

    $categoria = CategoriaServicio::query()->create([
        'nombre' => 'Categoria restringida',
        'descripcion' => null,
        'activo' => true,
    ]);

    $servicio = Servicio::query()->create([
        'categoria_servicio_id' => $categoria->id,
        'codigo' => 'SERV-002',
        'nombre' => 'Servicio restringido',
        'descripcion' => null,
        'precio_base' => 180,
        'activo' => true,
    ]);

    Sanctum::actingAs($user);

    $this->postJson('/api/v1/productos', [
        'codigo' => 'PROD-003',
        'nombre' => 'Nuevo producto',
        'precio_compra' => 10,
        'precio_venta' => 20,
        'stock' => 5,
        'unidad_medida' => 'unidad',
        'activo' => true,
    ])->assertForbidden();

    $this->putJson("/api/v1/productos/{$producto->id}", [
        'nombre' => 'Producto editado',
    ])->assertForbidden();

    $this->patchJson("/api/v1/productos/{$producto->id}/toggle-activo")
        ->assertForbidden();

    $this->deleteJson("/api/v1/productos/{$producto->id}")
        ->assertForbidden();

    $this->postJson('/api/v1/clientes', [
        'nombre' => 'Cliente nuevo',
        'documento' => '555666777',
    ])->assertForbidden();

    $this->putJson("/api/v1/clientes/{$cliente->id}", [
        'nombre' => 'Cliente editado',
    ])->assertForbidden();

    $this->postJson('/api/v1/categorias-servicio', [
        'nombre' => 'Nueva categoria',
    ])->assertForbidden();

    $this->postJson('/api/v1/servicios', [
        'categoria_servicio_id' => $categoria->id,
        'codigo' => 'SERV-003',
        'nombre' => 'Nuevo servicio',
        'descripcion' => 'Demo',
        'precio_base' => 200,
        'activo' => true,
    ])->assertForbidden();

    $this->putJson("/api/v1/servicios/{$servicio->id}", [
        'nombre' => 'Servicio editado',
    ])->assertForbidden();
});

test('vendedor cannot delete cotizaciones or facturas', function () {
    $user = User::factory()->create([
        'role' => User::ROLE_VENDEDOR,
    ]);

    $cliente = Cliente::query()->create([
        'nombre' => 'Cliente ventas',
        'documento' => '777888999',
        'telefono' => '3002222222',
        'email' => 'ventas@demo.test',
        'direccion' => 'Calle 3',
        'notas' => null,
        'activo' => true,
        'created_by' => User::factory()->create()->id,
    ]);

    $cotizacion = Cotizacion::query()->create([
        'cliente_id' => $cliente->id,
        'user_id' => $user->id,
        'codigo' => 'COT-DELETE',
        'item' => 'General',
        'obra' => 'Sin obra',
        'descripcion' => 'Sin descripcion',
        'unidad' => 'unidad',
        'fecha' => now()->toDateString(),
        'estado' => 'pendiente',
        'subtotal' => 10,
        'impuestos' => 0,
        'total' => 10,
    ]);

    $factura = Factura::query()->create([
        'cliente_id' => $cliente->id,
        'user_id' => $user->id,
        'numero' => 'FAC-DELETE',
        'fecha' => now()->toDateString(),
        'estado' => 'borrador',
        'subtotal' => 10,
        'impuestos' => 0,
        'total' => 10,
    ]);

    Sanctum::actingAs($user);

    $this->deleteJson("/api/v1/cotizaciones/{$cotizacion->id}")
        ->assertForbidden();

    $this->deleteJson("/api/v1/facturas/{$factura->id}")
        ->assertForbidden();
});

test('administrador has full access', function () {
    $user = User::factory()->create([
        'role' => User::ROLE_ADMINISTRADOR,
    ]);

    $cliente = Cliente::query()->create([
        'nombre' => 'Cliente admin',
        'documento' => '300400500',
        'telefono' => '3003333333',
        'email' => 'admincliente@demo.test',
        'direccion' => 'Calle admin',
        'notas' => null,
        'activo' => true,
        'created_by' => $user->id,
    ]);

    $producto = Producto::query()->create([
        'codigo' => 'PROD-010',
        'nombre' => 'Producto admin',
        'descripcion' => null,
        'precio_compra' => 50,
        'precio_venta' => 70,
        'stock' => 3,
        'unidad_medida' => 'unidad',
        'activo' => true,
    ]);

    $categoria = CategoriaServicio::query()->create([
        'nombre' => 'Mantenimiento',
        'descripcion' => null,
        'activo' => true,
    ]);

    $servicio = Servicio::query()->create([
        'categoria_servicio_id' => $categoria->id,
        'codigo' => 'SERV-010',
        'nombre' => 'Servicio admin',
        'descripcion' => null,
        'precio_base' => 300,
        'activo' => true,
    ]);

    Sanctum::actingAs($user);

    $this->postJson('/api/v1/productos', [
        'codigo' => 'PROD-011',
        'nombre' => 'Producto nuevo admin',
        'precio_compra' => 15,
        'precio_venta' => 25,
        'stock' => 9,
        'unidad_medida' => 'unidad',
        'activo' => true,
    ])->assertCreated();

    $this->putJson("/api/v1/productos/{$producto->id}", [
        'nombre' => 'Producto admin actualizado',
    ])->assertOk();

    $this->patchJson("/api/v1/productos/{$producto->id}/toggle-activo")
        ->assertOk();

    $this->deleteJson("/api/v1/productos/{$producto->id}")
        ->assertOk();

    $this->postJson('/api/v1/clientes', [
        'nombre' => 'Cliente nuevo admin',
        'documento' => '999111222',
        'telefono' => '3004444444',
    ])->assertCreated();

    $this->postJson('/api/v1/servicios', [
        'categoria_servicio_id' => $categoria->id,
        'codigo' => 'SERV-011',
        'nombre' => 'Servicio nuevo admin',
        'descripcion' => 'Demo',
        'precio_base' => 450,
        'activo' => true,
    ])->assertCreated();

    $this->putJson("/api/v1/servicios/{$servicio->id}", [
        'nombre' => 'Servicio admin actualizado',
    ])->assertOk();
});
