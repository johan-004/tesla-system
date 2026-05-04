import '../domain/factura.dart';

class PaginatedFacturasResponse {
  PaginatedFacturasResponse({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.stats,
  });

  final List<Factura> items;
  final int currentPage;
  final int lastPage;
  final int total;
  final FacturasStats stats;

  factory PaginatedFacturasResponse.fromJson(Map<String, dynamic> json) {
    final items = (json['data'] as List<dynamic>)
        .map((item) => Factura.fromJson(item as Map<String, dynamic>))
        .toList();
    final meta = json['meta'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final rawStats =
        json['stats'] as Map<String, dynamic>? ?? <String, dynamic>{};

    return PaginatedFacturasResponse(
      items: items,
      currentPage: meta['current_page'] as int? ?? 1,
      lastPage: meta['last_page'] as int? ?? 1,
      total: meta['total'] as int? ?? items.length,
      stats: FacturasStats.fromJson(rawStats),
    );
  }
}

class FacturasStats {
  const FacturasStats({
    required this.total,
    required this.pendiente,
    required this.emitida,
    required this.anulada,
  });

  const FacturasStats.empty()
      : total = 0,
        pendiente = 0,
        emitida = 0,
        anulada = 0;

  final int total;
  final int pendiente;
  final int emitida;
  final int anulada;
  int get borrador => pendiente; // Legacy alias for older UI paths.

  factory FacturasStats.fromJson(Map<String, dynamic> json) {
    return FacturasStats(
      total: json['total'] as int? ?? 0,
      pendiente: (json['pendiente'] as int?) ?? (json['borrador'] as int?) ?? 0,
      emitida: json['emitida'] as int? ?? 0,
      anulada: json['anulada'] as int? ?? 0,
    );
  }
}
