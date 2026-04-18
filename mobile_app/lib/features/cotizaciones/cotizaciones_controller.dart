import 'dart:async';

import 'package:flutter/material.dart';

import 'data/cotizaciones_query.dart';
import 'data/cotizaciones_repository.dart';
import 'data/paginated_cotizaciones_response.dart';
import 'domain/cotizacion.dart';
import '../servicios/domain/servicio.dart';
import 'cotizaciones_state.dart';

class CotizacionesController extends ChangeNotifier {
  CotizacionesController({
    required this.repository,
    required Duration pollingInterval,
  }) : _pollingInterval = pollingInterval;

  final CotizacionesRepository repository;
  final Duration _pollingInterval;

  final searchController = TextEditingController();
  final searchFocusNode = FocusNode();

  CotizacionesState _state = const CotizacionesState.initial();
  Timer? _searchDebounce;
  Timer? _pollingTimer;
  CotizacionesQuery? _queuedQuery;
  bool _refreshQueued = false;
  int _refreshRequestId = 0;
  bool _isDisposed = false;

  CotizacionesState get state => _state;

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

  Future<Cotizacion> fetchCotizacion(int id) => repository.fetchCotizacion(id);

  Future<List<Servicio>> ensureCatalogoServiciosLoaded({
    bool forceRefresh = false,
    bool notifyListeners = true,
  }) async {
    if (!forceRefresh && _state.catalogoServicios.isNotEmpty) {
      return _state.catalogoServicios;
    }

    _setState(
      _state.copyWith(
        isLoadingCatalogoServicios: true,
        catalogoServiciosError: null,
      ),
      notify: notifyListeners,
    );

    try {
      final servicios = await repository.fetchServiciosDisponibles();
      if (_isDisposed) {
        return const [];
      }

      _setState(
        _state.copyWith(
          catalogoServicios: servicios,
          isLoadingCatalogoServicios: false,
          catalogoServiciosError: null,
        ),
        notify: notifyListeners,
      );
      return servicios;
    } catch (error) {
      if (_isDisposed) {
        return const [];
      }

      _setState(
        _state.copyWith(
          isLoadingCatalogoServicios: false,
          catalogoServiciosError: error,
        ),
        notify: notifyListeners,
      );
      rethrow;
    }
  }

  Future<Cotizacion> createCotizacion(Map<String, dynamic> payload) async {
    final created = await repository.createCotizacion(payload);
    Cotizacion cotizacion = created;

    try {
      cotizacion = await repository.fetchCotizacion(created.id);
    } catch (_) {
      cotizacion = created;
    }

    _insertCreatedCotizacion(cotizacion);
    unawaited(refreshAfterMutation(reason: 'create-cotizacion'));
    return cotizacion;
  }

  Future<Cotizacion> updateCotizacion(
    int id,
    Map<String, dynamic> payload,
  ) async {
    final cotizacion = await repository.updateCotizacion(id, payload);
    await refreshAfterMutation(reason: 'update-cotizacion');
    return cotizacion;
  }

  Future<Cotizacion> anularCotizacion(Cotizacion cotizacion) async {
    final updated = await repository.marcarNula(cotizacion.id);
    await refreshAfterMutation(reason: 'marcar-nula');
    return updated;
  }

  Future<Cotizacion> marcarRealizada(Cotizacion cotizacion) async {
    final updated = await repository.marcarRealizada(cotizacion.id);
    await refreshAfterMutation(reason: 'marcar-realizada');
    return updated;
  }

  Future<void> refreshAfterMutation({required String reason}) async {
    await refresh(silent: true, reason: reason);
  }

  Future<void> refresh({
    CotizacionesQuery? query,
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
      final response = await repository.fetchCotizaciones(requestQuery);
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
    PaginatedCotizacionesResponse? previous,
    PaginatedCotizacionesResponse next,
  ) {
    if (previous == null) return false;
    if (identical(previous, next)) return true;
    if (previous.currentPage != next.currentPage ||
        previous.lastPage != next.lastPage ||
        previous.total != next.total ||
        previous.stats.total != next.stats.total ||
        previous.stats.pendiente != next.stats.pendiente ||
        previous.stats.visto != next.stats.visto ||
        previous.stats.realizada != next.stats.realizada ||
        previous.stats.nula != next.stats.nula ||
        previous.items.length != next.items.length) {
      return false;
    }

    for (var i = 0; i < previous.items.length; i++) {
      if (!_sameCotizacion(previous.items[i], next.items[i])) {
        return false;
      }
    }

    return true;
  }

  bool _sameCotizacion(Cotizacion left, Cotizacion right) {
    return left.id == right.id &&
        left.numero == right.numero &&
        left.codigo == right.codigo &&
        left.fecha == right.fecha &&
        left.ciudad == right.ciudad &&
        left.clienteNombre == right.clienteNombre &&
        left.referencia == right.referencia &&
        left.subtotal == right.subtotal &&
        left.total == right.total &&
        left.estado == right.estado;
  }

  bool _queriesEqual(CotizacionesQuery left, CotizacionesQuery right) {
    return left.buscar == right.buscar &&
        left.estado == right.estado &&
        left.page == right.page &&
        left.orden == right.orden &&
        left.direccion == right.direccion &&
        left.perPage == right.perPage;
  }

  void _insertCreatedCotizacion(Cotizacion cotizacion) {
    final response = _state.response;
    if (response == null || response.currentPage != 1) {
      return;
    }

    if (!_matchesCurrentQuery(cotizacion)) {
      return;
    }

    final items = <Cotizacion>[
      cotizacion,
      ...response.items.where((item) => item.id != cotizacion.id),
    ];
    final limitedItems = items.take(_state.query.perPage).toList();
    final stats = _incrementStatsForCreated(response.stats, cotizacion.estado);

    _setState(
      _state.copyWith(
        response: PaginatedCotizacionesResponse(
          items: limitedItems,
          currentPage: response.currentPage,
          lastPage: response.lastPage,
          total: response.total + 1,
          stats: stats,
        ),
      ),
    );
  }

  bool _matchesCurrentQuery(Cotizacion cotizacion) {
    final estado = _state.query.estado.trim().toLowerCase();
    if (estado.isNotEmpty && cotizacion.estado.toLowerCase() != estado) {
      return false;
    }

    final buscar = _state.query.buscar.trim().toLowerCase();
    if (buscar.isEmpty) {
      return true;
    }

    final hayMatch = [
      cotizacion.codigo,
      cotizacion.numero,
      cotizacion.clienteNombre,
      cotizacion.ciudad,
      cotizacion.referencia,
    ].any((value) => value.toLowerCase().contains(buscar));

    return hayMatch;
  }

  CotizacionesStats _incrementStatsForCreated(
    CotizacionesStats stats,
    String estado,
  ) {
    final normalized = estado.trim().toLowerCase();
    return CotizacionesStats(
      total: stats.total + 1,
      pendiente: stats.pendiente + (normalized == 'pendiente' ? 1 : 0),
      visto: stats.visto + (normalized == 'visto' ? 1 : 0),
      realizada: stats.realizada + (normalized == 'realizada' ? 1 : 0),
      nula: stats.nula + (normalized == 'nula' ? 1 : 0),
    );
  }

  void _setState(CotizacionesState nextState, {bool notify = true}) {
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
