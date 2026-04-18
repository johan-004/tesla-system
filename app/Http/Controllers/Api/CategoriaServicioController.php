<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\CategoriaServicio\StoreCategoriaServicioRequest;
use App\Http\Requests\Api\CategoriaServicio\UpdateCategoriaServicioRequest;
use App\Http\Resources\CategoriaServicioResource;
use App\Models\CategoriaServicio;

class CategoriaServicioController extends Controller
{
    public function index()
    {
        $categorias = CategoriaServicio::query()->orderBy('nombre')->paginate(15);

        return CategoriaServicioResource::collection($categorias);
    }

    public function store(StoreCategoriaServicioRequest $request)
    {
        $categoria = CategoriaServicio::create([
            ...$request->validated(),
            'activo' => $request->boolean('activo', true),
        ]);

        return (new CategoriaServicioResource($categoria))
            ->response()
            ->setStatusCode(201);
    }

    public function show(CategoriaServicio $categoriaServicio)
    {
        return new CategoriaServicioResource($categoriaServicio);
    }

    public function update(UpdateCategoriaServicioRequest $request, CategoriaServicio $categoriaServicio)
    {
        $categoriaServicio->update($request->validated());

        return new CategoriaServicioResource($categoriaServicio->fresh());
    }

    public function destroy(CategoriaServicio $categoriaServicio)
    {
        $categoriaServicio->delete();

        return response()->json([
            'message' => 'Categoría eliminada correctamente.',
        ]);
    }
}
