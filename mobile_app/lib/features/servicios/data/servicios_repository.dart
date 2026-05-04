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
    final response = await _apiClient.get('/categorias-servicio?per_page=200');
    final rawItems = response['data'];

    if (rawItems is! List) {
      return const [];
    }

    final categories = rawItems
        .whereType<Map>()
        .map((item) => normalizeServiceCategory(item['nombre']?.toString()))
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    return categories;
  }

  Future<String> createCategoria(String nombre) async {
    final response = await _apiClient.post('/categorias-servicio', {
      'nombre': normalizeServiceCategory(nombre),
      'activo': true,
    });
    final data = response['data'] as Map<String, dynamic>? ?? const {};
    return normalizeServiceCategory(data['nombre']?.toString());
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
