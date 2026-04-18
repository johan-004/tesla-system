import 'dart:async';

import 'package:flutter/material.dart';

import '../data/paginated_servicios_response.dart';
import '../data/servicios_query.dart';
import '../data/servicios_repository.dart';
import '../domain/servicio.dart';
import 'servicios_state.dart';

class ServiciosController extends ChangeNotifier {
  ServiciosController({
    required this.repository,
    required Duration pollingInterval,
  }) : _pollingInterval = pollingInterval;

  final ServiciosRepository repository;
  final Duration _pollingInterval;

  final searchController = TextEditingController();
  final searchFocusNode = FocusNode();

  ServiciosState _state = const ServiciosState.initial();
  Timer? _searchDebounce;
  Timer? _pollingTimer;
  ServiciosQuery? _queuedQuery;
  bool _refreshQueued = false;
  int _refreshRequestId = 0;
  bool _isDisposed = false;

  ServiciosState get state => _state;

  void initialize() {
    _syncSearchController(_state.searchText);
    searchFocusNode.addListener(_onSearchFocusChanged);
    unawaited(_loadAvailableCategories());
    unawaited(refresh(silent: false, reason: 'initialize'));
    _startPolling();
  }

  void onSearchDraftChanged(String value) {
    _searchDebounce?.cancel();
    _setState(_state.copyWith(searchText: value));

    _searchDebounce = Timer(const Duration(milliseconds: 320), () {
      if (value.trim() == _state.query.buscar) {
        return;
      }

      unawaited(applySearch(value, reason: 'debounced-search'));
    });
  }

  Future<void> applySearch(String value, {String reason = 'submit-search'}) {
    final term = value.trim();
    _searchDebounce?.cancel();
    _setSearchText(term);

    return refresh(
      query: _state.query.copyWith(buscar: term, page: 1),
      reason: reason,
    );
  }

  Future<void> clearSearch() {
    _searchDebounce?.cancel();
    _setSearchText('');

    return refresh(
      query: _state.query.copyWith(buscar: '', page: 1),
      reason: 'clear-search',
    );
  }

  Future<void> setCategoriaFilter(String? categoria) {
    final normalizedCategoria = normalizeServiceCategory(categoria);
    final nextQuery = normalizedCategoria.isEmpty
        ? _state.query.copyWith(page: 1, clearCategoria: true)
        : _state.query.copyWith(categoria: normalizedCategoria, page: 1);

    return refresh(query: nextQuery, reason: 'filter-categoria');
  }

  Future<void> setActivoFilter(bool? activo) {
    final nextQuery = activo == null
        ? _state.query.copyWith(page: 1, clearActivo: true)
        : _state.query.copyWith(activo: activo, page: 1);

    return refresh(query: nextQuery, reason: 'filter-activo');
  }

  Future<void> setOrden(String orden) {
    return refresh(
      query: _state.query.copyWith(orden: orden, page: 1),
      reason: 'sort-field',
    );
  }

  Future<void> setDireccion(String direccion) {
    return refresh(
      query: _state.query.copyWith(direccion: direccion, page: 1),
      reason: 'sort-direction',
    );
  }

  Future<void> goToPage(int page) {
    return refresh(
      query: _state.query.copyWith(page: page),
      reason: 'pagination',
    );
  }

  Future<void> refreshAfterMutation({
    required String reason,
    Servicio? servicio,
  }) async {
    if (servicio != null) {
      _log('service mutation reason=$reason id=${servicio.id}');
    }

    await refresh(silent: true, reason: reason);
  }

  Future<Servicio> toggleActivo(Servicio servicio) async {
    final updated = await repository.toggleActivo(servicio.id);
    await refreshAfterMutation(reason: 'toggle-activo', servicio: updated);

    return updated;
  }

  Future<void> refresh({
    ServiciosQuery? query,
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

    try {
      final response = await repository.fetchServicios(requestQuery);
      if (_isDisposed) return;

      if (requestId != _refreshRequestId ||
          !_queriesEqual(_state.query, requestQuery)) {
        return;
      }

      final hasChanged = !_responsesEqual(_state.response, response);
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
        return;
      }

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

  Future<void> _loadAvailableCategories() async {
    try {
      final categories = await repository.fetchCategorias();
      if (_isDisposed) return;

      final currentCategory = _state.query.categoria;
      final nextCategories = [
        ...categories,
        if (currentCategory.isNotEmpty && !categories.contains(currentCategory))
          currentCategory,
      ];

      _setState(
        _state.copyWith(availableCategories: nextCategories),
        notify: false,
      );
      _notify();
    } catch (_) {
      if (_isDisposed) return;
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
      if (_isDisposed || _shouldPauseAutoRefresh()) {
        return;
      }

      unawaited(refresh(reason: 'polling'));
    });
  }

  bool _shouldPauseAutoRefresh() {
    return searchFocusNode.hasFocus &&
        _state.searchText.trim() != _state.query.buscar;
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
    PaginatedServiciosResponse? previous,
    PaginatedServiciosResponse next,
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
      if (!_sameServicio(previous.items[i], next.items[i])) {
        return false;
      }
    }

    return true;
  }

  bool _sameServicio(Servicio left, Servicio right) {
    return left.id == right.id &&
        left.codigo == right.codigo &&
        left.descripcion == right.descripcion &&
        left.categoria == right.categoria &&
        left.unidad == right.unidad &&
        left.precioUnitario == right.precioUnitario &&
        left.iva == right.iva &&
        left.precioConIva == right.precioConIva &&
        left.observaciones == right.observaciones &&
        left.activo == right.activo;
  }

  bool _queriesEqual(ServiciosQuery left, ServiciosQuery right) {
    return left.buscar == right.buscar &&
        left.categoria == right.categoria &&
        left.page == right.page &&
        left.orden == right.orden &&
        left.direccion == right.direccion &&
        left.activo == right.activo &&
        left.perPage == right.perPage;
  }

  void _setState(ServiciosState nextState, {bool notify = true}) {
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
    debugPrint('[ServiciosController] $message');
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
