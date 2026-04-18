<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\Producto\StoreProductoRequest;
use App\Http\Requests\Api\Producto\UpdateProductoRequest;
use App\Http\Resources\ProductoResource;
use App\Models\Producto;
use Illuminate\Http\Request;

class ProductoController extends Controller
{
    public function index(Request $request)
    {
        $ordenesPermitidos = ['codigo', 'nombre', 'stock', 'precio_venta', 'iva_porcentaje', 'activo', 'created_at'];
        $direccionesPermitidas = ['asc', 'desc'];
        $orden = in_array($request->get('orden'), $ordenesPermitidos, true) ? $request->get('orden') : 'codigo';
        $direccion = in_array($request->get('direccion'), $direccionesPermitidas, true) ? $request->get('direccion') : 'asc';
        $perPage = max(1, min((int) $request->get('per_page', 10), 50));
        $buscar = trim((string) $request->get('buscar', ''));
        $activo = $request->get('activo');

        $productos = Producto::query()
            ->buscar($buscar)
            ->when($activo !== null && $activo !== '', fn ($query) => $query->where('activo', filter_var($activo, FILTER_VALIDATE_BOOLEAN, FILTER_NULL_ON_FAILURE)))
            ->orderBy($orden, $direccion)
            ->paginate($perPage)
            ->appends($request->query());

        return ProductoResource::collection($productos)->additional([
            'message' => 'Productos obtenidos correctamente.',
            'filters' => [
                'buscar' => $buscar,
                'activo' => $activo,
                'orden' => $orden,
                'direccion' => $direccion,
                'per_page' => $perPage,
            ],
        ]);
    }

    public function suggestions(Request $request)
    {
        $buscar = trim((string) $request->get('buscar', ''));
        $limite = (int) $request->get('limite', 6);

        if ($buscar === '') {
            return response()->json([
                'message' => 'Sin término de búsqueda.',
                'data' => [],
            ]);
        }

        $productos = Producto::query()
            ->sugerencias($buscar, $limite)
            ->get();

        return response()->json([
            'message' => 'Sugerencias obtenidas correctamente.',
            'data' => ProductoResource::collection($productos)->resolve(),
        ]);
    }

    public function store(StoreProductoRequest $request)
    {
        $producto = Producto::create([
            ...$request->validated(),
            'activo' => $request->boolean('activo', true),
        ]);

        return response()->json([
            'message' => 'Producto creado correctamente.',
            'data' => new ProductoResource($producto),
        ], 201);
    }

    public function show(Producto $producto)
    {
        return response()->json([
            'message' => 'Producto obtenido correctamente.',
            'data' => new ProductoResource($producto),
        ]);
    }

    public function update(UpdateProductoRequest $request, Producto $producto)
    {
        $producto->update($request->validated());

        return response()->json([
            'message' => 'Producto actualizado correctamente.',
            'data' => new ProductoResource($producto->fresh()),
        ]);
    }

    public function destroy(Producto $producto)
    {
        $producto->update([
            'activo' => false,
        ]);

        return response()->json([
            'message' => 'Producto inactivado correctamente.',
            'data' => new ProductoResource($producto->fresh()),
        ]);
    }

    public function toggleActivo(Producto $producto)
    {
        $producto->update([
            'activo' => ! $producto->activo,
        ]);

        return response()->json([
            'message' => $producto->activo ? 'Producto activado correctamente.' : 'Producto inactivado correctamente.',
            'data' => new ProductoResource($producto->fresh()),
        ]);
    }
}
