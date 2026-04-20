import '../../../core/api/api_client.dart';
import '../domain/dashboard_summary.dart';

class DashboardRepository {
  DashboardRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<DashboardSummary> fetchResumen() async {
    final response = await _apiClient.get('/dashboard/resumen');
    return DashboardSummary.fromJson(response);
  }
}
