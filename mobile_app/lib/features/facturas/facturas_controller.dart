import 'dart:async';

import 'package:flutter/material.dart';

import '../productos/domain/producto.dart';
import 'data/facturas_query.dart';
import 'data/facturas_repository.dart';
import 'data/paginated_facturas_response.dart';
import 'domain/factura.dart';
import 'facturas_state.dart';

class FacturasController extends ChangeNotifier {
  FacturasController({
    required this.repository,
    required Duration pollingInterval,
  }) : _pollingInterval = pollingInterval;

  final FacturasRepository repository;
  final Duration _pollingInterval;

  final searchController = TextEditingController();
  final searchFocusNode = FocusNode();

  FacturasState _state = const FacturasState.initial();
  Timer? _searchDebounce;
  Timer? _pollingTimer;
  FacturasQuery? _queuedQuery;
  bool _refreshQueued = false;
  int _refreshRequestId = 0;
  bool _isDisposed = false;

  FacturasState get state => _state;

  void initialize() {
    _syncSearchController(_state.searchText);
    searchFocusNode.addListener(_onSearchFocusChanged);
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

  Future<void> setEstadoFilter(String? estado) {
    final normalized = (estado ?? '').trim();
    final nextQuery = normalized.isEmpty
        ? _state.query.copyWith(page: 1, clearEstado: true)
        : _state.query.copyWith(estado: normalized, page: 1);

    return refresh(query: nextQuery, reason: 'filter-estado');
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

  Future<Factura> fetchFactura(int id) => repository.fetchFactura(id);

  Future<List<Producto>> ensureCatalogoProductosLoaded({
    bool forceRefresh = false,
    bool notifyListeners = true,
  }) async {
    if (!forceRefresh && _state.catalogoProductos.isNotEmpty) {
      return _state.catalogoProductos;
    }

    _setState(
      _state.copyWith(
        isLoadingCatalogoProductos: true,
        catalogoProductosError: null,
      ),
      notify: notifyListeners,
    );

    try {
      final productos = await repository.fetchProductosDisponibles();
      if (_isDisposed) {
        return const [];
      }

      _setState(
        _state.copyWith(
          catalogoProductos: productos,
          isLoadingCatalogoProductos: false,
          catalogoProductosError: null,
        ),
        notify: notifyListeners,
      );
      return productos;
    } catch (error) {
      if (_isDisposed) {
        return const [];
      }

      _setState(
        _state.copyWith(
          isLoadingCatalogoProductos: false,
          catalogoProductosError: error,
        ),
        notify: notifyListeners,
      );
      rethrow;
    }
  }

  Future<Factura> createFactura(Map<String, dynamic> payload) async {
    final created = await repository.createFactura(payload);
    await refreshAfterMutation(reason: 'create-factura');
    return created;
  }

  Future<Factura> updateFactura(int id, Map<String, dynamic> payload) async {
    final updated = await repository.updateFactura(id, payload);
    await refreshAfterMutation(reason: 'update-factura');
    return updated;
  }

  Future<Factura> emitirFactura(Factura factura) async {
    final updated = await repository.emitirFactura(factura.id);
    await refreshAfterMutation(reason: 'emitir-factura');
    return updated;
  }

  Future<void> refreshAfterMutation({required String reason}) async {
    await refresh(silent: true, reason: reason);
  }

  Future<void> refresh({
    FacturasQuery? query,
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
      final response = await repository.fetchFacturas(requestQuery);
      if (_isDisposed) {
        return;
      }

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
      if (_isDisposed) {
        return;
      }

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

  void _onSearchFocusChanged() {
    _notify();
    if (searchFocusNode.hasFocus) {
      return;
    }
    if (_shouldPauseAutoRefresh()) {
      return;
    }
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
    PaginatedFacturasResponse? previous,
    PaginatedFacturasResponse next,
  ) {
    if (previous == null) {
      return false;
    }
    if (identical(previous, next)) {
      return true;
    }
    if (previous.currentPage != next.currentPage ||
        previous.lastPage != next.lastPage ||
        previous.total != next.total ||
        previous.stats.total != next.stats.total ||
        previous.stats.borrador != next.stats.borrador ||
        previous.stats.emitida != next.stats.emitida ||
        previous.stats.anulada != next.stats.anulada ||
        previous.items.length != next.items.length) {
      return false;
    }

    for (var i = 0; i < previous.items.length; i++) {
      if (!_sameFactura(previous.items[i], next.items[i])) {
        return false;
      }
    }

    return true;
  }

  bool _sameFactura(Factura left, Factura right) {
    return left.id == right.id &&
        left.codigo == right.codigo &&
        left.fecha == right.fecha &&
        left.clienteNombre == right.clienteNombre &&
        left.subtotal == right.subtotal &&
        left.ivaTotal == right.ivaTotal &&
        left.total == right.total &&
        left.estado == right.estado;
  }

  bool _queriesEqual(FacturasQuery left, FacturasQuery right) {
    return left.buscar == right.buscar &&
        left.estado == right.estado &&
        left.page == right.page &&
        left.orden == right.orden &&
        left.direccion == right.direccion &&
        left.perPage == right.perPage;
  }

  void _setState(FacturasState nextState, {bool notify = true}) {
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
