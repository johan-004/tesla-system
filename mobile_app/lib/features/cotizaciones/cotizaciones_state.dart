import 'data/cotizaciones_query.dart';
import 'data/paginated_cotizaciones_response.dart';
import '../servicios/domain/servicio.dart';

class CotizacionesState {
  const CotizacionesState({
    required this.query,
    required this.searchText,
    required this.isInitialLoading,
    required this.isRefreshing,
    required this.response,
    required this.loadError,
    required this.catalogoServicios,
    required this.isLoadingCatalogoServicios,
    required this.catalogoServiciosError,
  });

  const CotizacionesState.initial()
      : query = const CotizacionesQuery(),
        searchText = '',
        isInitialLoading = true,
        isRefreshing = false,
        response = null,
        loadError = null,
        catalogoServicios = const [],
        isLoadingCatalogoServicios = false,
        catalogoServiciosError = null;

  static const _sentinel = Object();

  final CotizacionesQuery query;
  final String searchText;
  final bool isInitialLoading;
  final bool isRefreshing;
  final PaginatedCotizacionesResponse? response;
  final Object? loadError;
  final List<Servicio> catalogoServicios;
  final bool isLoadingCatalogoServicios;
  final Object? catalogoServiciosError;

  bool get hasDraftSearch => searchText.trim().isNotEmpty;

  CotizacionesState copyWith({
    CotizacionesQuery? query,
    String? searchText,
    bool? isInitialLoading,
    bool? isRefreshing,
    Object? response = _sentinel,
    Object? loadError = _sentinel,
    List<Servicio>? catalogoServicios,
    bool? isLoadingCatalogoServicios,
    Object? catalogoServiciosError = _sentinel,
  }) {
    return CotizacionesState(
      query: query ?? this.query,
      searchText: searchText ?? this.searchText,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      response: identical(response, _sentinel)
          ? this.response
          : response as PaginatedCotizacionesResponse?,
      loadError: identical(loadError, _sentinel) ? this.loadError : loadError,
      catalogoServicios: catalogoServicios ?? this.catalogoServicios,
      isLoadingCatalogoServicios:
          isLoadingCatalogoServicios ?? this.isLoadingCatalogoServicios,
      catalogoServiciosError: identical(catalogoServiciosError, _sentinel)
          ? this.catalogoServiciosError
          : catalogoServiciosError,
    );
  }
}
