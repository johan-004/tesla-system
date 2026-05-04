<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Cotizacion;
use App\Models\CotizacionDetalle;
use App\Models\Factura;
use App\Models\FacturaItem;
use App\Models\Producto;
use App\Models\Servicio;
use Carbon\CarbonImmutable;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

class DashboardController extends Controller
{
    public function resumen(): JsonResponse
    {
        $now = CarbonImmutable::now();
        $today = $now->startOfDay();
        $monthStart = $now->startOfMonth();
        $monthEnd = $now->endOfMonth();
        $availableYears = $this->buildAvailableYears((int) $now->year);
        $selectedMonth = max(1, min(12, (int) request()->get('mes', $now->month)));
        $requestedYear = (int) request()->get('anio', $now->year);
        $selectedYear = in_array($requestedYear, $availableYears, true) ? $requestedYear : ($availableYears[0] ?? (int) $now->year);
        $selectedMonthStart = CarbonImmutable::create($selectedYear, $selectedMonth, 1)->startOfMonth();
        $selectedMonthEnd = $selectedMonthStart->endOfMonth();
        $selectedYearStart = CarbonImmutable::create($selectedYear, 1, 1)->startOfYear();
        $selectedYearEnd = $selectedYearStart->endOfYear();
        $periodStart = $selectedMonthStart;
        $periodEnd = $selectedMonthEnd;
        $periodLabel = 'Mes seleccionado';
        $previousPeriodStart = $periodStart->subDays($periodEnd->diffInDays($periodStart) + 1);
        $previousPeriodEnd = $periodStart->subDay();
        $previousMonthStart = $monthStart->subMonth()->startOfMonth();
        $previousMonthEnd = $monthStart->subMonth()->endOfMonth();

        $cotizacionesBase = Cotizacion::query();
        $facturasBase = Factura::query()->visibleFlow();

        $totalFacturadoMes = (clone $facturasBase)
            ->where('estado', Factura::ESTADO_EMITIDA)
            ->whereBetween('fecha', [$monthStart->toDateString(), $monthEnd->toDateString()])
            ->sum('total');

        $facturacionPorMes = $this->buildFacturacionMensual($selectedYearStart);
        $cotizadoPorMes = $this->buildCotizadoMensual($now);
        $ventasDiariasMesActual = $this->buildVentasDiariasMesActual($selectedMonthStart, $selectedMonthEnd);

        $topItemsFacturados = FacturaItem::query()
            ->join('facturas', 'facturas.id', '=', 'factura_items.factura_id')
            ->where('facturas.estado', Factura::ESTADO_EMITIDA)
            ->select([
                DB::raw("TRIM(COALESCE(NULLIF(factura_items.descripcion, ''), 'Ítem sin nombre')) as servicio"),
                DB::raw('COUNT(*) as veces'),
                DB::raw('SUM(factura_items.total_linea) as valor_total'),
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

        $productosTotal = Producto::query()->count();
        $serviciosTotal = Servicio::query()->count();
        $cotizacionesMes = (clone $cotizacionesBase)
            ->where('estado', Cotizacion::ESTADO_REALIZADA)
            ->whereBetween('fecha', [$monthStart->toDateString(), $monthEnd->toDateString()])
            ->count();
        $facturasEmitidasMes = (clone $facturasBase)
            ->where('estado', Factura::ESTADO_EMITIDA)
            ->whereBetween('fecha', [$monthStart->toDateString(), $monthEnd->toDateString()])
            ->count();

        $productosPrevMonth = Producto::query()
            ->whereBetween('created_at', [$previousMonthStart->toDateTimeString(), $previousMonthEnd->toDateTimeString()])
            ->count();
        $serviciosPrevMonth = Servicio::query()
            ->whereBetween('created_at', [$previousMonthStart->toDateTimeString(), $previousMonthEnd->toDateTimeString()])
            ->count();
        $cotizacionesPrevMonth = (clone $cotizacionesBase)
            ->where('estado', Cotizacion::ESTADO_REALIZADA)
            ->whereBetween('fecha', [$previousMonthStart->toDateString(), $previousMonthEnd->toDateString()])
            ->count();
        $facturasPrevMonth = (clone $facturasBase)
            ->where('estado', Factura::ESTADO_EMITIDA)
            ->whereBetween('fecha', [$previousMonthStart->toDateString(), $previousMonthEnd->toDateString()])
            ->count();

        $ventasPeriodo = $this->sumFacturasEmitidas($periodStart, $periodEnd);
        $ventasPrevPeriodo = $this->sumFacturasEmitidas($previousPeriodStart, $previousPeriodEnd);
        $facturasPeriodo = $this->countFacturasEmitidas($periodStart, $periodEnd);
        $facturasPrevPeriodo = $this->countFacturasEmitidas($previousPeriodStart, $previousPeriodEnd);
        $cotizacionesPeriodo = $this->countCotizacionesPeriodo($periodStart, $periodEnd);
        $cotizacionesPrevPeriodo = $this->countCotizacionesPeriodo($previousPeriodStart, $previousPeriodEnd);
        $productosVendidosPeriodo = $this->sumItemsByType($periodStart, $periodEnd, 'producto');
        $productosVendidosPrevPeriodo = $this->sumItemsByType($previousPeriodStart, $previousPeriodEnd, 'producto');
        $serviciosFacturadosPeriodo = $this->sumItemsByType($periodStart, $periodEnd, 'servicio');
        $serviciosFacturadosPrevPeriodo = $this->sumItemsByType($previousPeriodStart, $previousPeriodEnd, 'servicio');
        $ventasPorTipo = $this->buildVentasPorTipo($periodStart, $periodEnd);
        $ventasCategoriaProductos = $this->buildVentasCategoriaProductos($periodStart, $periodEnd);
        $topItems = $this->buildTopItemsVendidos($periodStart, $periodEnd);
        $resumenFinanciero = $this->buildResumenFinanciero($periodStart, $periodEnd, $ventasPorTipo);
        $estadoDocumentos = $this->buildEstadoDocumentos($periodStart, $periodEnd, $stockThreshold);
        $ventasDiariasPeriodo = $this->buildVentasDiariasMesActual($periodStart, $periodEnd);
        $ventasAnuales = $this->buildFacturacionMensual($selectedYearStart);

        return response()->json([
            'message' => 'Resumen del dashboard obtenido correctamente.',
            'data' => [
                'kpis' => [
                    'cotizaciones_pendientes' => (clone $cotizacionesBase)->where('estado', Cotizacion::ESTADO_PENDIENTE)->count(),
                    'cotizaciones_vistas' => (clone $cotizacionesBase)->where('estado', Cotizacion::ESTADO_VISTO)->count(),
                    'cotizaciones_realizadas' => (clone $cotizacionesBase)->where('estado', Cotizacion::ESTADO_REALIZADA)->count(),
                    'facturas_pendientes' => (clone $facturasBase)->pendiente()->count(),
                    'facturas_borrador' => (clone $facturasBase)->pendiente()->count(),
                    'facturas_emitidas' => (clone $facturasBase)->where('estado', Factura::ESTADO_EMITIDA)->count(),
                    'facturas_anuladas' => (clone $facturasBase)->where('estado', Factura::ESTADO_ANULADA)->count(),
                    'total_facturado_mes' => (float) $totalFacturadoMes,
                    'productos_stock_bajo' => count($productosStockBajo),
                    'productos_inactivos' => Producto::query()->where('activo', false)->count(),
                    'productos_total' => $productosTotal,
                    'servicios_total' => $serviciosTotal,
                    'cotizaciones_mes' => $cotizacionesMes,
                    'facturas_emitidas_mes' => $facturasEmitidasMes,
                    'productos_variacion_pct' => $this->variationPercent($productosTotal, $productosPrevMonth),
                    'servicios_variacion_pct' => $this->variationPercent($serviciosTotal, $serviciosPrevMonth),
                    'cotizaciones_variacion_pct' => $this->variationPercent($cotizacionesMes, $cotizacionesPrevMonth),
                    'facturas_variacion_pct' => $this->variationPercent($facturasEmitidasMes, $facturasPrevMonth),
                ],
                'charts' => [
                    'cotizaciones_por_estado' => [
                        ['estado' => Cotizacion::ESTADO_PENDIENTE, 'total' => (clone $cotizacionesBase)->where('estado', Cotizacion::ESTADO_PENDIENTE)->count()],
                        ['estado' => Cotizacion::ESTADO_VISTO, 'total' => (clone $cotizacionesBase)->where('estado', Cotizacion::ESTADO_VISTO)->count()],
                        ['estado' => Cotizacion::ESTADO_REALIZADA, 'total' => (clone $cotizacionesBase)->where('estado', Cotizacion::ESTADO_REALIZADA)->count()],
                        ['estado' => Cotizacion::ESTADO_NULA, 'total' => (clone $cotizacionesBase)->where('estado', Cotizacion::ESTADO_NULA)->count()],
                    ],
                    'facturas_por_estado' => [
                        ['estado' => Factura::ESTADO_PENDIENTE, 'total' => (clone $facturasBase)->pendiente()->count()],
                        ['estado' => Factura::ESTADO_EMITIDA, 'total' => (clone $facturasBase)->where('estado', Factura::ESTADO_EMITIDA)->count()],
                        ['estado' => Factura::ESTADO_ANULADA, 'total' => (clone $facturasBase)->where('estado', Factura::ESTADO_ANULADA)->count()],
                    ],
                    'facturacion_por_mes' => $facturacionPorMes,
                    'cotizado_por_mes' => $cotizadoPorMes,
                    'resumen_ventas_diario_mes' => $ventasDiariasMesActual,
                    'ventas_diarias_mes' => $ventasDiariasMesActual,
                    'ventas_mensuales_anio' => $facturacionPorMes,
                    'servicios_top_cotizados' => $topItemsFacturados,
                    'items_top_facturados' => $topItemsFacturados,
                    'modulos' => [
                        'productos' => [
                            'top_mes' => $this->buildProductosTopRegistrados($monthStart, $monthEnd),
                            'top_anio' => $this->buildProductosTopRegistrados($now->startOfYear(), $now->endOfYear()),
                        ],
                        'servicios' => [
                            'top_mes' => $this->buildServiciosTopFacturados($monthStart, $monthEnd),
                            'top_anio' => $this->buildServiciosTopFacturados($now->startOfYear(), $now->endOfYear()),
                            'serie_mensual' => $this->buildServiciosSerieMensual($now),
                            'serie_anual' => $this->buildServiciosSerieAnual($selectedYear),
                        ],
                        'cotizaciones' => [
                            'serie_semana' => $this->buildCotizacionesSerieSemana($now),
                            'serie_mes' => $this->buildCotizacionesSerieMes($now),
                        ],
                        'facturas' => $this->buildFacturasDetalle($selectedYearStart, $selectedYearEnd, $selectedMonthStart, $selectedMonthEnd, $now),
                    ],
                ],
                'operativo' => [
                    'ultimas_cotizaciones' => $latestCotizaciones,
                    'ultimas_facturas_emitidas' => $latestFacturasEmitidas,
                    'productos_stock_bajo' => $productosStockBajo,
                    'productos_inactivos' => $productosInactivos,
                ],
                'contexto' => [
                    'stock_bajo_hasta' => $stockThreshold,
                    'filtro_dashboard' => [
                        'mes' => $selectedMonth,
                        'anio' => $selectedYear,
                    ],
                    'anios_disponibles' => $availableYears,
                    'periodo_mes_actual' => [
                        'inicio' => $selectedMonthStart->toDateString(),
                        'fin' => $selectedMonthEnd->toDateString(),
                    ],
                ],
                'business_dashboard' => [
                    'periodo' => [
                        'label' => $periodLabel,
                        'inicio' => $periodStart->toDateString(),
                        'fin' => $periodEnd->toDateString(),
                        'inicio_anterior' => $previousPeriodStart->toDateString(),
                        'fin_anterior' => $previousPeriodEnd->toDateString(),
                    ],
                    'kpis' => [
                        'ventas_facturas' => [
                            'valor' => $ventasPeriodo,
                            'variacion_pct' => $this->variationPercent($ventasPeriodo, $ventasPrevPeriodo),
                        ],
                        'facturas_emitidas' => [
                            'valor' => $facturasPeriodo,
                            'variacion_pct' => $this->variationPercent($facturasPeriodo, $facturasPrevPeriodo),
                        ],
                        'cotizaciones_enviadas' => [
                            'valor' => $cotizacionesPeriodo,
                            'variacion_pct' => $this->variationPercent($cotizacionesPeriodo, $cotizacionesPrevPeriodo),
                        ],
                        'productos_vendidos' => [
                            'valor' => $productosVendidosPeriodo,
                            'variacion_pct' => $this->variationPercent($productosVendidosPeriodo, $productosVendidosPrevPeriodo),
                        ],
                        'servicios_facturados' => [
                            'valor' => $serviciosFacturadosPeriodo,
                            'variacion_pct' => $this->variationPercent($serviciosFacturadosPeriodo, $serviciosFacturadosPrevPeriodo),
                        ],
                    ],
                    'graficas' => [
                        'ventas_diarias_periodo' => $ventasDiariasPeriodo,
                        'ventas_mensuales_anio' => $ventasAnuales,
                        'ventas_por_categoria_productos' => $ventasCategoriaProductos,
                        'ventas_por_tipo' => $ventasPorTipo,
                    ],
                    'top_items_vendidos' => $topItems,
                    'estado_documentos' => $estadoDocumentos,
                    'resumen_financiero' => $resumenFinanciero,
                ],
            ],
        ]);
    }

    private function buildAvailableYears(int $fallbackYear): array
    {
        $facturaYears = Factura::query()
            ->selectRaw('DISTINCT YEAR(fecha) as anio')
            ->whereNotNull('fecha')
            ->pluck('anio')
            ->filter()
            ->map(fn ($year) => (int) $year)
            ->all();

        $cotizacionYears = Cotizacion::query()
            ->selectRaw('DISTINCT YEAR(fecha) as anio')
            ->whereNotNull('fecha')
            ->pluck('anio')
            ->filter()
            ->map(fn ($year) => (int) $year)
            ->all();

        $years = array_values(array_unique(array_merge($facturaYears, $cotizacionYears)));
        rsort($years);

        if ($years === []) {
            return [$fallbackYear];
        }

        return $years;
    }

    private function sumFacturasEmitidas(CarbonImmutable $start, CarbonImmutable $end): float
    {
        return (float) Factura::query()
            ->visibleFlow()
            ->where('estado', Factura::ESTADO_EMITIDA)
            ->whereBetween('fecha', [$start->toDateString(), $end->toDateString()])
            ->sum('total');
    }

    private function countFacturasEmitidas(CarbonImmutable $start, CarbonImmutable $end): int
    {
        return (int) Factura::query()
            ->visibleFlow()
            ->where('estado', Factura::ESTADO_EMITIDA)
            ->whereBetween('fecha', [$start->toDateString(), $end->toDateString()])
            ->count();
    }

    private function countCotizacionesPeriodo(CarbonImmutable $start, CarbonImmutable $end): int
    {
        return (int) Cotizacion::query()
            ->whereBetween('fecha', [$start->toDateString(), $end->toDateString()])
            ->count();
    }

    private function sumItemsByType(CarbonImmutable $start, CarbonImmutable $end, string $type): float
    {
        return (float) FacturaItem::query()
            ->join('facturas', 'facturas.id', '=', 'factura_items.factura_id')
            ->where('facturas.estado', Factura::ESTADO_EMITIDA)
            ->whereBetween('facturas.fecha', [$start->toDateString(), $end->toDateString()])
            ->where('factura_items.tipo_item', $type)
            ->sum('factura_items.cantidad');
    }

    private function buildVentasPorTipo(CarbonImmutable $start, CarbonImmutable $end): array
    {
        $raw = FacturaItem::query()
            ->join('facturas', 'facturas.id', '=', 'factura_items.factura_id')
            ->where('facturas.estado', Factura::ESTADO_EMITIDA)
            ->whereBetween('facturas.fecha', [$start->toDateString(), $end->toDateString()])
            ->selectRaw("COALESCE(NULLIF(factura_items.tipo_item, ''), 'servicio') as tipo")
            ->selectRaw('SUM(factura_items.total_linea) as total')
            ->groupBy('tipo')
            ->pluck('total', 'tipo');

        $productos = (float) ($raw['producto'] ?? 0);
        $servicios = (float) ($raw['servicio'] ?? 0);
        $total = $productos + $servicios;

        return [
            'total' => $total,
            'items' => [
                ['tipo' => 'producto', 'label' => 'Productos', 'valor' => $productos, 'porcentaje' => $total > 0 ? round(($productos / $total) * 100, 1) : 0],
                ['tipo' => 'servicio', 'label' => 'Servicios', 'valor' => $servicios, 'porcentaje' => $total > 0 ? round(($servicios / $total) * 100, 1) : 0],
            ],
        ];
    }

    private function buildVentasCategoriaProductos(CarbonImmutable $start, CarbonImmutable $end): array
    {
        $raw = FacturaItem::query()
            ->join('facturas', 'facturas.id', '=', 'factura_items.factura_id')
            ->leftJoin('productos', 'productos.id', '=', 'factura_items.producto_id')
            ->leftJoin('producto_categorias', 'producto_categorias.id', '=', 'productos.categoria_id')
            ->where('facturas.estado', Factura::ESTADO_EMITIDA)
            ->whereBetween('facturas.fecha', [$start->toDateString(), $end->toDateString()])
            ->where('factura_items.tipo_item', 'producto')
            ->selectRaw("TRIM(COALESCE(NULLIF(producto_categorias.nombre, ''), 'Sin categoría')) as categoria")
            ->selectRaw('SUM(factura_items.total_linea) as total')
            ->groupBy('categoria')
            ->get()
            ->map(fn ($row) => [
                'categoria' => (string) $row->categoria,
                'valor' => (float) $row->total,
            ])
            ->values()
            ->all();

        $total = array_sum(array_map(fn ($item) => (float) $item['valor'], $raw));
        $items = array_map(function ($item) use ($total) {
            $value = (float) $item['valor'];

            return [
                ...$item,
                'porcentaje' => $total > 0 ? round(($value / $total) * 100, 1) : 0,
            ];
        }, $raw);

        return [
            'total' => (float) $total,
            'items' => $items,
        ];
    }

    private function buildTopItemsVendidos(CarbonImmutable $start, CarbonImmutable $end): array
    {
        return FacturaItem::query()
            ->join('facturas', 'facturas.id', '=', 'factura_items.factura_id')
            ->leftJoin('productos', 'productos.id', '=', 'factura_items.producto_id')
            ->leftJoin('servicios', 'servicios.id', '=', 'factura_items.servicio_id')
            ->where('facturas.estado', Factura::ESTADO_EMITIDA)
            ->whereBetween('facturas.fecha', [$start->toDateString(), $end->toDateString()])
            ->selectRaw("
                TRIM(
                    COALESCE(
                        NULLIF(factura_items.descripcion, ''),
                        NULLIF(productos.nombre, ''),
                        NULLIF(servicios.descripcion, ''),
                        'Ítem sin nombre'
                    )
                ) as item
            ")
            ->selectRaw("TRIM(COALESCE(NULLIF(factura_items.unidad, ''), 'uds')) as unidad")
            ->selectRaw('SUM(factura_items.cantidad) as cantidad_total')
            ->selectRaw('SUM(factura_items.total_linea) as valor_total')
            ->groupBy('item', 'unidad')
            ->orderByDesc('valor_total')
            ->limit(5)
            ->get()
            ->map(fn ($row) => [
                'descripcion' => (string) $row->item,
                'unidad' => (string) $row->unidad,
                'cantidad' => (float) $row->cantidad_total,
                'valor_total' => (float) $row->valor_total,
            ])
            ->values()
            ->all();
    }

    private function buildEstadoDocumentos(CarbonImmutable $start, CarbonImmutable $end, int $stockThreshold): array
    {
        return [
            'cotizaciones' => [
                'total' => (int) Cotizacion::query()->whereBetween('fecha', [$start->toDateString(), $end->toDateString()])->count(),
                'pendientes' => (int) Cotizacion::query()->whereBetween('fecha', [$start->toDateString(), $end->toDateString()])->where('estado', Cotizacion::ESTADO_PENDIENTE)->count(),
                'vistas' => (int) Cotizacion::query()->whereBetween('fecha', [$start->toDateString(), $end->toDateString()])->where('estado', Cotizacion::ESTADO_VISTO)->count(),
                'realizadas' => (int) Cotizacion::query()->whereBetween('fecha', [$start->toDateString(), $end->toDateString()])->where('estado', Cotizacion::ESTADO_REALIZADA)->count(),
                'nulas' => (int) Cotizacion::query()->whereBetween('fecha', [$start->toDateString(), $end->toDateString()])->where('estado', Cotizacion::ESTADO_NULA)->count(),
            ],
            'facturas' => [
                'total' => (int) Factura::query()->visibleFlow()->whereBetween('fecha', [$start->toDateString(), $end->toDateString()])->count(),
                'pendientes' => (int) Factura::query()->visibleFlow()->whereBetween('fecha', [$start->toDateString(), $end->toDateString()])->pendiente()->count(),
                'emitidas' => (int) Factura::query()->visibleFlow()->whereBetween('fecha', [$start->toDateString(), $end->toDateString()])->where('estado', Factura::ESTADO_EMITIDA)->count(),
                'anuladas' => (int) Factura::query()->visibleFlow()->whereBetween('fecha', [$start->toDateString(), $end->toDateString()])->where('estado', Factura::ESTADO_ANULADA)->count(),
            ],
            'productos' => [
                'total' => (int) Producto::query()->count(),
                'con_stock' => (int) Producto::query()->where('stock', '>', 0)->count(),
                'sin_stock' => (int) Producto::query()->where('stock', '=', 0)->count(),
                'stock_bajo' => (int) Producto::query()->where('stock', '<=', $stockThreshold)->count(),
            ],
        ];
    }

    private function buildResumenFinanciero(CarbonImmutable $start, CarbonImmutable $end, array $ventasPorTipo): array
    {
        $ventas = $this->sumFacturasEmitidas($start, $end);

        $costosProductos = (float) FacturaItem::query()
            ->join('facturas', 'facturas.id', '=', 'factura_items.factura_id')
            ->join('productos', 'productos.id', '=', 'factura_items.producto_id')
            ->where('facturas.estado', Factura::ESTADO_EMITIDA)
            ->whereBetween('facturas.fecha', [$start->toDateString(), $end->toDateString()])
            ->where('factura_items.tipo_item', 'producto')
            ->selectRaw('SUM(COALESCE(productos.precio_compra, 0) * factura_items.cantidad) as costo_total')
            ->value('costo_total') ?? 0.0;

        // Mientras no exista módulo de gastos, usamos 0 para mantener el resumen calculable.
        $gastos = 0.0;
        $utilidad = $ventas - $costosProductos - $gastos;
        $margen = $ventas > 0 ? round(($utilidad / $ventas) * 100, 1) : 0.0;

        return [
            'ventas_facturas' => $ventas,
            'costos_productos_vendidos' => $costosProductos,
            'gastos_operativos' => $gastos,
            'utilidad_estimada' => $utilidad,
            'margen_utilidad_pct' => $margen,
            'ventas_por_tipo_total' => (float) ($ventasPorTipo['total'] ?? 0),
            'calculable' => true,
        ];
    }

    private function buildFacturacionMensual(CarbonImmutable $startOfYear): array
    {
        $start = $startOfYear->startOfYear();
        $end = $startOfYear->endOfYear();

        $raw = Factura::query()
            ->visibleFlow()
            ->where('estado', Factura::ESTADO_EMITIDA)
            ->whereBetween('fecha', [$start->toDateString(), $end->toDateString()])
            ->selectRaw("DATE_FORMAT(fecha, '%Y-%m') as periodo")
            ->selectRaw('SUM(total) as total')
            ->groupBy('periodo')
            ->orderBy('periodo')
            ->get()
            ->mapWithKeys(fn ($row) => [
                (string) $row->periodo => (float) $row->total,
            ]);

        $items = [];
        for ($i = 0; $i < 12; $i++) {
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

    private function buildCotizadoMensual(CarbonImmutable $now): array
    {
        $start = $now->startOfYear();
        $end = $now->endOfYear();

        $raw = Cotizacion::query()
            ->where('estado', Cotizacion::ESTADO_REALIZADA)
            ->whereBetween('fecha', [$start->toDateString(), $end->toDateString()])
            ->selectRaw("DATE_FORMAT(fecha, '%Y-%m') as periodo")
            ->selectRaw('SUM(total) as total')
            ->groupBy('periodo')
            ->orderBy('periodo')
            ->get()
            ->mapWithKeys(fn ($row) => [
                (string) $row->periodo => (float) $row->total,
            ]);

        $items = [];
        for ($i = 0; $i < 12; $i++) {
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

    private function buildVentasDiariasMesActual(CarbonImmutable $start, CarbonImmutable $end): array
    {
        $facturadoRaw = Factura::query()
            ->visibleFlow()
            ->where('estado', Factura::ESTADO_EMITIDA)
            ->whereBetween('fecha', [$start->toDateString(), $end->toDateString()])
            ->selectRaw('DATE(fecha) as dia')
            ->selectRaw('SUM(total) as total')
            ->groupBy('dia')
            ->pluck('total', 'dia');

        $items = [];
        $cursor = $start;
        while ($cursor->lessThanOrEqualTo($end)) {
            $key = $cursor->toDateString();
            $items[] = [
                'fecha' => $key,
                'label' => sprintf('%02d %s', $cursor->day, $this->labelMes($cursor->month)),
                'facturado' => (float) ($facturadoRaw[$key] ?? 0),
                'cotizado' => 0.0,
            ];
            $cursor = $cursor->addDay();
        }

        return $items;
    }

    private function buildProductosTopRegistrados(CarbonImmutable $start, CarbonImmutable $end): array
    {
        return Producto::query()
            ->whereBetween('created_at', [$start->toDateTimeString(), $end->toDateTimeString()])
            ->selectRaw("TRIM(COALESCE(NULLIF(nombre, ''), CONCAT('Producto #', id))) as etiqueta")
            ->selectRaw('COUNT(*) as total')
            ->groupBy('etiqueta')
            ->orderByDesc('total')
            ->orderBy('etiqueta')
            ->limit(8)
            ->get()
            ->map(fn ($row) => [
                'label' => (string) $row->etiqueta,
                'total' => (float) $row->total,
            ])
            ->values()
            ->all();
    }

    private function buildServiciosTopFacturados(CarbonImmutable $start, CarbonImmutable $end): array
    {
        return FacturaItem::query()
            ->join('facturas', 'facturas.id', '=', 'factura_items.factura_id')
            ->where('facturas.estado', Factura::ESTADO_EMITIDA)
            ->whereBetween('facturas.fecha', [$start->toDateString(), $end->toDateString()])
            ->selectRaw("TRIM(COALESCE(NULLIF(factura_items.descripcion, ''), 'Servicio sin nombre')) as etiqueta")
            ->selectRaw('SUM(factura_items.cantidad) as total')
            ->groupBy('etiqueta')
            ->orderByDesc('total')
            ->orderBy('etiqueta')
            ->limit(8)
            ->get()
            ->map(fn ($row) => [
                'label' => (string) $row->etiqueta,
                'total' => (float) $row->total,
            ])
            ->values()
            ->all();
    }

    private function buildServiciosSerieMensual(CarbonImmutable $now): array
    {
        $start = $now->startOfMonth()->subMonths(5);
        $raw = FacturaItem::query()
            ->join('facturas', 'facturas.id', '=', 'factura_items.factura_id')
            ->where('facturas.estado', Factura::ESTADO_EMITIDA)
            ->whereDate('facturas.fecha', '>=', $start->toDateString())
            ->selectRaw("DATE_FORMAT(facturas.fecha, '%Y-%m') as periodo")
            ->selectRaw('SUM(factura_items.cantidad) as total')
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
                'label' => $this->labelMes($period->month),
                'total' => (float) ($raw[$periodKey] ?? 0),
            ];
        }

        return $items;
    }

    private function buildServiciosSerieAnual(int $year): array
    {
        $raw = FacturaItem::query()
            ->join('facturas', 'facturas.id', '=', 'factura_items.factura_id')
            ->where('facturas.estado', Factura::ESTADO_EMITIDA)
            ->whereYear('facturas.fecha', $year)
            ->selectRaw("DATE_FORMAT(facturas.fecha, '%Y-%m') as periodo")
            ->selectRaw('SUM(factura_items.cantidad) as total')
            ->groupBy('periodo')
            ->orderBy('periodo')
            ->get()
            ->mapWithKeys(fn ($row) => [
                (string) $row->periodo => (float) $row->total,
            ]);

        $items = [];
        for ($month = 1; $month <= 12; $month++) {
            $period = CarbonImmutable::create($year, $month, 1);
            $key = $period->format('Y-m');
            $items[] = [
                'label' => $this->labelMes($month),
                'total' => (float) ($raw[$key] ?? 0),
            ];
        }

        return $items;
    }

    private function buildCotizacionesSerieSemana(CarbonImmutable $now): array
    {
        $start = $now->startOfWeek();
        $end = $now->endOfWeek();
        $raw = Cotizacion::query()
            ->where('estado', Cotizacion::ESTADO_REALIZADA)
            ->whereBetween('fecha', [$start->toDateString(), $end->toDateString()])
            ->selectRaw('DATE(fecha) as dia')
            ->selectRaw('COUNT(*) as total')
            ->groupBy('dia')
            ->pluck('total', 'dia');

        $items = [];
        $cursor = $start;
        while ($cursor->lessThanOrEqualTo($end)) {
            $key = $cursor->toDateString();
            $items[] = [
                'label' => $cursor->translatedFormat('D'),
                'total' => (float) ($raw[$key] ?? 0),
            ];
            $cursor = $cursor->addDay();
        }

        return $items;
    }

    private function buildCotizacionesSerieMes(CarbonImmutable $now): array
    {
        $start = $now->startOfMonth();
        $end = $now->startOfDay();
        $raw = Cotizacion::query()
            ->where('estado', Cotizacion::ESTADO_REALIZADA)
            ->whereBetween('fecha', [$start->toDateString(), $end->toDateString()])
            ->selectRaw('DATE(fecha) as dia')
            ->selectRaw('COUNT(*) as total')
            ->groupBy('dia')
            ->pluck('total', 'dia');

        $items = [];
        $cursor = $start;
        while ($cursor->lessThanOrEqualTo($end)) {
            $key = $cursor->toDateString();
            $items[] = [
                'label' => sprintf('%02d', $cursor->day),
                'total' => (float) ($raw[$key] ?? 0),
            ];
            $cursor = $cursor->addDay();
        }

        return $items;
    }

    private function buildFacturasDetalle(
        CarbonImmutable $yearStart,
        CarbonImmutable $yearEnd,
        CarbonImmutable $monthStart,
        CarbonImmutable $monthEnd,
        CarbonImmutable $now
    ): array
    {
        $weekStart = $now->startOfWeek();
        $weekEnd = $now->endOfWeek();

        return [
            'serie_semana' => $this->buildFacturasSerieDiaria($weekStart, $weekEnd),
            'serie_mes' => $this->buildFacturasSerieDiaria($monthStart, $monthEnd),
            'serie_anio' => $this->buildFacturasSerieMensualAnual((int) $yearStart->year),
            'totales' => [
                'semana' => (float) Factura::query()
                    ->visibleFlow()
                    ->where('estado', Factura::ESTADO_EMITIDA)
                    ->whereBetween('fecha', [$weekStart->toDateString(), $weekEnd->toDateString()])
                    ->sum('total'),
                'mes' => (float) Factura::query()
                    ->visibleFlow()
                    ->where('estado', Factura::ESTADO_EMITIDA)
                    ->whereBetween('fecha', [$monthStart->toDateString(), $monthEnd->toDateString()])
                    ->sum('total'),
                'anio' => (float) Factura::query()
                    ->visibleFlow()
                    ->where('estado', Factura::ESTADO_EMITIDA)
                    ->whereBetween('fecha', [$yearStart->toDateString(), $yearEnd->toDateString()])
                    ->sum('total'),
            ],
        ];
    }

    private function buildFacturasSerieDiaria(CarbonImmutable $start, CarbonImmutable $end): array
    {
        $raw = Factura::query()
            ->visibleFlow()
            ->where('estado', Factura::ESTADO_EMITIDA)
            ->whereBetween('fecha', [$start->toDateString(), $end->toDateString()])
            ->selectRaw('DATE(fecha) as dia')
            ->selectRaw('COUNT(*) as cantidad')
            ->selectRaw('SUM(total) as total_valor')
            ->groupBy('dia')
            ->get()
            ->mapWithKeys(fn ($row) => [
                (string) $row->dia => [
                    'cantidad' => (float) $row->cantidad,
                    'total_valor' => (float) $row->total_valor,
                ],
            ]);

        $items = [];
        $cursor = $start;
        while ($cursor->lessThanOrEqualTo($end)) {
            $key = $cursor->toDateString();
            $data = $raw[$key] ?? ['cantidad' => 0.0, 'total_valor' => 0.0];
            $items[] = [
                'label' => sprintf('%02d', $cursor->day),
                'cantidad' => (float) $data['cantidad'],
                'total' => (float) $data['total_valor'],
            ];
            $cursor = $cursor->addDay();
        }

        return $items;
    }

    private function buildFacturasSerieMensualAnual(int $year): array
    {
        $raw = Factura::query()
            ->visibleFlow()
            ->where('estado', Factura::ESTADO_EMITIDA)
            ->whereYear('fecha', $year)
            ->selectRaw("DATE_FORMAT(fecha, '%Y-%m') as periodo")
            ->selectRaw('COUNT(*) as cantidad')
            ->selectRaw('SUM(total) as total_valor')
            ->groupBy('periodo')
            ->orderBy('periodo')
            ->get()
            ->mapWithKeys(fn ($row) => [
                (string) $row->periodo => [
                    'cantidad' => (float) $row->cantidad,
                    'total_valor' => (float) $row->total_valor,
                ],
            ]);

        $items = [];
        for ($month = 1; $month <= 12; $month++) {
            $period = CarbonImmutable::create($year, $month, 1);
            $key = $period->format('Y-m');
            $data = $raw[$key] ?? ['cantidad' => 0.0, 'total_valor' => 0.0];
            $items[] = [
                'label' => $this->labelMes($month),
                'cantidad' => (float) $data['cantidad'],
                'total' => (float) $data['total_valor'],
            ];
        }

        return $items;
    }

    private function variationPercent(int|float $current, int|float $previous): float
    {
        if ($previous <= 0 && $current <= 0) {
            return 0.0;
        }

        if ($previous <= 0) {
            return 100.0;
        }

        return round((($current - $previous) / $previous) * 100, 1);
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
