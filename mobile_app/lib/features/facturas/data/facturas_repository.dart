import '../../../core/api/api_client.dart';
import '../../productos/domain/producto.dart';
import '../domain/factura.dart';
import 'facturas_query.dart';
import 'paginated_facturas_response.dart';

class FacturasRepository {
  FacturasRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<PaginatedFacturasResponse> fetchFacturas(FacturasQuery query) async {
    final response = await _apiClient.get('/facturas?${query.toQueryString()}');

    return PaginatedFacturasResponse.fromJson(response);
  }

  Future<Factura> fetchFactura(int id) async {
    final response = await _apiClient.get('/facturas/$id');
    return Factura.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Factura> createFactura(Map<String, dynamic> payload) async {
    final response = await _apiClient.post('/facturas', payload);
    return Factura.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Factura> updateFactura(int id, Map<String, dynamic> payload) async {
    final response = await _apiClient.put('/facturas/$id', payload);
    return Factura.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Factura> emitirFactura(int id) async {
    final response = await _apiClient.patch('/facturas/$id/emitir', {});
    return Factura.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<List<Producto>> fetchProductosDisponibles() async {
    const perPage = 100;
    final collected = <Producto>[];
    var currentPage = 1;
    var lastPage = 1;

    do {
      final response = await _apiClient.get(
        '/productos?per_page=$perPage&page=$currentPage&orden=nombre&direccion=asc&activo=true',
      );
      final data = response['data'];
      if (data is! List) {
        break;
      }

      collected.addAll(
        data.whereType<Map<String, dynamic>>().map(Producto.fromJson),
      );

      final meta = response['meta'];
      if (meta is! Map<String, dynamic>) {
        break;
      }

      final rawLastPage = meta['last_page'];
      lastPage =
          (rawLastPage is int ? rawLastPage : int.tryParse('$rawLastPage')) ??
              currentPage;
      currentPage += 1;
    } while (currentPage <= lastPage);

    final uniqueById = <int, Producto>{};
    for (final producto in collected) {
      uniqueById[producto.id] = producto;
    }

    final productos = uniqueById.values.toList()
      ..sort((a, b) {
        final byName = a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase());
        if (byName != 0) {
          return byName;
        }
        return a.codigo.toLowerCase().compareTo(b.codigo.toLowerCase());
      });

    return productos;
  }
}
