import 'factura_item.dart';

class Factura {
  Factura({
    required this.id,
    required this.codigo,
    required this.numero,
    required this.fecha,
    required this.ciudadExpedicion,
    required this.clienteNombre,
    required this.clienteNit,
    required this.clienteContacto,
    required this.clienteDireccion,
    required this.clienteCiudad,
    required this.observaciones,
    required this.firmaPath,
    required this.firmaNombre,
    required this.firmaCargo,
    required this.firmaEmpresa,
    required this.subtotal,
    required this.ivaTotal,
    required this.total,
    required this.estado,
    required this.items,
    required this.createdBy,
    required this.updatedBy,
    required this.createdByName,
    required this.updatedByName,
    required this.emitidaAt,
    required this.anuladaAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String codigo;
  final String numero;
  final String fecha;
  final String? ciudadExpedicion;
  final String clienteNombre;
  final String? clienteNit;
  final String? clienteContacto;
  final String? clienteDireccion;
  final String? clienteCiudad;
  final String? observaciones;
  final String? firmaPath;
  final String? firmaNombre;
  final String? firmaCargo;
  final String? firmaEmpresa;
  final String subtotal;
  final String ivaTotal;
  final String total;
  final String estado;
  final List<FacturaItem> items;
  final int? createdBy;
  final int? updatedBy;
  final String? createdByName;
  final String? updatedByName;
  final String? emitidaAt;
  final String? anuladaAt;
  final String? createdAt;
  final String? updatedAt;

  bool get isBorrador {
    final value = estado.trim().toLowerCase();
    return value == 'pendiente' || value == 'borrador';
  }

  bool get isPendiente => isBorrador;
  bool get isEmitida => estado.trim().toLowerCase() == 'emitida';
  bool get isAnulada => estado.trim().toLowerCase() == 'anulada';

  factory Factura.fromJson(Map<String, dynamic> json) {
    return Factura(
      id: _parseInt(json['id']),
      codigo: json['codigo']?.toString() ?? '',
      numero: json['numero']?.toString() ?? json['codigo']?.toString() ?? '',
      fecha: json['fecha']?.toString() ?? '',
      ciudadExpedicion: json['ciudad_expedicion']?.toString(),
      clienteNombre: json['cliente_nombre']?.toString() ?? '',
      clienteNit: json['cliente_nit']?.toString(),
      clienteContacto: json['cliente_contacto']?.toString(),
      clienteDireccion: json['cliente_direccion']?.toString(),
      clienteCiudad: json['cliente_ciudad']?.toString(),
      observaciones: json['observaciones']?.toString(),
      firmaPath: json['firma_path']?.toString(),
      firmaNombre: json['firma_nombre']?.toString(),
      firmaCargo: json['firma_cargo']?.toString(),
      firmaEmpresa: json['firma_empresa']?.toString(),
      subtotal: json['subtotal']?.toString() ?? '0',
      ivaTotal:
          json['iva_total']?.toString() ?? json['impuestos']?.toString() ?? '0',
      total: json['total']?.toString() ?? '0',
      estado: json['estado']?.toString() ?? 'pendiente',
      items: (json['items'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(FacturaItem.fromJson)
          .toList(),
      createdBy: _parseNullableInt(json['created_by']),
      updatedBy: _parseNullableInt(json['updated_by']),
      createdByName: json['created_by_name']?.toString(),
      updatedByName: json['updated_by_name']?.toString(),
      emitidaAt: json['emitida_at']?.toString(),
      anuladaAt: json['anulada_at']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
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
