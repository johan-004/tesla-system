class Cotizacion {
  Cotizacion({
    required this.id,
    required this.numero,
    required this.codigo,
    required this.fecha,
    required this.ciudad,
    required this.clienteNombre,
    required this.clienteNit,
    required this.clienteContacto,
    required this.clienteCargo,
    required this.clienteCiudad,
    required this.clienteDireccion,
    required this.referencia,
    required this.observaciones,
    required this.alcanceItems,
    required this.ofertaDiasTotales,
    required this.ofertaDiasEjecucion,
    required this.ofertaDiasTramitologia,
    required this.ofertaPago1Pct,
    required this.ofertaPago2Pct,
    required this.ofertaPago3Pct,
    required this.ofertaGarantiaMeses,
    required this.firmaPath,
    required this.firmaNombre,
    required this.firmaCargo,
    required this.firmaEmpresa,
    required this.subtotal,
    required this.total,
    required this.estado,
    required this.detalles,
    required this.createdBy,
    required this.updatedBy,
    required this.createdByName,
    required this.updatedByName,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String numero;
  final String codigo;
  final String fecha;
  final String ciudad;
  final String clienteNombre;
  final String? clienteNit;
  final String? clienteContacto;
  final String? clienteCargo;
  final String? clienteCiudad;
  final String? clienteDireccion;
  final String referencia;
  final String? observaciones;
  final List<String> alcanceItems;
  final int ofertaDiasTotales;
  final int ofertaDiasEjecucion;
  final int ofertaDiasTramitologia;
  final String ofertaPago1Pct;
  final String ofertaPago2Pct;
  final String ofertaPago3Pct;
  final int ofertaGarantiaMeses;
  final String? firmaPath;
  final String firmaNombre;
  final String firmaCargo;
  final String firmaEmpresa;
  final String subtotal;
  final String total;
  final String estado;
  final List<CotizacionDetalle> detalles;
  final int? createdBy;
  final int? updatedBy;
  final String? createdByName;
  final String? updatedByName;
  final String? createdAt;
  final String? updatedAt;

  factory Cotizacion.fromJson(Map<String, dynamic> json) {
    return Cotizacion(
      id: _parseInt(json['id']),
      numero: json['numero']?.toString() ?? '',
      codigo: json['codigo']?.toString() ?? json['numero']?.toString() ?? '',
      fecha: json['fecha']?.toString() ?? '',
      ciudad: json['ciudad']?.toString() ?? '',
      clienteNombre: json['cliente_nombre']?.toString() ?? '',
      clienteNit: json['cliente_nit']?.toString(),
      clienteContacto: json['cliente_contacto']?.toString(),
      clienteCargo: json['cliente_cargo']?.toString(),
      clienteCiudad: json['cliente_ciudad']?.toString(),
      clienteDireccion: json['cliente_direccion']?.toString(),
      referencia: json['referencia']?.toString() ?? '',
      observaciones: json['observaciones']?.toString(),
      alcanceItems: (json['alcance_items'] as List<dynamic>? ?? const [])
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList(),
      ofertaDiasTotales:
          int.tryParse(json['oferta_dias_totales']?.toString() ?? '') ?? 30,
      ofertaDiasEjecucion:
          int.tryParse(json['oferta_dias_ejecucion']?.toString() ?? '') ?? 15,
      ofertaDiasTramitologia:
          int.tryParse(json['oferta_dias_tramitologia']?.toString() ?? '') ??
              15,
      ofertaPago1Pct: json['oferta_pago_1_pct']?.toString() ?? '50',
      ofertaPago2Pct: json['oferta_pago_2_pct']?.toString() ?? '25',
      ofertaPago3Pct: json['oferta_pago_3_pct']?.toString() ?? '25',
      ofertaGarantiaMeses:
          int.tryParse(json['oferta_garantia_meses']?.toString() ?? '') ?? 6,
      firmaPath: json['firma_path']?.toString(),
      firmaNombre:
          json['firma_nombre']?.toString() ?? 'Maria Alejandra Florez Ocampo.',
      firmaCargo: json['firma_cargo']?.toString() ?? 'Representante.',
      firmaEmpresa:
          json['firma_empresa']?.toString() ?? 'Proyecciones electricas Tesla',
      subtotal: json['subtotal']?.toString() ?? '0',
      total: json['total']?.toString() ?? '0',
      estado: json['estado']?.toString() ?? 'pendiente',
      detalles: (json['detalles'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(CotizacionDetalle.fromJson)
          .toList(),
      createdBy: _parseNullableInt(json['created_by']),
      updatedBy: _parseNullableInt(json['updated_by']),
      createdByName: json['created_by_name']?.toString(),
      updatedByName: json['updated_by_name']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
}

class CotizacionDetalle {
  CotizacionDetalle({
    required this.id,
    required this.item,
    required this.servicioId,
    required this.descripcion,
    required this.unidad,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
  });

  final int id;
  final int item;
  final int? servicioId;
  final String descripcion;
  final String unidad;
  final String cantidad;
  final String precioUnitario;
  final String subtotal;

  factory CotizacionDetalle.fromJson(Map<String, dynamic> json) {
    return CotizacionDetalle(
      id: _parseInt(json['id']),
      item: _parseInt(json['item']),
      servicioId: _parseNullableInt(json['servicio_id']),
      descripcion: json['descripcion']?.toString() ?? '',
      unidad: json['unidad']?.toString() ?? '',
      cantidad: json['cantidad']?.toString() ?? '0',
      precioUnitario: json['precio_unitario']?.toString() ?? '0',
      subtotal: json['subtotal']?.toString() ?? '0',
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

int? _parseNullableInt(dynamic value) {
  if (value == null) {
    return null;
  }

  final parsed = _parseInt(value, fallback: -1);
  return parsed == -1 ? null : parsed;
}
