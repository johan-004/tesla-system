import '../productos/domain/producto.dart';
import 'data/facturas_query.dart';
import 'data/paginated_facturas_response.dart';

class FacturasState {
  const FacturasState({
    required this.query,
    required this.searchText,
    required this.isInitialLoading,
    required this.isRefreshing,
    required this.response,
    required this.loadError,
    required this.catalogoProductos,
    required this.isLoadingCatalogoProductos,
    required this.catalogoProductosError,
  });

  const FacturasState.initial()
      : query = const FacturasQuery(),
        searchText = '',
        isInitialLoading = true,
        isRefreshing = false,
        response = null,
        loadError = null,
        catalogoProductos = const [],
        isLoadingCatalogoProductos = false,
        catalogoProductosError = null;

  static const _sentinel = Object();

  final FacturasQuery query;
  final String searchText;
  final bool isInitialLoading;
  final bool isRefreshing;
  final PaginatedFacturasResponse? response;
  final Object? loadError;
  final List<Producto> catalogoProductos;
  final bool isLoadingCatalogoProductos;
  final Object? catalogoProductosError;

  bool get hasDraftSearch => searchText.trim().isNotEmpty;

  FacturasState copyWith({
    FacturasQuery? query,
    String? searchText,
    bool? isInitialLoading,
    bool? isRefreshing,
    Object? response = _sentinel,
    Object? loadError = _sentinel,
    List<Producto>? catalogoProductos,
    bool? isLoadingCatalogoProductos,
    Object? catalogoProductosError = _sentinel,
  }) {
    return FacturasState(
      query: query ?? this.query,
      searchText: searchText ?? this.searchText,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      response: identical(response, _sentinel)
          ? this.response
          : response as PaginatedFacturasResponse?,
      loadError: identical(loadError, _sentinel) ? this.loadError : loadError,
      catalogoProductos: catalogoProductos ?? this.catalogoProductos,
      isLoadingCatalogoProductos:
          isLoadingCatalogoProductos ?? this.isLoadingCatalogoProductos,
      catalogoProductosError: identical(catalogoProductosError, _sentinel)
          ? this.catalogoProductosError
          : catalogoProductosError,
    );
  }
}
