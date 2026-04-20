<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Cotizacion;
use App\Models\CotizacionDetalle;
use App\Models\Factura;
use App\Models\Producto;
use Carbon\CarbonImmutable;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

class DashboardController extends Controller
{
    public function resumen(): JsonResponse
    {
        $now = CarbonImmutable::now();
        $monthStart = $now->startOfMonth()->toDateString();
        $monthEnd = $now->endOfMonth()->toDateString();

        $cotizacionesBase = Cotizacion::query();
        $facturasBase = Factura::query()->visibleFlow();

        $totalFacturadoMes = (clone $facturasBase)
            ->where('estado', Factura::ESTADO_EMITIDA)
            ->whereBetween('fecha', [$monthStart, $monthEnd])
            ->sum('total');

        $facturacionPorMes = $this->buildFacturacionMensual();

        $topServicios = CotizacionDetalle::query()
            ->select([
                DB::raw("TRIM(COALESCE(NULLIF(descripcion, ''), 'Servicio sin nombre')) as servicio"),
                DB::raw('COUNT(*) as veces'),
                DB::raw('SUM(subtotal) as valor_total'),
            ])
            ->groupBy('servicio')
            ->orderByDesc('veces')
            ->orderByDesc('valor_total')
            ->limit(6)
            ->get()
            ->map(fn ($row) => [
                'servicio' => (string) $row->servicio,
                'veces' => (int) $row->veces,
                'valor_total' => (float) $row->valor_total,
            ])
            ->values()
            ->all();

        $latestCotizaciones = Cotizacion::query()
            ->orderByDesc('created_at')
            ->limit(6)
            ->get(['id', 'codigo', 'cliente_nombre', 'estado', 'total', 'fecha', 'created_at'])
            ->map(fn (Cotizacion $cotizacion) => [
                'id' => $cotizacion->id,
                'codigo' => $cotizacion->codigo,
                'cliente_nombre' => $cotizacion->cliente_nombre,
                'estado' => $cotizacion->estado,
                'total' => (float) $cotizacion->total,
                'fecha' => optional($cotizacion->fecha)->toDateString(),
                'created_at' => optional($cotizacion->created_at)->toDateTimeString(),
            ])
            ->values()
            ->all();

        $latestFacturasEmitidas = Factura::query()
            ->visibleFlow()
            ->where('estado', Factura::ESTADO_EMITIDA)
            ->orderByDesc(DB::raw('COALESCE(emitida_at, created_at)'))
            ->limit(6)
            ->get(['id', 'codigo', 'cliente_nombre', 'total', 'fecha', 'emitida_at'])
            ->map(fn (Factura $factura) => [
                'id' => $factura->id,
                'codigo' => $factura->codigo,
                'cliente_nombre' => $factura->cliente_nombre,
                'total' => (float) $factura->total,
                'fecha' => optional($factura->fecha)->toDateString(),
                'emitida_at' => optional($factura->emitida_at)->toDateTimeString(),
            ])
            ->values()
            ->all();

        $stockThreshold = 5;
        $productosStockBajo = Producto::query()
            ->where('activo', true)
            ->where('stock', '<=', $stockThreshold)
            ->orderBy('stock')
            ->orderBy('nombre')
            ->limit(8)
            ->get(['id', 'codigo', 'nombre', 'stock', 'unidad_medida', 'activo'])
            ->map(fn (Producto $producto) => [
                'id' => $producto->id,
                'codigo' => $producto->codigo,
                'nombre' => $producto->nombre,
                'stock' => (int) $producto->stock,
                'unidad_medida' => $producto->unidad_medida,
                'activo' => (bool) $producto->activo,
            ])
            ->values()
            ->all();

        $productosInactivos = Producto::query()
            ->where('activo', false)
            ->orderByDesc('updated_at')
            ->limit(8)
            ->get(['id', 'codigo', 'nombre', 'stock', 'unidad_medida', 'activo'])
            ->map(fn (Producto $producto) => [
                'id' => $producto->id,
                'codigo' => $producto->codigo,
                'nombre' => $producto->nombre,
                'stock' => (int) $producto->stock,
                'unidad_medida' => $producto->unidad_medida,
                'activo' => (bool) $producto->activo,
            ])
            ->values()
            ->all();

        return response()->json([
            'message' => 'Resumen del dashboard obtenido correctamente.',
            'data' => [
                'kpis' => [
                    'cotizaciones_pendientes' => (clone $cotizacionesBase)->where('estado', Cotizacion::ESTADO_PENDIENTE)->count(),
                    'cotizaciones_vistas' => (clone $cotizacionesBase)->where('estado', Cotizacion::ESTADO_VISTO)->count(),
                    'cotizaciones_realizadas' => (clone $cotizacionesBase)->where('estado', Cotizacion::ESTADO_REALIZADA)->count(),
                    'facturas_borrador' => (clone $facturasBase)->where('estado', Factura::ESTADO_BORRADOR)->count(),
                    'facturas_emitidas' => (clone $facturasBase)->where('estado', Factura::ESTADO_EMITIDA)->count(),
                    'total_facturado_mes' => (float) $totalFacturadoMes,
                    'productos_stock_bajo' => count($productosStockBajo),
                    'productos_inactivos' => Producto::query()->where('activo', false)->count(),
                ],
                'charts' => [
                    'cotizaciones_por_estado' => [
                        ['estado' => Cotizacion::ESTADO_PENDIENTE, 'total' => (clone $cotizacionesBase)->where('estado', Cotizacion::ESTADO_PENDIENTE)->count()],
                        ['estado' => Cotizacion::ESTADO_VISTO, 'total' => (clone $cotizacionesBase)->where('estado', Cotizacion::ESTADO_VISTO)->count()],
                        ['estado' => Cotizacion::ESTADO_REALIZADA, 'total' => (clone $cotizacionesBase)->where('estado', Cotizacion::ESTADO_REALIZADA)->count()],
                        ['estado' => Cotizacion::ESTADO_NULA, 'total' => (clone $cotizacionesBase)->where('estado', Cotizacion::ESTADO_NULA)->count()],
                    ],
                    'facturacion_por_mes' => $facturacionPorMes,
                    'servicios_top_cotizados' => $topServicios,
                ],
                'operativo' => [
                    'ultimas_cotizaciones' => $latestCotizaciones,
                    'ultimas_facturas_emitidas' => $latestFacturasEmitidas,
                    'productos_stock_bajo' => $productosStockBajo,
                    'productos_inactivos' => $productosInactivos,
                ],
                'contexto' => [
                    'stock_bajo_hasta' => $stockThreshold,
                    'periodo_mes_actual' => [
                        'inicio' => $monthStart,
                        'fin' => $monthEnd,
                    ],
                ],
            ],
        ]);
    }

    private function buildFacturacionMensual(): array
    {
        $now = CarbonImmutable::now();
        $start = $now->startOfMonth()->subMonths(5);

        $raw = Factura::query()
            ->visibleFlow()
            ->where('estado', Factura::ESTADO_EMITIDA)
            ->whereDate('fecha', '>=', $start->toDateString())
            ->selectRaw("DATE_FORMAT(fecha, '%Y-%m') as periodo")
            ->selectRaw('SUM(total) as total')
            ->groupBy('periodo')
            ->orderBy('periodo')
            ->get()
            ->mapWithKeys(fn ($row) => [
                (string) $row->periodo => (float) $row->total,
            ]);

        $items = [];
        for ($i = 0; $i < 6; $i++) {
            $period = $start->addMonths($i);
            $periodKey = $period->format('Y-m');
            $items[] = [
                'periodo' => $periodKey,
                'label' => $this->labelMes($period->month).' '.$period->format('Y'),
                'total' => (float) ($raw[$periodKey] ?? 0),
            ];
        }

        return $items;
    }

    private function labelMes(int $month): string
    {
        return match ($month) {
            1 => 'Ene',
            2 => 'Feb',
            3 => 'Mar',
            4 => 'Abr',
            5 => 'May',
            6 => 'Jun',
            7 => 'Jul',
            8 => 'Ago',
            9 => 'Sep',
            10 => 'Oct',
            11 => 'Nov',
            default => 'Dic',
        };
    }
}
