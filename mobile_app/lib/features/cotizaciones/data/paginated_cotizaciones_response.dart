import '../domain/cotizacion.dart';

class PaginatedCotizacionesResponse {
  PaginatedCotizacionesResponse({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.stats,
  });

  final List<Cotizacion> items;
  final int currentPage;
  final int lastPage;
  final int total;
  final CotizacionesStats stats;

  factory PaginatedCotizacionesResponse.fromJson(Map<String, dynamic> json) {
    final items = (json['data'] as List<dynamic>)
        .map((item) => Cotizacion.fromJson(item as Map<String, dynamic>))
        .toList();
    final meta = json['meta'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final rawStats =
        json['stats'] as Map<String, dynamic>? ?? <String, dynamic>{};

    return PaginatedCotizacionesResponse(
      items: items,
      currentPage: meta['current_page'] as int? ?? 1,
      lastPage: meta['last_page'] as int? ?? 1,
      total: meta['total'] as int? ?? items.length,
      stats: CotizacionesStats.fromJson(rawStats),
    );
  }
}

class CotizacionesStats {
  const CotizacionesStats({
    required this.total,
    required this.pendiente,
    required this.visto,
    required this.realizada,
    required this.nula,
  });

  const CotizacionesStats.empty()
      : total = 0,
        pendiente = 0,
        visto = 0,
        realizada = 0,
        nula = 0;

  final int total;
  final int pendiente;
  final int visto;
  final int realizada;
  final int nula;

  factory CotizacionesStats.fromJson(Map<String, dynamic> json) {
    return CotizacionesStats(
      total: json['total'] as int? ?? 0,
      pendiente: json['pendiente'] as int? ?? 0,
      visto: json['visto'] as int? ?? 0,
      realizada: json['realizada'] as int? ?? 0,
      nula: json['nula'] as int? ?? 0,
    );
  }
}
