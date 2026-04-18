class CotizacionesQuery {
  const CotizacionesQuery({
    this.buscar = '',
    this.estado = '',
    this.page = 1,
    this.orden = 'fecha',
    this.direccion = 'desc',
    this.perPage = 10,
  });

  final String buscar;
  final String estado;
  final int page;
  final String orden;
  final String direccion;
  final int perPage;

  String toQueryString() {
    final params = <String, String>{
      'page': '$page',
      'per_page': '$perPage',
      'orden': orden,
      'direccion': direccion,
      if (buscar.trim().isNotEmpty) 'buscar': buscar.trim(),
      if (estado.trim().isNotEmpty) 'estado': estado.trim(),
    };

    return params.entries
        .map(
          (entry) => '${entry.key}=${Uri.encodeQueryComponent(entry.value)}',
        )
        .join('&');
  }

  CotizacionesQuery copyWith({
    String? buscar,
    String? estado,
    int? page,
    String? orden,
    String? direccion,
    bool clearEstado = false,
  }) {
    return CotizacionesQuery(
      buscar: buscar ?? this.buscar,
      estado: clearEstado ? '' : (estado ?? this.estado),
      page: page ?? this.page,
      orden: orden ?? this.orden,
      direccion: direccion ?? this.direccion,
      perPage: perPage,
    );
  }
}
