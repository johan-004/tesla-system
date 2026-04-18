import '../data/paginated_productos_response.dart';
import '../data/productos_query.dart';
import '../domain/producto.dart';

class ProductosState {
  const ProductosState({
    required this.query,
    required this.searchText,
    required this.suggestions,
    required this.isLoadingSuggestions,
    required this.showSuggestions,
    required this.isInitialLoading,
    required this.isRefreshing,
    required this.response,
    required this.loadError,
  });

  const ProductosState.initial()
      : query = const ProductosQuery(),
        searchText = '',
        suggestions = const [],
        isLoadingSuggestions = false,
        showSuggestions = false,
        isInitialLoading = true,
        isRefreshing = false,
        response = null,
        loadError = null;

  static const _sentinel = Object();

  final ProductosQuery query;
  final String searchText;
  final List<Producto> suggestions;
  final bool isLoadingSuggestions;
  final bool showSuggestions;
  final bool isInitialLoading;
  final bool isRefreshing;
  final PaginatedProductosResponse? response;
  final Object? loadError;

  bool get hasDraftSearch => searchText.trim().isNotEmpty;

  ProductosState copyWith({
    ProductosQuery? query,
    String? searchText,
    List<Producto>? suggestions,
    bool? isLoadingSuggestions,
    bool? showSuggestions,
    bool? isInitialLoading,
    bool? isRefreshing,
    Object? response = _sentinel,
    Object? loadError = _sentinel,
  }) {
    return ProductosState(
      query: query ?? this.query,
      searchText: searchText ?? this.searchText,
      suggestions: suggestions ?? this.suggestions,
      isLoadingSuggestions: isLoadingSuggestions ?? this.isLoadingSuggestions,
      showSuggestions: showSuggestions ?? this.showSuggestions,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      response: identical(response, _sentinel)
          ? this.response
          : response as PaginatedProductosResponse?,
      loadError: identical(loadError, _sentinel) ? this.loadError : loadError,
    );
  }
}
