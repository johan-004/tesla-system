<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\CategoriaServicioController;
use App\Http\Controllers\Api\ClienteController;
use App\Http\Controllers\Api\CotizacionController;
use App\Http\Controllers\Api\FacturaController;
use App\Http\Controllers\Api\ProductoController;
use App\Http\Controllers\Api\ServicioController;
use App\Http\Controllers\Api\UserController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {
    Route::post('/auth/login', [AuthController::class, 'login']);

    Route::middleware('auth:sanctum')->group(function () {
        Route::get('/auth/me', [AuthController::class, 'me']);
        Route::post('/auth/logout', [AuthController::class, 'logout']);

        Route::get('productos/sugerencias', [ProductoController::class, 'suggestions'])
            ->middleware('permission:productos.view');
        Route::get('productos', [ProductoController::class, 'index'])
            ->middleware('permission:productos.view');
        Route::get('productos/{producto}', [ProductoController::class, 'show'])
            ->middleware('permission:productos.view');
        Route::post('productos', [ProductoController::class, 'store'])
            ->middleware('permission:productos.create');
        Route::put('productos/{producto}', [ProductoController::class, 'update'])
            ->middleware('permission:productos.update');
        Route::patch('productos/{producto}', [ProductoController::class, 'update'])
            ->middleware('permission:productos.update');
        Route::patch('productos/{producto}/toggle-activo', [ProductoController::class, 'toggleActivo'])
            ->middleware('permission:productos.toggle');
        Route::delete('productos/{producto}', [ProductoController::class, 'destroy'])
            ->middleware('permission:productos.delete');

        Route::get('clientes', [ClienteController::class, 'index'])
            ->middleware('permission:clientes.view');
        Route::get('clientes/{cliente}', [ClienteController::class, 'show'])
            ->middleware('permission:clientes.view');
        Route::post('clientes', [ClienteController::class, 'store'])
            ->middleware('permission:clientes.create');
        Route::put('clientes/{cliente}', [ClienteController::class, 'update'])
            ->middleware('permission:clientes.update');
        Route::patch('clientes/{cliente}', [ClienteController::class, 'update'])
            ->middleware('permission:clientes.update');
        Route::delete('clientes/{cliente}', [ClienteController::class, 'destroy'])
            ->middleware('permission:clientes.delete');

        Route::get('categorias-servicio', [CategoriaServicioController::class, 'index'])
            ->middleware('permission:categorias_servicio.view');
        Route::get('categorias-servicio/{categoriaServicio}', [CategoriaServicioController::class, 'show'])
            ->middleware('permission:categorias_servicio.view');
        Route::post('categorias-servicio', [CategoriaServicioController::class, 'store'])
            ->middleware('permission:categorias_servicio.create');
        Route::put('categorias-servicio/{categoriaServicio}', [CategoriaServicioController::class, 'update'])
            ->middleware('permission:categorias_servicio.update');
        Route::patch('categorias-servicio/{categoriaServicio}', [CategoriaServicioController::class, 'update'])
            ->middleware('permission:categorias_servicio.update');
        Route::delete('categorias-servicio/{categoriaServicio}', [CategoriaServicioController::class, 'destroy'])
            ->middleware('permission:categorias_servicio.delete');

        Route::get('servicios', [ServicioController::class, 'index'])
            ->middleware('permission:servicios.view');
        Route::get('servicios/{servicio}', [ServicioController::class, 'show'])
            ->middleware('permission:servicios.view');
        Route::post('servicios', [ServicioController::class, 'store'])
            ->middleware('permission:servicios.create');
        Route::put('servicios/{servicio}', [ServicioController::class, 'update'])
            ->middleware('permission:servicios.update');
        Route::patch('servicios/{servicio}', [ServicioController::class, 'update'])
            ->middleware('permission:servicios.update');
        Route::patch('servicios/{servicio}/toggle-activo', [ServicioController::class, 'toggleActivo'])
            ->middleware('permission:servicios.toggle');
        Route::delete('servicios/{servicio}', [ServicioController::class, 'destroy'])
            ->middleware('permission:servicios.delete');

        Route::get('cotizaciones', [CotizacionController::class, 'index'])
            ->middleware('permission:cotizaciones.view');
        Route::post('cotizaciones/firma/upload', [CotizacionController::class, 'uploadFirma'])
            ->middleware('permission:cotizaciones.update');
        Route::patch('cotizaciones/firma-predeterminada', [CotizacionController::class, 'guardarFirmaPredeterminada'])
            ->middleware('permission:cotizaciones.update');
        Route::get('cotizaciones/{cotizacion}', [CotizacionController::class, 'show'])
            ->middleware('permission:cotizaciones.view');
        Route::post('cotizaciones', [CotizacionController::class, 'store'])
            ->middleware('permission:cotizaciones.create');
        Route::put('cotizaciones/{cotizacion}', [CotizacionController::class, 'update'])
            ->middleware('permission:cotizaciones.update');
        Route::patch('cotizaciones/{cotizacion}', [CotizacionController::class, 'update'])
            ->middleware('permission:cotizaciones.update');
        Route::patch('cotizaciones/{cotizacion}/marcar-realizada', [CotizacionController::class, 'marcarRealizada'])
            ->middleware('permission:cotizaciones.update');
        Route::patch('cotizaciones/{cotizacion}/marcar-nula', [CotizacionController::class, 'marcarNula'])
            ->middleware('permission:cotizaciones.update');
        Route::patch('cotizaciones/{cotizacion}/anular', [CotizacionController::class, 'anular'])
            ->middleware('permission:cotizaciones.update');
        Route::delete('cotizaciones/{cotizacion}', [CotizacionController::class, 'destroy'])
            ->middleware('permission:cotizaciones.delete');

        Route::get('facturas', [FacturaController::class, 'index'])
            ->middleware('permission:facturacion.view');
        Route::get('facturas/{factura}', [FacturaController::class, 'show'])
            ->middleware('permission:facturacion.view');
        Route::post('facturas', [FacturaController::class, 'store'])
            ->middleware('permission:facturacion.create');
        Route::put('facturas/{factura}', [FacturaController::class, 'update'])
            ->middleware('permission:facturacion.update');
        Route::patch('facturas/{factura}', [FacturaController::class, 'update'])
            ->middleware('permission:facturacion.update');
        Route::patch('facturas/{factura}/emitir', [FacturaController::class, 'emitir'])
            ->middleware('permission:facturacion.update');
        Route::delete('facturas/{factura}', [FacturaController::class, 'destroy'])
            ->middleware('permission:facturacion.delete');

        Route::get('usuarios', [UserController::class, 'index'])
            ->middleware('permission:usuarios.view');
        Route::get('usuarios/{user}', [UserController::class, 'show'])
            ->middleware('permission:usuarios.view');
        Route::post('usuarios', [UserController::class, 'store'])
            ->middleware('permission:usuarios.create');
        Route::put('usuarios/{user}', [UserController::class, 'update'])
            ->middleware('permission:usuarios.update');
        Route::patch('usuarios/{user}', [UserController::class, 'update'])
            ->middleware('permission:usuarios.update');
        Route::delete('usuarios/{user}', [UserController::class, 'destroy'])
            ->middleware('permission:usuarios.delete');
    });
});
