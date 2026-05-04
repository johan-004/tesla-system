class FacturaItem {
  FacturaItem({
    required this.id,
    required this.facturaId,
    required this.tipoItem,
    required this.productoId,
    required this.servicioId,
    required this.codigo,
    required this.orden,
    required this.descripcion,
    required this.unidad,
    required this.cantidad,
    required this.precioUnitario,
    required this.ivaPorcentaje,
    required this.ivaValor,
    required this.subtotalLinea,
    required this.totalLinea,
  });

  final int id;
  final int facturaId;
  final String tipoItem;
  final int? productoId;
  final int? servicioId;
  final String codigo;
  final int orden;
  final String descripcion;
  final String unidad;
  final String cantidad;
  final String precioUnitario;
  final String ivaPorcentaje;
  final String ivaValor;
  final String subtotalLinea;
  final String totalLinea;

  factory FacturaItem.fromJson(Map<String, dynamic> json) {
    return FacturaItem(
      id: _parseInt(json['id']),
      facturaId: _parseInt(json['factura_id']),
      tipoItem: json['tipo_item']?.toString() ?? 'servicio',
      productoId: _parseNullableInt(json['producto_id']),
      servicioId: _parseNullableInt(json['servicio_id']),
      codigo: json['codigo']?.toString() ?? '',
      orden: _parseInt(json['orden']),
      descripcion: json['descripcion']?.toString() ?? '',
      unidad: json['unidad']?.toString() ?? '',
      cantidad: json['cantidad']?.toString() ?? '0',
      precioUnitario: json['precio_unitario']?.toString() ?? '0',
      ivaPorcentaje: json['iva_porcentaje']?.toString() ?? '0',
      ivaValor: json['iva_valor']?.toString() ?? '0',
      subtotalLinea: json['subtotal_linea']?.toString() ?? '0',
      totalLinea: json['total_linea']?.toString() ?? '0',
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

  if (value is int) {
    return value;
  }

  if (value is double) {
    return value.toInt();
  }

  return int.tryParse(value.toString());
}
