import '../../../core/api/api_client.dart';
import 'paginated_productos_response.dart';
import 'productos_query.dart';
import '../domain/producto.dart';

class ProductosRepository {
  ProductosRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<PaginatedProductosResponse> fetchProductos(
      ProductosQuery query) async {
    final response =
        await _apiClient.get('/productos?${query.toQueryString()}');

    return PaginatedProductosResponse.fromJson(response);
  }

  Future<List<Producto>> fetchSuggestions(String buscar,
      {int limite = 6}) async {
    final query = Uri(queryParameters: {
      'buscar': buscar.trim(),
      'limite': '$limite',
    }).query;

    final response = await _apiClient.get('/productos/sugerencias?$query');
    final data = response['data'] as List<dynamic>? ?? const [];

    return data
        .map((item) => Producto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Producto> createProducto(Map<String, dynamic> payload) async {
    final response = await _apiClient.post('/productos', payload);

    return Producto.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Producto> updateProducto(int id, Map<String, dynamic> payload) async {
    final response = await _apiClient.put('/productos/$id', payload);

    return Producto.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Producto> toggleActivo(int id) async {
    final response = await _apiClient.patch('/productos/$id/toggle-activo', {});

    return Producto.fromJson(response['data'] as Map<String, dynamic>);
  }
}
