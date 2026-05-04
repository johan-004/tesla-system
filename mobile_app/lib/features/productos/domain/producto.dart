class Producto {
  Producto({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.precioVenta,
    required this.ivaPorcentaje,
    required this.stock,
    required this.unidadMedida,
    required this.categoriaId,
    required this.categoriaNombre,
    required this.activo,
  });

  final int id;
  final String codigo;
  final String nombre;
  final String precioVenta;
  final String ivaPorcentaje;
  final int stock;
  final String unidadMedida;
  final int? categoriaId;
  final String categoriaNombre;
  final bool activo;

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: json['id'] as int,
      codigo: json['codigo']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      precioVenta: json['precio_venta']?.toString() ?? '0',
      ivaPorcentaje: json['iva_porcentaje']?.toString() ?? '0',
      stock: json['stock'] as int? ?? 0,
      unidadMedida: json['unidad_medida']?.toString() ?? '',
      categoriaId: _parseNullableInt(json['categoria_id']),
      categoriaNombre: json['categoria_nombre']?.toString() ?? 'Sin categoría',
      activo: json['activo'] as bool? ?? false,
    );
  }
}

int? _parseNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse(value.toString());
}
