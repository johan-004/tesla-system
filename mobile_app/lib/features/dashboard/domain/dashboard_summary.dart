class DashboardSummary {
  DashboardSummary({
    required this.kpis,
    required this.cotizacionesPorEstado,
    required this.facturacionPorMes,
    required this.serviciosTopCotizados,
    required this.ultimasCotizaciones,
    required this.ultimasFacturasEmitidas,
    required this.productosStockBajo,
    required this.productosInactivos,
    required this.stockBajoHasta,
    required this.periodoMesInicio,
    required this.periodoMesFin,
  });

  final DashboardKpis kpis;
  final List<EstadoTotal> cotizacionesPorEstado;
  final List<PeriodoTotal> facturacionPorMes;
  final List<ServicioTop> serviciosTopCotizados;
  final List<DashboardCotizacionItem> ultimasCotizaciones;
  final List<DashboardFacturaItem> ultimasFacturasEmitidas;
  final List<DashboardProductoItem> productosStockBajo;
  final List<DashboardProductoItem> productosInactivos;
  final int stockBajoHasta;
  final String? periodoMesInicio;
  final String? periodoMesFin;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? const {};
    final kpisJson = data['kpis'] as Map<String, dynamic>? ?? const {};
    final charts = data['charts'] as Map<String, dynamic>? ?? const {};
    final operativo = data['operativo'] as Map<String, dynamic>? ?? const {};
    final contexto = data['contexto'] as Map<String, dynamic>? ?? const {};
    final periodoMesActual =
        contexto['periodo_mes_actual'] as Map<String, dynamic>? ?? const {};

    return DashboardSummary(
      kpis: DashboardKpis.fromJson(kpisJson),
      cotizacionesPorEstado:
          (charts['cotizaciones_por_estado'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(EstadoTotal.fromJson)
              .toList(),
      facturacionPorMes:
          (charts['facturacion_por_mes'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(PeriodoTotal.fromJson)
              .toList(),
      serviciosTopCotizados:
          (charts['servicios_top_cotizados'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(ServicioTop.fromJson)
              .toList(),
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
    );
  }
}

class DashboardKpis {
  const DashboardKpis({
    required this.cotizacionesPendientes,
    required this.cotizacionesVistas,
    required this.cotizacionesRealizadas,
    required this.facturasBorrador,
    required this.facturasEmitidas,
    required this.totalFacturadoMes,
    required this.productosStockBajo,
    required this.productosInactivos,
  });

  final int cotizacionesPendientes;
  final int cotizacionesVistas;
  final int cotizacionesRealizadas;
  final int facturasBorrador;
  final int facturasEmitidas;
  final double totalFacturadoMes;
  final int productosStockBajo;
  final int productosInactivos;

  factory DashboardKpis.fromJson(Map<String, dynamic> json) {
    return DashboardKpis(
      cotizacionesPendientes: _parseInt(json['cotizaciones_pendientes']),
      cotizacionesVistas: _parseInt(json['cotizaciones_vistas']),
      cotizacionesRealizadas: _parseInt(json['cotizaciones_realizadas']),
      facturasBorrador: _parseInt(json['facturas_borrador']),
      facturasEmitidas: _parseInt(json['facturas_emitidas']),
      totalFacturadoMes: _parseDouble(json['total_facturado_mes']),
      productosStockBajo: _parseInt(json['productos_stock_bajo']),
      productosInactivos: _parseInt(json['productos_inactivos']),
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
