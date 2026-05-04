class ProductoCategoria {
  ProductoCategoria({
    required this.id,
    required this.nombre,
    required this.activo,
  });

  final int id;
  final String nombre;
  final bool activo;

  factory ProductoCategoria.fromJson(Map<String, dynamic> json) {
    return ProductoCategoria(
      id: json['id'] as int,
      nombre: json['nombre']?.toString() ?? '',
      activo: json['activo'] as bool? ?? true,
    );
  }
}

