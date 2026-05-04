import '../../../core/api/api_client.dart';
import '../domain/dashboard_summary.dart';

class DashboardRepository {
  DashboardRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<DashboardSummary> fetchResumen({
    int? mes,
    int? anio,
    String? quick,
  }) async {
    final query = <String, String>{};
    if (mes != null) {
      query['mes'] = '$mes';
    }
    if (anio != null) {
      query['anio'] = '$anio';
    }
    if (quick != null && quick.trim().isNotEmpty) {
      query['quick'] = quick.trim();
    }
    final suffix = query.isEmpty ? '' : '?${Uri(queryParameters: query).query}';
    final response = await _apiClient.get('/dashboard/resumen$suffix');
    return DashboardSummary.fromJson(response);
  }
}
