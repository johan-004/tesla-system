<?php

namespace App\Http\Controllers;

use App\Models\Producto;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ProductoController extends Controller
{
    public function index(Request $request)
    {
        $buscar = trim((string) $request->get('buscar', ''));
        $ordenesPermitidos = ['codigo', 'nombre', 'stock', 'precio_venta', 'activo'];
        $direccionesPermitidas = ['asc', 'desc'];

        $orden = in_array($request->get('orden'), $ordenesPermitidos, true) ? $request->get('orden') : 'codigo';
        $direccion = in_array($request->get('direccion'), $direccionesPermitidas, true) ? $request->get('direccion') : 'asc';
        $estado = in_array($request->get('estado'), ['todos', 'activos', 'inactivos'], true) ? $request->get('estado') : 'todos';

        $productos = Producto::query()
            ->buscar($buscar)
            ->when($estado === 'activos', fn ($query) => $query->where('activo', true))
            ->when($estado === 'inactivos', fn ($query) => $query->where('activo', false))
            ->orderBy($orden, $direccion)
            ->paginate(10)
            ->withQueryString();

        $stockBajo = Producto::query()
            ->where('activo', true)
            ->where('stock', '<=', 5)
            ->count();

        $resumen = [
            'total' => Producto::count(),
            'activos' => Producto::where('activo', true)->count(),
            'inactivos' => Producto::where('activo', false)->count(),
            'stock_bajo' => $stockBajo,
        ];

        return view('productos.index', [
            'productos' => $productos,
            'buscar' => $buscar,
            'orden' => $orden,
            'direccion' => $direccion,
            'estado' => $estado,
            'stockBajo' => $stockBajo,
            'resumen' => $resumen,
        ]);
    }

    public function suggestions(Request $request): JsonResponse
    {
        $buscar = trim((string) $request->get('buscar', ''));
        $limite = (int) $request->get('limite', 6);

        if ($buscar === '') {
            return response()->json([
                'data' => [],
            ]);
        }

        $productos = Producto::query()
            ->sugerencias($buscar, $limite)
            ->get(['id', 'codigo', 'nombre', 'precio_venta', 'stock', 'unidad_medida', 'activo']);

        return response()->json([
            'data' => $productos->map(fn (Producto $producto) => [
                'id' => $producto->id,
                'codigo' => $producto->codigo,
                'nombre' => $producto->nombre,
                'precio_venta' => number_format((float) $producto->precio_venta, 2, '.', ''),
                'stock' => $producto->stock,
                'unidad_medida' => $producto->unidad_medida,
                'activo' => (bool) $producto->activo,
            ])->values(),
        ]);
    }

    public function create()
    {
        return view('productos.create');
    }

    public function store(Request $request): RedirectResponse
    {
        $validated = $request->validate([
            'codigo' => 'required|unique:productos,codigo',
            'nombre' => 'required|max:255',
            'descripcion' => 'nullable|string',
            'precio_compra' => 'required|numeric|min:0',
            'precio_venta' => 'required|numeric|min:0',
            'stock' => 'required|integer|min:0',
            'unidad_medida' => 'required|string|max:50',
            'activo' => 'nullable|boolean',
        ], [
            'codigo.required' => 'El código es obligatorio.',
            'codigo.unique' => 'Este código ya existe.',
            'nombre.required' => 'El nombre es obligatorio.',
            'precio_compra.required' => 'El precio de compra es obligatorio.',
            'precio_venta.required' => 'El precio de venta es obligatorio.',
            'stock.required' => 'El stock es obligatorio.',
            'unidad_medida.required' => 'La unidad de medida es obligatoria.',
        ]);

        Producto::create([
            ...$validated,
            'activo' => $request->boolean('activo', true),
        ]);

        return redirect()->route('web.productos.index')
            ->with('success', 'Producto creado correctamente');
    }

    public function edit(Producto $producto)
    {
        return view('productos.edit', compact('producto'));
    }

    public function update(Request $request, Producto $producto): RedirectResponse
    {
        $validated = $request->validate([
            'codigo' => 'required|max:50|unique:productos,codigo,' . $producto->id,
            'nombre' => 'required|max:255',
            'descripcion' => 'nullable|string',
            'precio_compra' => 'required|numeric|min:0',
            'precio_venta' => 'required|numeric|min:0',
            'stock' => 'required|integer|min:0',
            'unidad_medida' => 'required|string|max:50',
            'activo' => 'nullable|boolean',
        ]);

        $producto->update([
            ...$validated,
            'activo' => $request->boolean('activo'),
        ]);

        return redirect()->route('web.productos.index')
            ->with('success', 'Producto actualizado correctamente');
    }

    public function destroy(Producto $producto): RedirectResponse
    {
        $producto->update([
            'activo' => false,
        ]);

        return redirect()->route('web.productos.index')
            ->with('success', 'Producto inactivado correctamente');
    }

    public function toggleActivo(Producto $producto): RedirectResponse
    {
        $producto->update([
            'activo' => ! $producto->activo,
        ]);

        return redirect()->route('web.productos.index', request()->query())
            ->with('success', $producto->activo ? 'Producto activado correctamente' : 'Producto inactivado correctamente');
    }
}
