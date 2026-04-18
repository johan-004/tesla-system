class ProductosQuery {
  const ProductosQuery({
    this.buscar = '',
    this.page = 1,
    this.orden = 'codigo',
    this.direccion = 'asc',
    this.activo,
    this.perPage = 10,
  });

  final String buscar;
  final int page;
  final String orden;
  final String direccion;
  final bool? activo;
  final int perPage;

  String toQueryString() {
    final params = <String, String>{
      'page': '$page',
      'per_page': '$perPage',
      'orden': orden,
      'direccion': direccion,
      if (buscar.trim().isNotEmpty) 'buscar': buscar.trim(),
      if (activo != null) 'activo': activo! ? 'true' : 'false',
    };

    return params.entries.map((entry) => '${entry.key}=${Uri.encodeQueryComponent(entry.value)}').join('&');
  }

  ProductosQuery copyWith({
    String? buscar,
    int? page,
    String? orden,
    String? direccion,
    bool? activo,
    bool clearActivo = false,
  }) {
    return ProductosQuery(
      buscar: buscar ?? this.buscar,
      page: page ?? this.page,
      orden: orden ?? this.orden,
      direccion: direccion ?? this.direccion,
      activo: clearActivo ? null : (activo ?? this.activo),
      perPage: perPage,
    );
  }
}
