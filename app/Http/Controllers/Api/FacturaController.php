<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\Factura\StoreFacturaRequest;
use App\Http\Requests\Api\Factura\UpdateFacturaRequest;
use App\Http\Resources\FacturaResource;
use App\Models\Factura;
use App\Models\FacturaItem;
use App\Models\Producto;
use App\Models\Servicio;
use App\Services\Alerts\AdminBusinessPushNotifier;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class FacturaController extends Controller
{
    public function index(Request $request)
    {
        $ordenesPermitidos = [
            'codigo',
            'fecha',
            'cliente_nombre',
            'subtotal',
            'iva_total',
            'total',
            'estado',
            'created_at',
        ];
        $direccionesPermitidas = ['asc', 'desc'];
        $orden = in_array($request->get('orden'), $ordenesPermitidos, true) ? $request->get('orden') : 'fecha';
        $direccion = in_array($request->get('direccion'), $direccionesPermitidas, true) ? $request->get('direccion') : 'desc';
        $perPage = max(1, min((int) $request->get('per_page', 10), 50));
        $buscar = trim((string) $request->get('buscar', ''));
        $estado = Factura::normalizeEstado($request->get('estado'));

        $baseQuery = Factura::query()->visibleFlow();
        $filteredQuery = Factura::query()
            ->visibleFlow()
            ->buscar($buscar)
            ->estado($estado);

        $facturas = $filteredQuery
            ->orderBy($orden, $direccion)
            ->paginate($perPage)
            ->appends($request->query());

        return FacturaResource::collection($facturas)->additional([
            'message' => 'Facturas obtenidas correctamente.',
            'filters' => [
                'buscar' => $buscar,
                'estado' => $estado ?? '',
                'orden' => $orden,
                'direccion' => $direccion,
                'per_page' => $perPage,
            ],
            'stats' => [
                'total' => (clone $baseQuery)->count(),
                'pendiente' => (clone $baseQuery)->pendiente()->count(),
                'borrador' => (clone $baseQuery)->pendiente()->count(), // Legacy key
                'emitida' => (clone $baseQuery)->where('estado', Factura::ESTADO_EMITIDA)->count(),
                'anulada' => (clone $baseQuery)->where('estado', Factura::ESTADO_ANULADA)->count(),
            ],
        ]);
    }

    public function store(
        StoreFacturaRequest $request,
        AdminBusinessPushNotifier $adminBusinessPushNotifier
    ): JsonResponse
    {
        $actor = $request->user();

        $factura = DB::transaction(function () use ($request, $actor) {
            $payload = $request->validated();
            $items = $payload['items'];

            $calculated = $this->calculateItems($items);

            $factura = Factura::create([
                'codigo' => $this->generateCodigo(),
                'numero' => null,
                'fecha' => $payload['fecha'],
                'ciudad_expedicion' => trim((string) ($payload['ciudad_expedicion'] ?? 'Villavicencio, Meta')),
                'cliente_id' => $payload['cliente_id'] ?? null,
                'cliente_nombre' => trim((string) $payload['cliente_nombre']),
                'cliente_nit' => trim((string) ($payload['cliente_nit'] ?? '')),
                'cliente_contacto' => trim((string) ($payload['cliente_contacto'] ?? '')),
                'cliente_direccion' => trim((string) ($payload['cliente_direccion'] ?? '')),
                'cliente_ciudad' => trim((string) ($payload['cliente_ciudad'] ?? 'Villavicencio.')),
                'observaciones' => $payload['observaciones'] ?? null,
                'firma_path' => trim((string) ($payload['firma_path'] ?? '')),
                'firma_nombre' => trim((string) ($payload['firma_nombre'] ?? 'María Alejandra Flórez Ocampo.')),
                'firma_cargo' => trim((string) ($payload['firma_cargo'] ?? 'Representante Legal')),
                'firma_empresa' => trim((string) ($payload['firma_empresa'] ?? 'Proyecciones eléctricas Tesla.')),
                'estado' => Factura::ESTADO_PENDIENTE,
                'subtotal' => $calculated['subtotal'],
                'iva_total' => $calculated['iva_total'],
                'impuestos' => $calculated['iva_total'],
                'total' => $calculated['total'],
                'created_by' => $actor?->id,
                'updated_by' => $actor?->id,
                'user_id' => $actor?->id,
            ]);

            $factura->update([
                'numero' => $factura->codigo,
            ]);

            $this->syncItems($factura, $calculated['items']);

            return $factura;
        });

        $adminBusinessPushNotifier->notifyFacturaCreatedBySeller(
            $factura,
            $actor
        );

        return response()->json([
            'message' => 'Factura guardada como pendiente correctamente.',
            'data' => new FacturaResource($factura->load(['creator', 'updater', 'items'])),
        ], 201);
    }

    public function show(Factura $factura): JsonResponse
    {
        return response()->json([
            'message' => 'Factura obtenida correctamente.',
            'data' => new FacturaResource($factura->load(['creator', 'updater', 'emitter', 'items'])),
        ]);
    }

    public function update(UpdateFacturaRequest $request, Factura $factura): JsonResponse
    {
        if (! $factura->canBeUpdated()) {
            return response()->json([
                'message' => 'Solo se puede editar una factura en estado pendiente.',
            ], 422);
        }

        $actor = $request->user();

        DB::transaction(function () use ($request, $factura, $actor) {
            $payload = $request->validated();

            $updatePayload = [
                'updated_by' => $actor?->id,
            ];

            if (array_key_exists('fecha', $payload)) {
                $updatePayload['fecha'] = $payload['fecha'];
            }
            if (array_key_exists('ciudad_expedicion', $payload)) {
                $updatePayload['ciudad_expedicion'] = trim((string) ($payload['ciudad_expedicion'] ?? ''));
            }
            if (array_key_exists('cliente_id', $payload)) {
                $updatePayload['cliente_id'] = $payload['cliente_id'];
            }
            if (array_key_exists('cliente_nombre', $payload)) {
                $updatePayload['cliente_nombre'] = trim((string) $payload['cliente_nombre']);
            }
            if (array_key_exists('cliente_nit', $payload)) {
                $updatePayload['cliente_nit'] = trim((string) ($payload['cliente_nit'] ?? ''));
            }
            if (array_key_exists('cliente_contacto', $payload)) {
                $updatePayload['cliente_contacto'] = trim((string) ($payload['cliente_contacto'] ?? ''));
            }
            if (array_key_exists('cliente_direccion', $payload)) {
                $updatePayload['cliente_direccion'] = trim((string) ($payload['cliente_direccion'] ?? ''));
            }
            if (array_key_exists('cliente_ciudad', $payload)) {
                $updatePayload['cliente_ciudad'] = trim((string) ($payload['cliente_ciudad'] ?? ''));
            }
            if (array_key_exists('observaciones', $payload)) {
                $updatePayload['observaciones'] = $payload['observaciones'];
            }
            if (array_key_exists('firma_path', $payload)) {
                $updatePayload['firma_path'] = trim((string) ($payload['firma_path'] ?? ''));
            }
            if (array_key_exists('firma_nombre', $payload)) {
                $updatePayload['firma_nombre'] = trim((string) ($payload['firma_nombre'] ?? ''));
            }
            if (array_key_exists('firma_cargo', $payload)) {
                $updatePayload['firma_cargo'] = trim((string) ($payload['firma_cargo'] ?? ''));
            }
            if (array_key_exists('firma_empresa', $payload)) {
                $updatePayload['firma_empresa'] = trim((string) ($payload['firma_empresa'] ?? ''));
            }

            if (array_key_exists('items', $payload)) {
                $calculated = $this->calculateItems($payload['items']);
                $updatePayload['subtotal'] = $calculated['subtotal'];
                $updatePayload['iva_total'] = $calculated['iva_total'];
                $updatePayload['impuestos'] = $calculated['iva_total'];
                $updatePayload['total'] = $calculated['total'];

                $factura->update($updatePayload);
                $this->syncItems($factura, $calculated['items']);

                return;
            }

            $factura->update($updatePayload);
        });

        return response()->json([
            'message' => 'Factura actualizada correctamente.',
            'data' => new FacturaResource($factura->fresh()->load(['creator', 'updater', 'items'])),
        ]);
    }

    public function emitir(Request $request, Factura $factura): JsonResponse
    {
        $actor = $request->user();
        $notifier = app(AdminBusinessPushNotifier::class);

        if (! $factura->canBeEmitted()) {
            return response()->json([
                'message' => 'Solo se pueden emitir facturas en estado pendiente.',
            ], 422);
        }

        $productosSinStock = [];
        DB::transaction(function () use ($factura, $actor) {
            $factura = Factura::query()
                ->lockForUpdate()
                ->with('items')
                ->findOrFail($factura->id);

            if (! $factura->canBeEmitted()) {
                throw ValidationException::withMessages([
                    'estado' => 'La factura ya cambió de estado y no puede emitirse.',
                ]);
            }

            if ($factura->items->isEmpty()) {
                throw ValidationException::withMessages([
                    'items' => 'La factura debe tener al menos un item para emitirse.',
                ]);
            }

            $this->decrementStockForFacturaItems($factura->items->all());

            $factura->update([
                'estado' => Factura::ESTADO_EMITIDA,
                'emitida_at' => now(),
                'emitida_by' => $actor?->id,
                'updated_by' => $actor?->id,
            ]);
        });

        $factura = $factura->fresh(['creator', 'updater', 'emitter', 'items']);
        $productosSinStock = $this->collectProductosSinStockAfterEmit($factura->items->all());
        foreach ($productosSinStock as $producto) {
            $notifier->notifyProductoOutOfStock($producto, $factura, $actor);
        }

        return response()->json([
            'message' => 'Factura emitida correctamente.',
            'data' => new FacturaResource($factura),
        ]);
    }

    public function anular(Request $request, Factura $factura): JsonResponse
    {
        if (! $factura->canBeAnnulled()) {
            return response()->json([
                'message' => 'Solo se pueden anular facturas en estado pendiente.',
            ], 422);
        }

        $actor = $request->user();

        DB::transaction(function () use ($factura, $actor) {
            $locked = Factura::query()
                ->lockForUpdate()
                ->findOrFail($factura->id);

            if (! $locked->canBeAnnulled()) {
                throw ValidationException::withMessages([
                    'estado' => 'La factura ya cambió de estado y no puede anularse.',
                ]);
            }

            $locked->update([
                'estado' => Factura::ESTADO_ANULADA,
                'anulada_at' => now(),
                'anulada_by' => $actor?->id,
                'updated_by' => $actor?->id,
            ]);
        });

        return response()->json([
            'message' => 'Factura anulada correctamente.',
            'data' => new FacturaResource($factura->fresh()->load(['creator', 'updater', 'emitter', 'annuller', 'items'])),
        ]);
    }

    public function destroy(Factura $factura): JsonResponse
    {
        if (! $factura->canBeUpdated()) {
            return response()->json([
                'message' => 'Solo se pueden eliminar facturas en estado pendiente.',
            ], 422);
        }

        DB::transaction(function () use ($factura) {
            $factura->items()->delete();
            $factura->delete();
        });

        return response()->json([
            'message' => 'Factura pendiente eliminada correctamente.',
        ]);
    }

    private function generateCodigo(): string
    {
        $lastFactura = Factura::query()
            ->lockForUpdate()
            ->select(['codigo', 'numero'])
            ->orderByDesc('id')
            ->first();

        $lastSequence = max(
            $this->extractCodeSequence($lastFactura?->codigo),
            $this->extractCodeSequence($lastFactura?->numero),
        );

        return sprintf('FAC-%03d', $lastSequence + 1);
    }

    private function extractCodeSequence(?string $value): int
    {
        if (! is_string($value)) {
            return 0;
        }

        if (preg_match('/^FAC-(\d+)$/', trim($value), $matches) !== 1) {
            return 0;
        }

        return (int) $matches[1];
    }

    private function calculateItems(array $items): array
    {
        if (count($items) === 0) {
            throw ValidationException::withMessages([
                'items' => 'La factura debe tener al menos un item.',
            ]);
        }

        $calculatedItems = [];
        $subtotal = 0.0;
        $ivaTotal = 0.0;
        $total = 0.0;

        foreach ($items as $index => $item) {
            $tipoItem = trim((string) ($item['tipo_item'] ?? ''));
            $productoId = isset($item['producto_id']) ? (int) $item['producto_id'] : null;
            $servicioId = isset($item['servicio_id']) ? (int) $item['servicio_id'] : null;
            $cantidad = (float) ($item['cantidad'] ?? 0);
            $descripcion = trim((string) ($item['descripcion'] ?? ''));
            $unidad = trim((string) ($item['unidad'] ?? 'Un.'));
            $precioUnitario = (float) ($item['precio_unitario'] ?? 0);
            $ivaPorcentaje = (float) ($item['iva_porcentaje'] ?? 0);
            $codigo = trim((string) ($item['codigo'] ?? ''));

            if ($tipoItem === '') {
                $tipoItem = $productoId ? 'producto' : 'servicio';
            }

            if ($descripcion === '') {
                throw ValidationException::withMessages([
                    "items.{$index}.descripcion" => 'La descripción del item es obligatoria.',
                ]);
            }

            if ($cantidad <= 0) {
                throw ValidationException::withMessages([
                    "items.{$index}.cantidad" => 'La cantidad debe ser mayor a cero.',
                ]);
            }

            if ($precioUnitario < 0) {
                throw ValidationException::withMessages([
                    "items.{$index}.precio_unitario" => 'El valor unitario no puede ser negativo.',
                ]);
            }

            if ($ivaPorcentaje < 0 || $ivaPorcentaje > 100) {
                throw ValidationException::withMessages([
                    "items.{$index}.iva_porcentaje" => 'El IVA debe estar entre 0 y 100.',
                ]);
            }

            $subtotalLinea = round($cantidad * $precioUnitario, 2);
            $ivaValor = round($subtotalLinea * ($ivaPorcentaje / 100), 2);
            $totalLinea = round($subtotalLinea + $ivaValor, 2);

            $subtotal += $subtotalLinea;
            $ivaTotal += $ivaValor;
            $total += $totalLinea;

            if ($tipoItem === 'producto' && $productoId) {
                $producto = Producto::query()->find($productoId);
                $codigo = $codigo !== '' ? $codigo : trim((string) ($producto?->codigo ?? ''));
                if ($descripcion === '') {
                    $descripcion = trim((string) ($producto?->nombre ?? ''));
                }
            } elseif ($tipoItem === 'servicio' && $servicioId) {
                $servicio = Servicio::query()->find($servicioId);
                $codigo = $codigo !== '' ? $codigo : trim((string) ($servicio?->codigo ?? ''));
                if ($descripcion === '') {
                    $descripcion = trim((string) ($servicio?->descripcion ?? ''));
                }
            }

            if ($descripcion === '') {
                $descripcion = 'Ítem sin nombre';
            }

            $calculatedItems[] = [
                'tipo_item' => $tipoItem === 'producto' ? 'producto' : 'servicio',
                'producto_id' => $productoId,
                'servicio_id' => $servicioId,
                'codigo' => $codigo,
                'orden' => $index + 1,
                'descripcion' => $descripcion,
                'unidad' => $unidad === '' ? 'Un.' : $unidad,
                'cantidad' => $cantidad,
                'precio_unitario' => $precioUnitario,
                'iva_porcentaje' => $ivaPorcentaje,
                'iva_valor' => $ivaValor,
                'subtotal_linea' => $subtotalLinea,
                'total_linea' => $totalLinea,
            ];
        }

        return [
            'items' => $calculatedItems,
            'subtotal' => round($subtotal, 2),
            'iva_total' => round($ivaTotal, 2),
            'total' => round($total, 2),
        ];
    }

    private function syncItems(Factura $factura, array $items): void
    {
        $factura->items()->delete();

        foreach ($items as $item) {
            FacturaItem::query()->create([
                'factura_id' => $factura->id,
                'tipo_item' => $item['tipo_item'] ?? 'servicio',
                'producto_id' => $item['producto_id'] ?? null,
                'servicio_id' => $item['servicio_id'] ?? null,
                'codigo' => $item['codigo'] ?? null,
                'orden' => $item['orden'],
                'descripcion' => $item['descripcion'],
                'unidad' => $item['unidad'],
                'cantidad' => $item['cantidad'],
                'precio_unitario' => $item['precio_unitario'],
                'iva_porcentaje' => $item['iva_porcentaje'],
                'iva_valor' => $item['iva_valor'],
                'subtotal_linea' => $item['subtotal_linea'],
                'total_linea' => $item['total_linea'],
            ]);
        }
    }

    private function decrementStockForFacturaItems(array $items): void
    {
        foreach ($items as $index => $item) {
            if (($item->tipo_item ?? '') !== 'producto') {
                continue;
            }

            $productoId = $item->producto_id;
            if (! $productoId) {
                continue;
            }

            $cantidad = (int) round((float) $item->cantidad);
            if ($cantidad <= 0) {
                continue;
            }

            $producto = Producto::query()->lockForUpdate()->find($productoId);
            if (! $producto) {
                throw ValidationException::withMessages([
                    "items.{$index}" => 'El producto asociado al item ya no existe.',
                ]);
            }

            if ((int) $producto->stock < $cantidad) {
                throw ValidationException::withMessages([
                    "items.{$index}.cantidad" => sprintf(
                        'Stock insuficiente para %s. Disponible: %d, solicitado: %d.',
                        $producto->nombre,
                        (int) $producto->stock,
                        $cantidad
                    ),
                ]);
            }

            $producto->decrement('stock', $cantidad);
        }
    }

    /**
     * @param array<int, FacturaItem> $items
     * @return array<int, Producto>
     */
    private function collectProductosSinStockAfterEmit(array $items): array
    {
        $productoIds = collect($items)
            ->filter(fn (FacturaItem $item) => ($item->tipo_item ?? '') === 'producto' && (int) ($item->producto_id ?? 0) > 0)
            ->map(fn (FacturaItem $item) => (int) $item->producto_id)
            ->unique()
            ->values()
            ->all();

        if ($productoIds === []) {
            return [];
        }

        return Producto::query()
            ->whereIn('id', $productoIds)
            ->where('stock', '<=', 0)
            ->get()
            ->all();
    }
}
