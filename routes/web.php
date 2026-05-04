<?php

use App\Http\Controllers\ProfileController;
use App\Http\Controllers\ProductoController;
use App\Http\Controllers\CotizacionController;
use App\Http\Controllers\WebDashboardController;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

// Dashboard protegido por login y verificación
Route::get('/dashboard', [WebDashboardController::class, 'index'])
    ->middleware(['auth', 'verified'])
    ->name('dashboard');

// Grupo de rutas que requieren autenticación
Route::middleware('auth')->group(function () {
    // Perfil de usuario
    Route::get('/profile', [ProfileController::class, 'edit'])->name('profile.edit');
    Route::patch('/profile', [ProfileController::class, 'update'])->name('profile.update');
    Route::delete('/profile', [ProfileController::class, 'destroy'])->name('profile.destroy');

    // Productos (CRUD completo)
    Route::get('productos/sugerencias', [ProductoController::class, 'suggestions'])
        ->name('web.productos.sugerencias');
    Route::patch('productos/{producto}/toggle-activo', [ProductoController::class, 'toggleActivo'])
        ->name('web.productos.toggle-activo');
    Route::resource('productos', ProductoController::class)->names('web.productos');

    // Cotizaciones (CRUD completo)
    Route::resource('cotizaciones', CotizacionController::class);
});

require __DIR__.'/auth.php';
