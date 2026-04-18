import '../domain/producto.dart';

class PaginatedProductosResponse {
  PaginatedProductosResponse({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final List<Producto> items;
  final int currentPage;
  final int lastPage;
  final int total;

  factory PaginatedProductosResponse.fromJson(Map<String, dynamic> json) {
    final items = (json['data'] as List<dynamic>)
        .map((item) => Producto.fromJson(item as Map<String, dynamic>))
        .toList();
    final meta = json['meta'] as Map<String, dynamic>? ?? <String, dynamic>{};

    return PaginatedProductosResponse(
      items: items,
      currentPage: meta['current_page'] as int? ?? 1,
      lastPage: meta['last_page'] as int? ?? 1,
      total: meta['total'] as int? ?? items.length,
    );
  }
}
