import '../../../core/api/api_client.dart';
import '../domain/cliente.dart';

class ClientesRepository {
  ClientesRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<Cliente>> fetchClientes() async {
    final response = await _apiClient.get('/clientes');
    final items = response['data'] as List<dynamic>;

    return items
        .map((item) => Cliente.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
