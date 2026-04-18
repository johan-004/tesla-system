const suggestedServiceCategories = <String>[
  'residencial',
  'comercial',
  'industrial',
  'mantenimiento y emergencias',
];

String normalizeServiceCategory(String? value) {
  final normalized = value?.trim().toLowerCase() ?? '';
  return normalized;
}

String formatServiceCategoryLabel(String value) {
  final normalized = normalizeServiceCategory(value);
  if (normalized.isEmpty) {
    return '';
  }

  return normalized
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1))
      .join(' ');
}

class Servicio {
  Servicio({
    required this.id,
    required this.codigo,
    required this.descripcion,
    required this.categoria,
    required this.unidad,
    required this.precioUnitario,
    required this.iva,
    required this.precioConIva,
    required this.observaciones,
    required this.activo,
  });

  final int id;
  final String codigo;
  final String descripcion;
  final String categoria;
  final String unidad;
  final String precioUnitario;
  final String iva;
  final String precioConIva;
  final String observaciones;
  final bool activo;

  factory Servicio.fromJson(Map<String, dynamic> json) {
    return Servicio(
      id: json['id'] as int,
      codigo: json['codigo']?.toString() ?? '',
      descripcion: json['descripcion']?.toString() ?? '',
      categoria: json['categoria']?.toString() ?? '',
      unidad: json['unidad']?.toString() ?? '',
      precioUnitario: json['precio_unitario']?.toString() ?? '0',
      iva: json['iva']?.toString() ?? '0',
      precioConIva: json['precio_con_iva']?.toString() ?? '0',
      observaciones: json['observaciones']?.toString() ?? '',
      activo: json['activo'] as bool? ?? false,
    );
  }
}
