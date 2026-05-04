<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\ProductoCategoriaResource;
use App\Models\ProductoCategoria;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ProductoCategoriaController extends Controller
{
    public function index(): JsonResponse
    {
        $categorias = ProductoCategoria::query()
            ->where('activo', true)
            ->orderBy('nombre')
            ->get();

        return response()->json([
            'message' => 'Categorias de productos obtenidas correctamente.',
            'data' => ProductoCategoriaResource::collection($categorias)->resolve(),
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'nombre' => ['required', 'string', 'max:120'],
        ]);

        $nombre = trim((string) $validated['nombre']);
        $nombreNormalizado = mb_strtolower(preg_replace('/\s+/', '', $nombre) ?? '');

        $existing = ProductoCategoria::query()
            ->whereRaw("LOWER(REPLACE(nombre, ' ', '')) = ?", [$nombreNormalizado])
            ->first();

        if ($existing) {
            if (! $existing->activo) {
                $existing->update(['activo' => true]);

                return response()->json([
                    'message' => 'Categoría reactivada correctamente.',
                    'data' => new ProductoCategoriaResource($existing->fresh()),
                ]);
            }

            return response()->json([
                'message' => 'La categoría ya existe.',
                'errors' => [
                    'nombre' => ['La categoría ya existe.'],
                ],
            ], 422);
        }

        $categoria = ProductoCategoria::query()->create([
            'nombre' => $nombre,
            'activo' => true,
        ]);

        return response()->json([
            'message' => 'Categoría creada correctamente.',
            'data' => new ProductoCategoriaResource($categoria),
        ], 201);
    }
}
