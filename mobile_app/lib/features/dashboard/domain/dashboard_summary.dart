class DashboardSummary {
  DashboardSummary({
    required this.businessDashboard,
    required this.kpis,
    required this.cotizacionesPorEstado,
    required this.facturasPorEstado,
    required this.facturacionPorMes,
    required this.cotizadoPorMes,
    required this.resumenVentasDiarioMes,
    required this.serviciosTopCotizados,
    required this.modulos,
    required this.ultimasCotizaciones,
    required this.ultimasFacturasEmitidas,
    required this.productosStockBajo,
    required this.productosInactivos,
    required this.stockBajoHasta,
    required this.periodoMesInicio,
    required this.periodoMesFin,
    required this.aniosDisponibles,
  });

  final BusinessDashboard businessDashboard;
  final DashboardKpis kpis;
  final List<EstadoTotal> cotizacionesPorEstado;
  final List<EstadoTotal> facturasPorEstado;
  final List<PeriodoTotal> facturacionPorMes;
  final List<PeriodoTotal> cotizadoPorMes;
  final List<VentaDiaria> resumenVentasDiarioMes;
  final List<ServicioTop> serviciosTopCotizados;
  final DashboardModulos modulos;
  final List<DashboardCotizacionItem> ultimasCotizaciones;
  final List<DashboardFacturaItem> ultimasFacturasEmitidas;
  final List<DashboardProductoItem> productosStockBajo;
  final List<DashboardProductoItem> productosInactivos;
  final int stockBajoHasta;
  final String? periodoMesInicio;
  final String? periodoMesFin;
  final List<int> aniosDisponibles;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? const {};
    final kpisJson = data['kpis'] as Map<String, dynamic>? ?? const {};
    final charts = data['charts'] as Map<String, dynamic>? ?? const {};
    final operativo = data['operativo'] as Map<String, dynamic>? ?? const {};
    final contexto = data['contexto'] as Map<String, dynamic>? ?? const {};
    final businessDashboardJson =
        data['business_dashboard'] as Map<String, dynamic>? ?? const {};
    final periodoMesActual =
        contexto['periodo_mes_actual'] as Map<String, dynamic>? ?? const {};
    final modulosJson = charts['modulos'] as Map<String, dynamic>? ?? const {};

    return DashboardSummary(
      businessDashboard: BusinessDashboard.fromJson(businessDashboardJson),
      kpis: DashboardKpis.fromJson(kpisJson),
      cotizacionesPorEstado:
          (charts['cotizaciones_por_estado'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(EstadoTotal.fromJson)
              .toList(),
      facturasPorEstado:
          (charts['facturas_por_estado'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(EstadoTotal.fromJson)
              .toList(),
      facturacionPorMes:
          (charts['facturacion_por_mes'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(PeriodoTotal.fromJson)
              .toList(),
      cotizadoPorMes: (charts['cotizado_por_mes'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(PeriodoTotal.fromJson)
          .toList(),
      resumenVentasDiarioMes:
          (charts['resumen_ventas_diario_mes'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(VentaDiaria.fromJson)
              .toList(),
      serviciosTopCotizados:
          (charts['servicios_top_cotizados'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(ServicioTop.fromJson)
              .toList(),
      modulos: DashboardModulos.fromJson(modulosJson),
      ultimasCotizaciones:
          (operativo['ultimas_cotizaciones'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(DashboardCotizacionItem.fromJson)
              .toList(),
      ultimasFacturasEmitidas:
          (operativo['ultimas_facturas_emitidas'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(DashboardFacturaItem.fromJson)
              .toList(),
      productosStockBajo:
          (operativo['productos_stock_bajo'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(DashboardProductoItem.fromJson)
              .toList(),
      productosInactivos:
          (operativo['productos_inactivos'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(DashboardProductoItem.fromJson)
              .toList(),
      stockBajoHasta: _parseInt(contexto['stock_bajo_hasta'], fallback: 5),
      periodoMesInicio: periodoMesActual['inicio']?.toString(),
      periodoMesFin: periodoMesActual['fin']?.toString(),
      aniosDisponibles:
          (contexto['anios_disponibles'] as List<dynamic>? ?? const [])
              .map((item) => _parseInt(item))
              .where((item) => item > 0)
              .toList(),
    );
  }
}

class DashboardKpis {
  const DashboardKpis({
    required this.cotizacionesPendientes,
    required this.cotizacionesVistas,
    required this.cotizacionesRealizadas,
    required this.facturasPendientes,
    required this.facturasEmitidas,
    required this.facturasAnuladas,
    required this.totalFacturadoMes,
    required this.productosStockBajo,
    required this.productosInactivos,
    required this.productosTotal,
    required this.serviciosTotal,
    required this.cotizacionesMes,
    required this.facturasEmitidasMes,
    required this.productosVariacionPct,
    required this.serviciosVariacionPct,
    required this.cotizacionesVariacionPct,
    required this.facturasVariacionPct,
  });

  final int cotizacionesPendientes;
  final int cotizacionesVistas;
  final int cotizacionesRealizadas;
  final int facturasPendientes;
  final int facturasEmitidas;
  final int facturasAnuladas;
  final double totalFacturadoMes;
  final int productosStockBajo;
  final int productosInactivos;
  final int productosTotal;
  final int serviciosTotal;
  final int cotizacionesMes;
  final int facturasEmitidasMes;
  final double productosVariacionPct;
  final double serviciosVariacionPct;
  final double cotizacionesVariacionPct;
  final double facturasVariacionPct;
  int get facturasBorrador => facturasPendientes;

  factory DashboardKpis.fromJson(Map<String, dynamic> json) {
    return DashboardKpis(
      cotizacionesPendientes: _parseInt(json['cotizaciones_pendientes']),
      cotizacionesVistas: _parseInt(json['cotizaciones_vistas']),
      cotizacionesRealizadas: _parseInt(json['cotizaciones_realizadas']),
      facturasPendientes:
          _parseInt(json['facturas_pendientes'] ?? json['facturas_borrador']),
      facturasEmitidas: _parseInt(json['facturas_emitidas']),
      facturasAnuladas: _parseInt(json['facturas_anuladas']),
      totalFacturadoMes: _parseDouble(json['total_facturado_mes']),
      productosStockBajo: _parseInt(json['productos_stock_bajo']),
      productosInactivos: _parseInt(json['productos_inactivos']),
      productosTotal:
          _parseInt(json['productos_total'] ?? json['productos_stock_bajo']),
      serviciosTotal: _parseInt(json['servicios_total']),
      cotizacionesMes: _parseInt(
          json['cotizaciones_mes'] ?? json['cotizaciones_realizadas']),
      facturasEmitidasMes:
          _parseInt(json['facturas_emitidas_mes'] ?? json['facturas_emitidas']),
      productosVariacionPct: _parseDouble(json['productos_variacion_pct']),
      serviciosVariacionPct: _parseDouble(json['servicios_variacion_pct']),
      cotizacionesVariacionPct:
          _parseDouble(json['cotizaciones_variacion_pct']),
      facturasVariacionPct: _parseDouble(json['facturas_variacion_pct']),
    );
  }
}

class DashboardModulos {
  const DashboardModulos({
    required this.productos,
    required this.servicios,
    required this.cotizaciones,
    required this.facturas,
  });

  final DashboardModuloProductos productos;
  final DashboardModuloServicios servicios;
  final DashboardModuloCotizaciones cotizaciones;
  final DashboardModuloFacturas facturas;

  factory DashboardModulos.fromJson(Map<String, dynamic> json) {
    return DashboardModulos(
      productos: DashboardModuloProductos.fromJson(
        json['productos'] as Map<String, dynamic>? ?? const {},
      ),
      servicios: DashboardModuloServicios.fromJson(
        json['servicios'] as Map<String, dynamic>? ?? const {},
      ),
      cotizaciones: DashboardModuloCotizaciones.fromJson(
        json['cotizaciones'] as Map<String, dynamic>? ?? const {},
      ),
      facturas: DashboardModuloFacturas.fromJson(
        json['facturas'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}

class DashboardModuloProductos {
  const DashboardModuloProductos({
    required this.topMes,
    required this.topAnio,
  });

  final List<ChartPoint> topMes;
  final List<ChartPoint> topAnio;

  factory DashboardModuloProductos.fromJson(Map<String, dynamic> json) {
    return DashboardModuloProductos(
      topMes: (json['top_mes'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ChartPoint.fromJson)
          .toList(),
      topAnio: (json['top_anio'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ChartPoint.fromJson)
          .toList(),
    );
  }
}

class DashboardModuloServicios {
  const DashboardModuloServicios({
    required this.topMes,
    required this.topAnio,
    required this.serieMensual,
    required this.serieAnual,
  });

  final List<ChartPoint> topMes;
  final List<ChartPoint> topAnio;
  final List<ChartPoint> serieMensual;
  final List<ChartPoint> serieAnual;

  factory DashboardModuloServicios.fromJson(Map<String, dynamic> json) {
    return DashboardModuloServicios(
      topMes: (json['top_mes'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ChartPoint.fromJson)
          .toList(),
      topAnio: (json['top_anio'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ChartPoint.fromJson)
          .toList(),
      serieMensual: (json['serie_mensual'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ChartPoint.fromJson)
          .toList(),
      serieAnual: (json['serie_anual'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ChartPoint.fromJson)
          .toList(),
    );
  }
}

class DashboardModuloCotizaciones {
  const DashboardModuloCotizaciones({
    required this.serieSemana,
    required this.serieMes,
  });

  final List<ChartPoint> serieSemana;
  final List<ChartPoint> serieMes;

  factory DashboardModuloCotizaciones.fromJson(Map<String, dynamic> json) {
    return DashboardModuloCotizaciones(
      serieSemana: (json['serie_semana'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ChartPoint.fromJson)
          .toList(),
      serieMes: (json['serie_mes'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ChartPoint.fromJson)
          .toList(),
    );
  }
}

class DashboardModuloFacturas {
  const DashboardModuloFacturas({
    required this.serieSemana,
    required this.serieMes,
    required this.serieAnio,
    required this.totales,
  });

  final List<FacturaChartPoint> serieSemana;
  final List<FacturaChartPoint> serieMes;
  final List<FacturaChartPoint> serieAnio;
  final DashboardFacturasTotales totales;

  factory DashboardModuloFacturas.fromJson(Map<String, dynamic> json) {
    return DashboardModuloFacturas(
      serieSemana: (json['serie_semana'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(FacturaChartPoint.fromJson)
          .toList(),
      serieMes: (json['serie_mes'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(FacturaChartPoint.fromJson)
          .toList(),
      serieAnio: (json['serie_anio'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(FacturaChartPoint.fromJson)
          .toList(),
      totales: DashboardFacturasTotales.fromJson(
          json['totales'] as Map<String, dynamic>? ?? const {}),
    );
  }
}

class DashboardFacturasTotales {
  const DashboardFacturasTotales({
    required this.semana,
    required this.mes,
    required this.anio,
  });

  final double semana;
  final double mes;
  final double anio;

  factory DashboardFacturasTotales.fromJson(Map<String, dynamic> json) {
    return DashboardFacturasTotales(
      semana: _parseDouble(json['semana']),
      mes: _parseDouble(json['mes']),
      anio: _parseDouble(json['anio']),
    );
  }
}

class ChartPoint {
  const ChartPoint({
    required this.label,
    required this.total,
  });

  final String label;
  final double total;

  factory ChartPoint.fromJson(Map<String, dynamic> json) {
    return ChartPoint(
      label: json['label']?.toString() ?? '',
      total: _parseDouble(json['total']),
    );
  }
}

class FacturaChartPoint {
  const FacturaChartPoint({
    required this.label,
    required this.total,
    required this.cantidad,
  });

  final String label;
  final double total;
  final double cantidad;

  factory FacturaChartPoint.fromJson(Map<String, dynamic> json) {
    return FacturaChartPoint(
      label: json['label']?.toString() ?? '',
      total: _parseDouble(json['total']),
      cantidad: _parseDouble(json['cantidad']),
    );
  }
}

class VentaDiaria {
  const VentaDiaria({
    required this.fecha,
    required this.label,
    required this.facturado,
    required this.cotizado,
  });

  final String fecha;
  final String label;
  final double facturado;
  final double cotizado;

  factory VentaDiaria.fromJson(Map<String, dynamic> json) {
    return VentaDiaria(
      fecha: json['fecha']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      facturado: _parseDouble(json['facturado']),
      cotizado: _parseDouble(json['cotizado']),
    );
  }
}

class EstadoTotal {
  const EstadoTotal({required this.estado, required this.total});

  final String estado;
  final int total;

  factory EstadoTotal.fromJson(Map<String, dynamic> json) {
    return EstadoTotal(
      estado: json['estado']?.toString() ?? '',
      total: _parseInt(json['total']),
    );
  }
}

class PeriodoTotal {
  const PeriodoTotal({
    required this.periodo,
    required this.label,
    required this.total,
  });

  final String periodo;
  final String label;
  final double total;

  factory PeriodoTotal.fromJson(Map<String, dynamic> json) {
    return PeriodoTotal(
      periodo: json['periodo']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      total: _parseDouble(json['total']),
    );
  }
}

class ServicioTop {
  const ServicioTop({
    required this.servicio,
    required this.veces,
    required this.valorTotal,
  });

  final String servicio;
  final int veces;
  final double valorTotal;

  factory ServicioTop.fromJson(Map<String, dynamic> json) {
    return ServicioTop(
      servicio: json['servicio']?.toString() ?? '',
      veces: _parseInt(json['veces']),
      valorTotal: _parseDouble(json['valor_total']),
    );
  }
}

class DashboardCotizacionItem {
  const DashboardCotizacionItem({
    required this.id,
    required this.codigo,
    required this.clienteNombre,
    required this.estado,
    required this.total,
    required this.fecha,
  });

  final int id;
  final String codigo;
  final String clienteNombre;
  final String estado;
  final double total;
  final String? fecha;

  factory DashboardCotizacionItem.fromJson(Map<String, dynamic> json) {
    return DashboardCotizacionItem(
      id: _parseInt(json['id']),
      codigo: json['codigo']?.toString() ?? '',
      clienteNombre: json['cliente_nombre']?.toString() ?? '',
      estado: json['estado']?.toString() ?? '',
      total: _parseDouble(json['total']),
      fecha: json['fecha']?.toString(),
    );
  }
}

class DashboardFacturaItem {
  const DashboardFacturaItem({
    required this.id,
    required this.codigo,
    required this.clienteNombre,
    required this.total,
    required this.fecha,
    required this.emitidaAt,
  });

  final int id;
  final String codigo;
  final String clienteNombre;
  final double total;
  final String? fecha;
  final String? emitidaAt;

  factory DashboardFacturaItem.fromJson(Map<String, dynamic> json) {
    return DashboardFacturaItem(
      id: _parseInt(json['id']),
      codigo: json['codigo']?.toString() ?? '',
      clienteNombre: json['cliente_nombre']?.toString() ?? '',
      total: _parseDouble(json['total']),
      fecha: json['fecha']?.toString(),
      emitidaAt: json['emitida_at']?.toString(),
    );
  }
}

class DashboardProductoItem {
  const DashboardProductoItem({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.stock,
    required this.unidadMedida,
    required this.activo,
  });

  final int id;
  final String codigo;
  final String nombre;
  final int stock;
  final String unidadMedida;
  final bool activo;

  factory DashboardProductoItem.fromJson(Map<String, dynamic> json) {
    return DashboardProductoItem(
      id: _parseInt(json['id']),
      codigo: json['codigo']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      stock: _parseInt(json['stock']),
      unidadMedida: json['unidad_medida']?.toString() ?? 'Un.',
      activo: json['activo'] as bool? ?? false,
    );
  }
}

class BusinessDashboard {
  const BusinessDashboard({
    required this.periodo,
    required this.kpis,
    required this.graficas,
    required this.topItemsVendidos,
    required this.estadoDocumentos,
    required this.resumenFinanciero,
  });

  final DashboardPeriodo periodo;
  final BusinessKpis kpis;
  final DashboardGraficas graficas;
  final List<TopItemVendido> topItemsVendidos;
  final DashboardEstadoDocumentos estadoDocumentos;
  final DashboardResumenFinanciero resumenFinanciero;

  factory BusinessDashboard.fromJson(Map<String, dynamic> json) {
    return BusinessDashboard(
      periodo: DashboardPeriodo.fromJson(
          json['periodo'] as Map<String, dynamic>? ?? const {}),
      kpis: BusinessKpis.fromJson(
          json['kpis'] as Map<String, dynamic>? ?? const {}),
      graficas: DashboardGraficas.fromJson(
          json['graficas'] as Map<String, dynamic>? ?? const {}),
      topItemsVendidos: (json['top_items_vendidos'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(TopItemVendido.fromJson)
          .toList(),
      estadoDocumentos: DashboardEstadoDocumentos.fromJson(
          json['estado_documentos'] as Map<String, dynamic>? ?? const {}),
      resumenFinanciero: DashboardResumenFinanciero.fromJson(
          json['resumen_financiero'] as Map<String, dynamic>? ?? const {}),
    );
  }
}

class DashboardPeriodo {
  const DashboardPeriodo({
    required this.label,
    required this.inicio,
    required this.fin,
  });

  final String label;
  final String inicio;
  final String fin;

  factory DashboardPeriodo.fromJson(Map<String, dynamic> json) {
    return DashboardPeriodo(
      label: json['label']?.toString() ?? '',
      inicio: json['inicio']?.toString() ?? '',
      fin: json['fin']?.toString() ?? '',
    );
  }
}

class KpiWithVariation {
  const KpiWithVariation({
    required this.valor,
    required this.variacionPct,
  });
  final double valor;
  final double variacionPct;

  factory KpiWithVariation.fromJson(Map<String, dynamic> json) {
    return KpiWithVariation(
      valor: _parseDouble(json['valor']),
      variacionPct: _parseDouble(json['variacion_pct']),
    );
  }
}

class BusinessKpis {
  const BusinessKpis({
    required this.ventasFacturas,
    required this.facturasEmitidas,
    required this.cotizacionesEnviadas,
    required this.productosVendidos,
    required this.serviciosFacturados,
  });

  final KpiWithVariation ventasFacturas;
  final KpiWithVariation facturasEmitidas;
  final KpiWithVariation cotizacionesEnviadas;
  final KpiWithVariation productosVendidos;
  final KpiWithVariation serviciosFacturados;

  factory BusinessKpis.fromJson(Map<String, dynamic> json) {
    return BusinessKpis(
      ventasFacturas: KpiWithVariation.fromJson(
          json['ventas_facturas'] as Map<String, dynamic>? ?? const {}),
      facturasEmitidas: KpiWithVariation.fromJson(
          json['facturas_emitidas'] as Map<String, dynamic>? ?? const {}),
      cotizacionesEnviadas: KpiWithVariation.fromJson(
          json['cotizaciones_enviadas'] as Map<String, dynamic>? ?? const {}),
      productosVendidos: KpiWithVariation.fromJson(
          json['productos_vendidos'] as Map<String, dynamic>? ?? const {}),
      serviciosFacturados: KpiWithVariation.fromJson(
          json['servicios_facturados'] as Map<String, dynamic>? ?? const {}),
    );
  }
}

class DashboardGraficas {
  const DashboardGraficas({
    required this.ventasDiariasPeriodo,
    required this.ventasMensualesAnio,
    required this.ventasPorCategoriaProductos,
    required this.ventasPorTipo,
  });

  final List<VentaDiaria> ventasDiariasPeriodo;
  final List<PeriodoTotal> ventasMensualesAnio;
  final VentasDistribucion ventasPorCategoriaProductos;
  final VentasDistribucion ventasPorTipo;

  factory DashboardGraficas.fromJson(Map<String, dynamic> json) {
    return DashboardGraficas(
      ventasDiariasPeriodo:
          (json['ventas_diarias_periodo'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(VentaDiaria.fromJson)
              .toList(),
      ventasMensualesAnio:
          (json['ventas_mensuales_anio'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(PeriodoTotal.fromJson)
              .toList(),
      ventasPorCategoriaProductos: VentasDistribucion.fromJson(
          json['ventas_por_categoria_productos'] as Map<String, dynamic>? ??
              const {}),
      ventasPorTipo: VentasDistribucion.fromJson(
          json['ventas_por_tipo'] as Map<String, dynamic>? ?? const {}),
    );
  }
}

class VentasDistribucion {
  const VentasDistribucion({
    required this.total,
    required this.items,
  });

  final double total;
  final List<VentasDistribucionItem> items;

  factory VentasDistribucion.fromJson(Map<String, dynamic> json) {
    return VentasDistribucion(
      total: _parseDouble(json['total']),
      items: (json['items'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(VentasDistribucionItem.fromJson)
          .toList(),
    );
  }
}

class VentasDistribucionItem {
  const VentasDistribucionItem({
    required this.label,
    required this.valor,
    required this.porcentaje,
  });

  final String label;
  final double valor;
  final double porcentaje;

  factory VentasDistribucionItem.fromJson(Map<String, dynamic> json) {
    return VentasDistribucionItem(
      label: json['label']?.toString() ??
          json['categoria']?.toString() ??
          json['tipo']?.toString() ??
          '',
      valor: _parseDouble(json['valor']),
      porcentaje: _parseDouble(json['porcentaje']),
    );
  }
}

class TopItemVendido {
  const TopItemVendido({
    required this.descripcion,
    required this.unidad,
    required this.cantidad,
    required this.valorTotal,
  });

  final String descripcion;
  final String unidad;
  final double cantidad;
  final double valorTotal;

  factory TopItemVendido.fromJson(Map<String, dynamic> json) {
    return TopItemVendido(
      descripcion: (json['descripcion'] ?? json['item'])?.toString() ?? '',
      unidad: json['unidad']?.toString() ?? 'und',
      cantidad: _parseDouble(json['cantidad']),
      valorTotal: _parseDouble(json['valor_total']),
    );
  }
}

class DashboardEstadoDocumentos {
  const DashboardEstadoDocumentos({
    required this.cotizaciones,
    required this.facturas,
    required this.productos,
  });

  final EstadoDocumentoCard cotizaciones;
  final EstadoDocumentoCard facturas;
  final EstadoDocumentoCard productos;

  factory DashboardEstadoDocumentos.fromJson(Map<String, dynamic> json) {
    return DashboardEstadoDocumentos(
      cotizaciones: EstadoDocumentoCard.fromJson(
          json['cotizaciones'] as Map<String, dynamic>? ?? const {}),
      facturas: EstadoDocumentoCard.fromJson(
          json['facturas'] as Map<String, dynamic>? ?? const {}),
      productos: EstadoDocumentoCard.fromJson(
          json['productos'] as Map<String, dynamic>? ?? const {}),
    );
  }
}

class EstadoDocumentoCard {
  const EstadoDocumentoCard({
    required this.total,
    required this.estados,
  });

  final int total;
  final Map<String, int> estados;

  factory EstadoDocumentoCard.fromJson(Map<String, dynamic> json) {
    final nestedEstados = json['estados'] as Map<String, dynamic>?;
    final rawEstados = nestedEstados ??
        json.entries
            .where((entry) => entry.key != 'total')
            .fold<Map<String, dynamic>>(
              <String, dynamic>{},
              (acc, entry) {
                acc[entry.key] = entry.value;
                return acc;
              },
            );
    return EstadoDocumentoCard(
      total: _parseInt(json['total']),
      estados: rawEstados.map((key, value) => MapEntry(key, _parseInt(value))),
    );
  }
}

class DashboardResumenFinanciero {
  const DashboardResumenFinanciero({
    required this.ventas,
    required this.costosProductos,
    required this.gastosOperativos,
    required this.utilidad,
    required this.margenPct,
  });

  final double ventas;
  final double? costosProductos;
  final double? gastosOperativos;
  final double? utilidad;
  final double? margenPct;

  factory DashboardResumenFinanciero.fromJson(Map<String, dynamic> json) {
    return DashboardResumenFinanciero(
      ventas: _parseDouble(json['ventas_facturas'] ?? json['ventas']),
      costosProductos: (json['costos_productos_vendidos'] ?? json['costos_productos']) == null
          ? null
          : _parseDouble(json['costos_productos_vendidos'] ?? json['costos_productos']),
      gastosOperativos: json['gastos_operativos'] == null
          ? null
          : _parseDouble(json['gastos_operativos']),
      utilidad: (json['utilidad_estimada'] ?? json['utilidad']) == null
          ? null
          : _parseDouble(json['utilidad_estimada'] ?? json['utilidad']),
      margenPct: (json['margen_utilidad_pct'] ?? json['margen_pct']) == null
          ? null
          : _parseDouble(json['margen_utilidad_pct'] ?? json['margen_pct']),
    );
  }
}

int _parseInt(dynamic value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }
  if (value is double) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double _parseDouble(dynamic value, {double fallback = 0}) {
  if (value is double) {
    return value;
  }
  if (value is int) {
    return value.toDouble();
  }

  return double.tryParse(value?.toString() ?? '') ?? fallback;
}
