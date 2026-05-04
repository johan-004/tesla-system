import 'dart:async';

import 'package:flutter/material.dart';

import '../data/paginated_productos_response.dart';
import '../data/productos_query.dart';
import '../data/productos_repository.dart';
import '../domain/producto.dart';
import 'productos_state.dart';

class ProductosController extends ChangeNotifier {
  ProductosController({
    required this.repository,
    required Duration pollingInterval,
  }) : _pollingInterval = pollingInterval;

  final ProductosRepository repository;
  final Duration _pollingInterval;

  final searchController = TextEditingController();
  final searchFocusNode = FocusNode();

  ProductosState _state = const ProductosState.initial();
  Timer? _searchDebounce;
  Timer? _pollingTimer;
  ProductosQuery? _queuedQuery;
  bool _refreshQueued = false;
  bool _pollingPaused = false;
  int _suggestionRequestId = 0;
  int _refreshRequestId = 0;
  bool _isDisposed = false;

  ProductosState get state => _state;

  void initialize() {
    _syncSearchController(_state.searchText);
    searchFocusNode.addListener(_onSearchFocusChanged);
    unawaited(refresh(silent: false, reason: 'initialize'));
    _startPolling();
  }

  void onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _setState(
      _state.copyWith(
        searchText: value,
        isLoadingSuggestions: false,
      ),
    );

    final term = value.trim();
    if (term.isEmpty) {
      _log('search draft cleared');
      _setState(
        _state.copyWith(
          suggestions: const [],
          showSuggestions: false,
          isLoadingSuggestions: false,
        ),
      );
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      unawaited(_loadSuggestions(term));
    });
  }

  void selectSuggestion(Producto producto) {
    _log('suggestion selected codigo=${producto.codigo}');
    _setSearchText(producto.codigo);
    unawaited(applySearch(producto.codigo, reason: 'suggestion'));
  }

  void clearSearch() {
    _searchDebounce?.cancel();
    _log('search cleared');
    _setSearchText('');
    _setState(
      _state.copyWith(
        suggestions: const [],
        showSuggestions: false,
        isLoadingSuggestions: false,
      ),
    );
    unawaited(
      refresh(
        query: _state.query.copyWith(buscar: '', page: 1),
        reason: 'clear-search',
      ),
    );
  }

  Future<void> applySearch(String value, {String reason = 'submit-search'}) {
    final term = value.trim();
    _searchDebounce?.cancel();
    _setSearchText(term);
    _log('applied query changed buscar="$term" reason=$reason');
    _setState(
      _state.copyWith(
        suggestions: const [],
        showSuggestions: false,
        isLoadingSuggestions: false,
      ),
    );

    return refresh(
      query: _state.query.copyWith(buscar: term, page: 1),
      reason: reason,
    );
  }

  Future<void> setActivoFilter(bool? activo) {
    final nextQuery = activo == null
        ? _state.query.copyWith(page: 1, clearActivo: true)
        : _state.query.copyWith(activo: activo, page: 1);
    _log('filter activo=${activo?.toString() ?? "all"}');
    return refresh(query: nextQuery, reason: 'filter-activo');
  }

  Future<void> setOrden(String orden) {
    _log('sort field=$orden');
    return refresh(
      query: _state.query.copyWith(orden: orden, page: 1),
      reason: 'sort-field',
    );
  }

  Future<void> setDireccion(String direccion) {
    _log('sort direction=$direccion');
    return refresh(
      query: _state.query.copyWith(direccion: direccion, page: 1),
      reason: 'sort-direction',
    );
  }

  Future<void> setCategoriaFilter(int? categoriaId) {
    final nextQuery = categoriaId == null
        ? _state.query.copyWith(page: 1, clearCategoriaId: true)
        : _state.query.copyWith(categoriaId: categoriaId, page: 1);
    _log('filter categoria_id=${categoriaId?.toString() ?? "all"}');
    return refresh(query: nextQuery, reason: 'filter-categoria');
  }

  Future<void> goToPage(int page) {
    _log('page changed page=$page');
    return refresh(
      query: _state.query.copyWith(page: page),
      reason: 'pagination',
    );
  }

  Future<void> refreshAfterMutation({
    required String reason,
    Producto? producto,
  }) async {
    if (producto != null) {
      _log(
        'product mutation reason=$reason id=${producto.id} codigo=${producto.codigo}',
      );
    } else {
      _log('product mutation reason=$reason');
    }

    await refresh(silent: true, reason: reason);
  }

  Future<Producto> toggleActivo(Producto producto) async {
    _log('toggle activo start id=${producto.id}');
    final updated = await repository.toggleActivo(producto.id);
    await refreshAfterMutation(reason: 'toggle-activo', producto: updated);
    return updated;
  }

  Future<void> refresh({
    ProductosQuery? query,
    bool silent = true,
    String reason = 'manual',
  }) async {
    final nextQuery = query ?? _state.query;

    if (_state.isRefreshing) {
      _queuedQuery = nextQuery;
      _refreshQueued = true;
      if (!_queriesEqual(_state.query, nextQuery)) {
        _setState(_state.copyWith(query: nextQuery));
      }
      _log('refresh queued reason=$reason query=${nextQuery.toQueryString()}');
      return;
    }

    if (!_queriesEqual(_state.query, nextQuery)) {
      _setState(_state.copyWith(query: nextQuery));
    }

    final requestQuery = _state.query;
    final requestId = ++_refreshRequestId;
    _setState(
      _state.copyWith(
        isRefreshing: true,
        isInitialLoading: _state.response == null,
        loadError: silent ? _state.loadError : null,
      ),
    );
    if (!silent) {
      _setState(_state.copyWith(loadError: null));
    }

    _log(
      'refresh start reason=$reason request=$requestId query=${requestQuery.toQueryString()}',
    );

    try {
      final response = await repository.fetchProductos(requestQuery);
      if (_isDisposed) return;

      if (requestId != _refreshRequestId ||
          !_queriesEqual(_state.query, requestQuery)) {
        _log(
          'refresh ignored stale reason=$reason request=$requestId current=$_refreshRequestId',
        );
        return;
      }

      final hasChanged = !_responsesEqual(_state.response, response);
      _log(
        'refresh success reason=$reason request=$requestId changed=$hasChanged items=${response.items.length} total=${response.total}',
      );

      _setState(
        _state.copyWith(
          response: response,
          loadError: null,
          isInitialLoading: false,
          isRefreshing: false,
        ),
        notify:
            hasChanged || _state.response == null || _state.loadError != null,
      );
    } catch (error) {
      if (_isDisposed) return;

      if (requestId != _refreshRequestId ||
          !_queriesEqual(_state.query, requestQuery)) {
        _log(
          'refresh error ignored stale reason=$reason request=$requestId',
        );
        return;
      }

      _log('refresh error reason=$reason request=$requestId error=$error');
      _setState(
        _state.copyWith(
          loadError: _state.response == null ? error : _state.loadError,
          isInitialLoading: false,
          isRefreshing: false,
        ),
        notify: _state.response == null,
      );
    } finally {
      if (!_isDisposed) {
        if (_state.isRefreshing && requestId == _refreshRequestId) {
          _setState(_state.copyWith(isRefreshing: false));
        }

        if (_refreshQueued) {
          final queuedQuery = _queuedQuery;
          _refreshQueued = false;
          _queuedQuery = null;
          unawaited(
            refresh(
              query: queuedQuery,
              reason: 'queued-refresh',
            ),
          );
        }
      }
    }
  }

  Future<void> _loadSuggestions(String term) async {
    final requestId = ++_suggestionRequestId;
    _log('suggestions start request=$requestId term="$term"');
    _setState(
      _state.copyWith(
        isLoadingSuggestions: true,
        showSuggestions: true,
      ),
    );

    try {
      final suggestions = await repository.fetchSuggestions(term);
      if (_isDisposed || requestId != _suggestionRequestId) {
        _log('suggestions ignored stale request=$requestId term="$term"');
        return;
      }

      _log(
          'suggestions success request=$requestId count=${suggestions.length}');
      _setState(
        _state.copyWith(
          suggestions: suggestions,
          isLoadingSuggestions: false,
          showSuggestions: true,
        ),
      );
    } catch (error) {
      if (_isDisposed || requestId != _suggestionRequestId) {
        _log('suggestions error ignored stale request=$requestId term="$term"');
        return;
      }

      _log('suggestions error request=$requestId error=$error');
      _setState(
        _state.copyWith(
          suggestions: const [],
          isLoadingSuggestions: false,
          showSuggestions: true,
        ),
      );
    }
  }

  void _onSearchFocusChanged() {
    _notify();
    if (searchFocusNode.hasFocus) return;
    if (_shouldPauseAutoRefresh()) return;
    unawaited(refresh(reason: 'focus-lost'));
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(_pollingInterval, (_) {
      if (_isDisposed || _pollingPaused || _shouldPauseAutoRefresh()) {
        if (!_isDisposed && (_pollingPaused || _shouldPauseAutoRefresh())) {
          _log('polling skipped paused=true');
        }
        return;
      }

      _log('polling tick');
      unawaited(refresh(reason: 'polling'));
    });
  }

  bool _shouldPauseAutoRefresh() {
    return searchFocusNode.hasFocus &&
        _state.searchText.trim() != _state.query.buscar;
  }

  void pausePolling() {
    _pollingPaused = true;
    _log('polling paused');
  }

  void resumePolling() {
    _pollingPaused = false;
    _log('polling resumed');
  }

  void _setSearchText(String value) {
    if (_state.searchText == value && searchController.text == value) {
      return;
    }

    _syncSearchController(value);
    _setState(_state.copyWith(searchText: value));
  }

  void _syncSearchController(String value) {
    if (searchController.text == value) {
      return;
    }

    searchController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  bool _responsesEqual(
    PaginatedProductosResponse? previous,
    PaginatedProductosResponse next,
  ) {
    if (previous == null) return false;
    if (identical(previous, next)) return true;
    if (previous.currentPage != next.currentPage ||
        previous.lastPage != next.lastPage ||
        previous.total != next.total ||
        previous.items.length != next.items.length) {
      return false;
    }

    for (var i = 0; i < previous.items.length; i++) {
      if (!_sameProducto(previous.items[i], next.items[i])) {
        return false;
      }
    }

    return true;
  }

  bool _sameProducto(Producto left, Producto right) {
    return left.id == right.id &&
        left.codigo == right.codigo &&
        left.nombre == right.nombre &&
        left.precioVenta == right.precioVenta &&
        left.stock == right.stock &&
        left.unidadMedida == right.unidadMedida &&
        left.activo == right.activo;
  }

  bool _queriesEqual(ProductosQuery left, ProductosQuery right) {
    return left.buscar == right.buscar &&
        left.page == right.page &&
        left.orden == right.orden &&
        left.direccion == right.direccion &&
        left.activo == right.activo &&
        left.categoriaId == right.categoriaId &&
        left.perPage == right.perPage;
  }

  void _setState(ProductosState nextState, {bool notify = true}) {
    _state = nextState;
    if (notify) {
      _notify();
    }
  }

  void _notify() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  void _log(String message) {
    debugPrint('[ProductosController] $message');
  }

  @override
  void dispose() {
    _isDisposed = true;
    _searchDebounce?.cancel();
    _pollingTimer?.cancel();
    searchFocusNode
      ..removeListener(_onSearchFocusChanged)
      ..dispose();
    searchController.dispose();
    super.dispose();
  }
}
