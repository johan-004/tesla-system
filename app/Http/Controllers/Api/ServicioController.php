<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\Servicio\StoreServicioRequest;
use App\Http\Requests\Api\Servicio\UpdateServicioRequest;
use App\Http\Resources\ServicioResource;
use App\Models\CategoriaServicio;
use App\Models\Servicio;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class ServicioController extends Controller
{
    public function index(Request $request)
    {
        $ordenesPermitidos = [
            'codigo',
            'descripcion',
            'categoria',
            'unidad',
            'precio_unitario',
            'iva',
            'precio_con_iva',
            'activo',
            'created_at',
        ];
        $direccionesPermitidas = ['asc', 'desc'];
        $orden = in_array($request->get('orden'), $ordenesPermitidos, true) ? $request->get('orden') : 'categoria';
        $direccion = in_array($request->get('direccion'), $direccionesPermitidas, true) ? $request->get('direccion') : 'asc';
        $perPage = max(1, min((int) $request->get('per_page', 10), 50));
        $buscar = trim((string) $request->get('buscar', ''));
        $categoria = Servicio::normalizeCategoria($request->get('categoria'));
        $activo = $request->get('activo');

        $servicios = Servicio::query()
            ->buscar($buscar)
            ->categoria($categoria)
            ->when($activo !== null && $activo !== '', fn ($query) => $query->where('activo', filter_var($activo, FILTER_VALIDATE_BOOLEAN, FILTER_NULL_ON_FAILURE)))
            ->orderBy($orden, $direccion)
            ->paginate($perPage)
            ->appends($request->query());

        return ServicioResource::collection($servicios)->additional([
            'message' => 'Servicios obtenidos correctamente.',
            'filters' => [
                'buscar' => $buscar,
                'categoria' => $categoria ?? '',
                'activo' => $activo,
                'orden' => $orden,
                'direccion' => $direccion,
                'per_page' => $perPage,
            ],
        ]);
    }

    public function store(StoreServicioRequest $request)
    {
        $servicio = Servicio::create($this->payloadFromRequest($request, true));

        return response()->json([
            'message' => 'Servicio creado correctamente.',
            'data' => new ServicioResource($servicio),
        ], 201);
    }

    public function show(Servicio $servicio)
    {
        return response()->json([
            'message' => 'Servicio obtenido correctamente.',
            'data' => new ServicioResource($servicio),
        ]);
    }

    public function update(UpdateServicioRequest $request, Servicio $servicio)
    {
        $servicio->update($this->payloadFromRequest($request, false, $servicio));

        return response()->json([
            'message' => 'Servicio actualizado correctamente.',
            'data' => new ServicioResource($servicio->fresh()),
        ]);
    }

    public function destroy(Servicio $servicio)
    {
        $servicio->update([
            'activo' => false,
        ]);

        return response()->json([
            'message' => 'Servicio inactivado correctamente.',
            'data' => new ServicioResource($servicio->fresh()),
        ]);
    }

    public function toggleActivo(Servicio $servicio)
    {
        $servicio->update([
            'activo' => ! $servicio->activo,
        ]);

        return response()->json([
            'message' => $servicio->activo ? 'Servicio activado correctamente.' : 'Servicio inactivado correctamente.',
            'data' => new ServicioResource($servicio->fresh()),
        ]);
    }

    private function payloadFromRequest(Request $request, bool $isStore, ?Servicio $servicio = null): array
    {
        $validated = $request->validated();
        $categoriaNombre = Servicio::normalizeCategoria($validated['categoria'] ?? $servicio?->categoria) ?? 'general';
        $categoriaServicio = CategoriaServicio::query()->firstOrCreate(
            ['nombre' => $categoriaNombre],
            [
                'descripcion' => 'Categoría creada automáticamente desde el módulo de servicios.',
                'activo' => true,
            ],
        );

        $descripcion = $validated['descripcion'] ?? $servicio?->descripcion ?? '';
        $precioUnitario = $validated['precio_unitario'] ?? $servicio?->precio_unitario ?? 0;
        $payload = [
            ...$validated,
            'categoria_servicio_id' => $categoriaServicio->id,
            'categoria' => $categoriaNombre,
            'nombre' => Str::limit($descripcion, 255, ''),
            'precio_base' => $precioUnitario,
        ];

        if ($isStore) {
            $payload['activo'] = $request->boolean('activo', true);
        }

        return $payload;
    }
}
