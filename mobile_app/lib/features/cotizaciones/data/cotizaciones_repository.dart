import '../../../core/api/api_client.dart';
import '../../servicios/domain/servicio.dart';
import '../domain/cotizacion.dart';
import 'cotizaciones_query.dart';
import 'paginated_cotizaciones_response.dart';

class CotizacionesRepository {
  CotizacionesRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<PaginatedCotizacionesResponse> fetchCotizaciones(
    CotizacionesQuery query,
  ) async {
    final response =
        await _apiClient.get('/cotizaciones?${query.toQueryString()}');

    return PaginatedCotizacionesResponse.fromJson(response);
  }

  Future<Cotizacion> fetchCotizacion(int id) async {
    final response = await _apiClient.get('/cotizaciones/$id');
    return Cotizacion.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Cotizacion> createCotizacion(Map<String, dynamic> payload) async {
    final response = await _apiClient.post('/cotizaciones', payload);
    return Cotizacion.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Cotizacion> updateCotizacion(
    int id,
    Map<String, dynamic> payload,
  ) async {
    final response = await _apiClient.put('/cotizaciones/$id', payload);
    return Cotizacion.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Cotizacion> marcarRealizada(int id) async {
    final response = await _apiClient.patch(
      '/cotizaciones/$id/marcar-realizada',
      {},
    );
    return Cotizacion.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Cotizacion> marcarNula(int id) async {
    final response =
        await _apiClient.patch('/cotizaciones/$id/marcar-nula', {});
    return Cotizacion.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<List<Servicio>> fetchServiciosDisponibles() async {
    const perPage = 100;
    final collected = <Servicio>[];
    var currentPage = 1;
    var lastPage = 1;

    do {
      final response = await _apiClient.get(
        '/servicios?per_page=$perPage&page=$currentPage&orden=categoria&direccion=asc&activo=true',
      );
      final data = response['data'];
      if (data is! List) {
        break;
      }

      collected.addAll(
        data.whereType<Map<String, dynamic>>().map(Servicio.fromJson),
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

    final uniqueById = <int, Servicio>{};
    for (final servicio in collected) {
      uniqueById[servicio.id] = servicio;
    }

    final servicios = uniqueById.values.toList()
      ..sort((a, b) {
        final categoryComparison = formatServiceCategoryLabel(a.categoria)
            .compareTo(formatServiceCategoryLabel(b.categoria));
        if (categoryComparison != 0) {
          return categoryComparison;
        }

        final descriptionComparison = a.descripcion.toLowerCase().compareTo(
              b.descripcion.toLowerCase(),
            );
        if (descriptionComparison != 0) {
          return descriptionComparison;
        }

        return a.codigo.toLowerCase().compareTo(b.codigo.toLowerCase());
      });

    return servicios;
  }

  Future<String> uploadFirma(String filePath) async {
    final response = await _apiClient.postMultipartFile(
      path: '/cotizaciones/firma/upload',
      fieldName: 'firma',
      filePath: filePath,
    );
    final data = response['data'];
    if (data is Map<String, dynamic>) {
      final firmaPath = data['firma_path']?.toString().trim() ?? '';
      if (firmaPath.isNotEmpty) {
        return firmaPath;
      }
    }

    throw ApiException('La API no devolvió una ruta de firma válida.', 0);
  }

  Future<void> guardarFirmaPredeterminada({
    required String? firmaPath,
    required String firmaNombre,
    required String firmaCargo,
    required String firmaEmpresa,
  }) async {
    await _apiClient.patch('/cotizaciones/firma-predeterminada', {
      'firma_path': firmaPath,
      'firma_nombre': firmaNombre,
      'firma_cargo': firmaCargo,
      'firma_empresa': firmaEmpresa,
    });
  }
}
