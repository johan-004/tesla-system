<?php

namespace App\Http\Controllers\Api;

use App\Events\CotizacionCreada;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\Cotizacion\StoreCotizacionRequest;
use App\Http\Requests\Api\Cotizacion\UpdateCotizacionRequest;
use App\Http\Resources\CotizacionResource;
use App\Models\Cotizacion;
use App\Models\CotizacionDetalle;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Exceptions\HttpResponseException;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class CotizacionController extends Controller
{
    public function index(Request $request)
    {
        $ordenesPermitidos = [
            'numero',
            'codigo',
            'fecha',
            'ciudad',
            'cliente_nombre',
            'referencia',
            'subtotal',
            'total',
            'estado',
            'created_at',
        ];
        $direccionesPermitidas = ['asc', 'desc'];
        $orden = in_array($request->get('orden'), $ordenesPermitidos, true) ? $request->get('orden') : 'fecha';
        $direccion = in_array($request->get('direccion'), $direccionesPermitidas, true) ? $request->get('direccion') : 'desc';
        $perPage = max(1, min((int) $request->get('per_page', 10), 50));
        $buscar = trim((string) $request->get('buscar', ''));
        $estado = Cotizacion::normalizeEstado($request->get('estado'));

        $baseQuery = Cotizacion::query();
        $filteredQuery = Cotizacion::query()
            ->buscar($buscar)
            ->estado($estado);

        $cotizaciones = $filteredQuery
            ->orderBy($orden, $direccion)
            ->paginate($perPage)
            ->appends($request->query());

        return CotizacionResource::collection($cotizaciones)->additional([
            'message' => 'Cotizaciones obtenidas correctamente.',
            'filters' => [
                'buscar' => $buscar,
                'estado' => $estado ?? '',
                'orden' => $orden,
                'direccion' => $direccion,
                'per_page' => $perPage,
            ],
            'stats' => [
                'total' => (clone $baseQuery)->count(),
                'pendiente' => (clone $baseQuery)->where('estado', Cotizacion::ESTADO_PENDIENTE)->count(),
                'visto' => (clone $baseQuery)->where('estado', Cotizacion::ESTADO_VISTO)->count(),
                'realizada' => (clone $baseQuery)->where('estado', Cotizacion::ESTADO_REALIZADA)->count(),
                'nula' => (clone $baseQuery)->where('estado', Cotizacion::ESTADO_NULA)->count(),
            ],
        ]);
    }

    public function store(StoreCotizacionRequest $request): JsonResponse
    {
        $actor = $request->user();

        $cotizacion = DB::transaction(function () use ($request, $actor) {
            $payload = $request->validated();
            $detalles = $payload['detalles'] ?? [];
            unset($payload['detalles']);
            $payload['alcance_items'] = $this->normalizeAlcanceItems($payload['alcance_items'] ?? []);
            $payload['oferta_dias_totales'] = (int) ($payload['oferta_dias_totales'] ?? 30);
            $payload['oferta_dias_ejecucion'] = (int) ($payload['oferta_dias_ejecucion'] ?? 15);
            $payload['oferta_dias_tramitologia'] = (int) ($payload['oferta_dias_tramitologia'] ?? 15);
            $payload['oferta_pago_1_pct'] = (float) ($payload['oferta_pago_1_pct'] ?? 50);
            $payload['oferta_pago_2_pct'] = (float) ($payload['oferta_pago_2_pct'] ?? 25);
            $payload['oferta_pago_3_pct'] = (float) ($payload['oferta_pago_3_pct'] ?? 25);
            $payload['oferta_garantia_meses'] = (int) ($payload['oferta_garantia_meses'] ?? 6);
            $payload['firma_path'] = trim((string) ($payload['firma_path'] ?? '')) !== ''
                ? trim((string) $payload['firma_path'])
                : $actor?->firma_path_default;
            $payload['firma_nombre'] = trim((string) ($payload['firma_nombre'] ?? '')) !== ''
                ? trim((string) $payload['firma_nombre'])
                : ($actor?->firma_nombre_default ?: 'María Alejandra Flórez Ocampo.');
            $payload['firma_cargo'] = trim((string) ($payload['firma_cargo'] ?? '')) !== ''
                ? trim((string) $payload['firma_cargo'])
                : ($actor?->firma_cargo_default ?: 'Representante.');
            $payload['firma_empresa'] = trim((string) ($payload['firma_empresa'] ?? '')) !== ''
                ? trim((string) $payload['firma_empresa'])
                : ($actor?->firma_empresa_default ?: 'Proyecciones eléctricas Tesla');
            $payload['numero'] = $this->generateNumero();
            $payload['codigo'] = $payload['numero'];
            $payload['estado'] = Cotizacion::ESTADO_PENDIENTE;
            $payload['created_by'] = $actor?->id;
            $payload['updated_by'] = $actor?->id;
            $payload['user_id'] = $actor?->id;
            $payload['impuestos'] = 0;
            $payload['subtotal'] = $this->calculateDetallesTotal($detalles);
            $payload['total'] = $payload['subtotal'];
            $payload['item'] = (string) count($detalles);
            $payload['obra'] = $payload['obra'] ?? $payload['referencia'];
            $payload['descripcion'] = $payload['descripcion'] ?? $this->buildDescripcionResumen($detalles, $payload['referencia']);
            $payload['unidad'] = $payload['unidad'] ?? 'servicio';

            $cotizacion = Cotizacion::create($payload);
            $this->syncDetalles($cotizacion, $detalles);

            return $cotizacion;
        });

        // Punto de integración para futura push notification a administradora.
        event(new CotizacionCreada($cotizacion, $actor?->id));

        return response()->json([
            'message' => 'Cotización creada correctamente.',
            'data' => new CotizacionResource($cotizacion->load(['creator', 'updater', 'detalles'])),
        ], 201);
    }

    public function show(Cotizacion $cotizacion): JsonResponse
    {
        if (request()->user()?->isAdministrador() && $cotizacion->canBeMarkedAsVista()) {
            $cotizacion->update([
                'estado' => Cotizacion::ESTADO_VISTO,
                'updated_by' => request()->user()?->id,
            ]);
        }

        return response()->json([
            'message' => 'Cotización obtenida correctamente.',
            'data' => new CotizacionResource($cotizacion->load(['creator', 'updater', 'detalles'])),
        ]);
    }

    public function update(UpdateCotizacionRequest $request, Cotizacion $cotizacion): JsonResponse
    {
        DB::transaction(function () use ($request, $cotizacion) {
            $payload = $request->validated();
            $detalles = $payload['detalles'] ?? null;

            unset($payload['detalles'], $payload['estado'], $payload['numero'], $payload['codigo']);

            if (array_key_exists('alcance_items', $payload)) {
                $payload['alcance_items'] = $this->normalizeAlcanceItems($payload['alcance_items'] ?? []);
            }

            if (is_array($detalles)) {
                $payload['subtotal'] = $this->calculateDetallesTotal($detalles);
                $payload['total'] = $payload['subtotal'];
                $payload['item'] = (string) count($detalles);
                $payload['descripcion'] = $this->buildDescripcionResumen(
                    $detalles,
                    $payload['referencia'] ?? $cotizacion->referencia
                );
                $payload['unidad'] = 'servicio';
            }

            $payload['updated_by'] = $request->user()?->id;

            $cotizacion->update($payload);

            if (is_array($detalles)) {
                $this->syncDetalles($cotizacion, $detalles);
            }
        });

        return response()->json([
            'message' => 'Cotización actualizada correctamente.',
            'data' => new CotizacionResource($cotizacion->fresh()->load(['creator', 'updater', 'detalles'])),
        ]);
    }

    public function uploadFirma(Request $request): JsonResponse
    {
        $this->ensureAdministrador($request);

        $validated = $request->validate([
            'firma' => ['required', 'file', 'mimes:png,jpg,jpeg', 'max:4096'],
        ]);

        $file = $validated['firma'];
        $filename = sprintf('firma-%s.%s', Str::uuid()->toString(), $file->getClientOriginalExtension());
        $storedPath = $file->storeAs('firmas', $filename, 'public');
        $publicUrl = $request->getSchemeAndHttpHost().Storage::url($storedPath);

        return response()->json([
            'message' => 'Firma cargada correctamente.',
            'data' => [
                'firma_path' => $publicUrl,
                'storage_path' => $storedPath,
            ],
        ]);
    }

    public function guardarFirmaPredeterminada(Request $request): JsonResponse
    {
        $this->ensureAdministrador($request);

        $validated = $request->validate([
            'firma_path' => ['nullable', 'string', 'max:1000'],
            'firma_nombre' => ['nullable', 'string', 'max:255'],
            'firma_cargo' => ['nullable', 'string', 'max:255'],
            'firma_empresa' => ['nullable', 'string', 'max:255'],
        ]);

        $user = $request->user();
        $user?->update([
            'firma_path_default' => trim((string) ($validated['firma_path'] ?? '')) !== ''
                ? trim((string) $validated['firma_path'])
                : null,
            'firma_nombre_default' => trim((string) ($validated['firma_nombre'] ?? '')) !== ''
                ? trim((string) $validated['firma_nombre'])
                : 'María Alejandra Flórez Ocampo.',
            'firma_cargo_default' => trim((string) ($validated['firma_cargo'] ?? '')) !== ''
                ? trim((string) $validated['firma_cargo'])
                : 'Representante.',
            'firma_empresa_default' => trim((string) ($validated['firma_empresa'] ?? '')) !== ''
                ? trim((string) $validated['firma_empresa'])
                : 'Proyecciones eléctricas Tesla',
        ]);

        return response()->json([
            'message' => 'Firma predeterminada actualizada correctamente.',
        ]);
    }

    public function marcarRealizada(Request $request, Cotizacion $cotizacion): JsonResponse
    {
        $this->ensureAdministrador($request);

        if (! $cotizacion->canBeMarkedAsRealizada()) {
            return response()->json([
                'message' => 'La cotización solo puede marcarse como realizada cuando ya fue revisada por administración.',
            ], 422);
        }

        $cotizacion->update([
            'estado' => Cotizacion::ESTADO_REALIZADA,
            'updated_by' => $request->user()?->id,
        ]);

        return response()->json([
            'message' => 'Cotización marcada como realizada correctamente.',
            'data' => new CotizacionResource($cotizacion->fresh()->load(['creator', 'updater'])),
        ]);
    }

    public function marcarNula(Request $request, Cotizacion $cotizacion): JsonResponse
    {
        $this->ensureAdministrador($request);

        if (! $cotizacion->canBeMarkedAsNula()) {
            return response()->json([
                'message' => 'La cotización ya no puede marcarse como nula.',
            ], 422);
        }

        $cotizacion->update([
            'estado' => Cotizacion::ESTADO_NULA,
            'updated_by' => $request->user()?->id,
        ]);

        return response()->json([
            'message' => 'Cotización marcada como nula correctamente.',
            'data' => new CotizacionResource($cotizacion->fresh()->load(['creator', 'updater'])),
        ]);
    }

    public function anular(Request $request, Cotizacion $cotizacion): JsonResponse
    {
        return $this->marcarNula($request, $cotizacion);
    }

    public function destroy(Request $request, Cotizacion $cotizacion): JsonResponse
    {
        return $this->marcarNula($request, $cotizacion);
    }

    private function ensureAdministrador(Request $request): void
    {
        if (! $request->user()?->isAdministrador()) {
            throw new HttpResponseException(response()->json([
                'message' => 'Solo la administradora puede cambiar el estado final de la cotización.',
            ], 403));
        }
    }

    private function generateNumero(): string
    {
        $lastCotizacion = Cotizacion::query()
            ->lockForUpdate()
            ->select(['numero', 'codigo'])
            ->orderByDesc('id')
            ->first();

        $lastSequence = max(
            $this->extractShortCodeSequence($lastCotizacion?->numero),
            $this->extractShortCodeSequence($lastCotizacion?->codigo),
        );

        return $this->formatShortCode($lastSequence + 1);
    }

    private function extractShortCodeSequence(?string $value): int
    {
        if (! is_string($value)) {
            return 0;
        }

        if (preg_match('/^COT-(?:\d{4}-)?(\d+)$/', trim($value), $matches) !== 1) {
            return 0;
        }

        return (int) $matches[1];
    }

    private function formatShortCode(int $sequence): string
    {
        return sprintf('COT-%03d', $sequence);
    }

    private function syncDetalles(Cotizacion $cotizacion, array $detalles): void
    {
        $cotizacion->detalles()->delete();

        foreach ($detalles as $detalle) {
            CotizacionDetalle::query()->create([
                'cotizacion_id' => $cotizacion->id,
                'servicio_id' => $detalle['servicio_id'] ?? null,
                'categoria' => 'servicio',
                'descripcion' => trim((string) ($detalle['descripcion'] ?? '')),
                'unidad' => trim((string) ($detalle['unidad'] ?? '')),
                'cantidad' => (float) ($detalle['cantidad'] ?? 0),
                'precio_unitario' => (float) ($detalle['precio_unitario'] ?? 0),
                'subtotal' => (float) ($detalle['subtotal'] ?? 0),
            ]);
        }
    }

    private function calculateDetallesTotal(array $detalles): float
    {
        return collect($detalles)->sum(function ($detalle) {
            return (float) ($detalle['subtotal'] ?? 0);
        });
    }

    private function buildDescripcionResumen(array $detalles, string $fallback): string
    {
        $descripciones = collect($detalles)
            ->map(fn ($detalle) => trim((string) ($detalle['descripcion'] ?? '')))
            ->filter()
            ->take(3)
            ->values();

        if ($descripciones->isEmpty()) {
            return $fallback;
        }

        $resumen = $descripciones->implode(' | ');

        if (count($detalles) > $descripciones->count()) {
            $resumen .= ' | ...';
        }

        return $resumen;
    }

    private function normalizeAlcanceItems(array $items): array
    {
        return collect($items)
            ->map(fn ($item) => trim((string) $item))
            ->filter()
            ->values()
            ->all();
    }
}
