import '../../../core/api/api_client.dart';
import '../domain/servicio.dart';
import 'paginated_servicios_response.dart';
import 'servicios_query.dart';

class ServiciosRepository {
  ServiciosRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<PaginatedServiciosResponse> fetchServicios(
    ServiciosQuery query,
  ) async {
    final response =
        await _apiClient.get('/servicios?${query.toQueryString()}');

    return PaginatedServiciosResponse.fromJson(response);
  }

  Future<List<String>> fetchCategorias() async {
    final response = await _apiClient.get('/categorias-servicio?per_page=50');
    final rawItems = response['data'];

    if (rawItems is! List) {
      return suggestedServiceCategories;
    }

    final categories = rawItems
        .whereType<Map>()
        .map((item) => normalizeServiceCategory(item['nombre']?.toString()))
        .where(suggestedServiceCategories.contains)
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    if (categories.isEmpty) {
      return suggestedServiceCategories;
    }

    return categories;
  }

  Future<Servicio> createServicio(Map<String, dynamic> payload) async {
    final response = await _apiClient.post('/servicios', payload);

    return Servicio.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Servicio> updateServicio(int id, Map<String, dynamic> payload) async {
    final response = await _apiClient.put('/servicios/$id', payload);

    return Servicio.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Servicio> toggleActivo(int id) async {
    final response = await _apiClient.patch('/servicios/$id/toggle-activo', {});

    return Servicio.fromJson(response['data'] as Map<String, dynamic>);
  }
}
