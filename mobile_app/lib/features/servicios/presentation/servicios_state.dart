import '../data/paginated_servicios_response.dart';
import '../data/servicios_query.dart';
import '../domain/servicio.dart';

class ServiciosState {
  const ServiciosState({
    required this.query,
    required this.searchText,
    required this.isInitialLoading,
    required this.isRefreshing,
    required this.response,
    required this.loadError,
    required this.availableCategories,
  });

  const ServiciosState.initial()
      : query = const ServiciosQuery(),
        searchText = '',
        isInitialLoading = true,
        isRefreshing = false,
        response = null,
        loadError = null,
        availableCategories = suggestedServiceCategories;

  static const _sentinel = Object();

  final ServiciosQuery query;
  final String searchText;
  final bool isInitialLoading;
  final bool isRefreshing;
  final PaginatedServiciosResponse? response;
  final Object? loadError;
  final List<String> availableCategories;

  bool get hasDraftSearch => searchText.trim().isNotEmpty;

  ServiciosState copyWith({
    ServiciosQuery? query,
    String? searchText,
    bool? isInitialLoading,
    bool? isRefreshing,
    Object? response = _sentinel,
    Object? loadError = _sentinel,
    List<String>? availableCategories,
  }) {
    return ServiciosState(
      query: query ?? this.query,
      searchText: searchText ?? this.searchText,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      response: identical(response, _sentinel)
          ? this.response
          : response as PaginatedServiciosResponse?,
      loadError: identical(loadError, _sentinel) ? this.loadError : loadError,
      availableCategories: availableCategories ?? this.availableCategories,
    );
  }
}
