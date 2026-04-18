import '../domain/servicio.dart';

class ServiciosQuery {
  const ServiciosQuery({
    this.buscar = '',
    this.categoria = '',
    this.page = 1,
    this.orden = 'categoria',
    this.direccion = 'asc',
    this.activo,
    this.perPage = 10,
  });

  final String buscar;
  final String categoria;
  final int page;
  final String orden;
  final String direccion;
  final bool? activo;
  final int perPage;

  String toQueryString() {
    final categoriaNormalizada = normalizeServiceCategory(categoria);

    final params = <String, String>{
      'page': '$page',
      'per_page': '$perPage',
      'orden': orden,
      'direccion': direccion,
      if (buscar.trim().isNotEmpty) 'buscar': buscar.trim(),
      if (categoriaNormalizada.isNotEmpty) 'categoria': categoriaNormalizada,
      if (activo != null) 'activo': activo! ? 'true' : 'false',
    };

    return params.entries
        .map(
          (entry) => '${entry.key}=${Uri.encodeQueryComponent(entry.value)}',
        )
        .join('&');
  }

  ServiciosQuery copyWith({
    String? buscar,
    String? categoria,
    int? page,
    String? orden,
    String? direccion,
    bool? activo,
    bool clearActivo = false,
    bool clearCategoria = false,
  }) {
    return ServiciosQuery(
      buscar: buscar ?? this.buscar,
      categoria: clearCategoria
          ? ''
          : normalizeServiceCategory(categoria ?? this.categoria),
      page: page ?? this.page,
      orden: orden ?? this.orden,
      direccion: direccion ?? this.direccion,
      activo: clearActivo ? null : (activo ?? this.activo),
      perPage: perPage,
    );
  }
}
