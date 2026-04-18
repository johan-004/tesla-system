import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../core/layout/adaptive_layout.dart';
import '../../../shared/utils/price_formatter.dart';
import '../data/paginated_productos_response.dart';
import '../data/productos_query.dart';
import '../data/productos_repository.dart';
import '../domain/producto.dart';
import 'productos_controller.dart';
import 'productos_state.dart';
import 'producto_form_screen.dart';

class ProductosScreen extends StatefulWidget {
  const ProductosScreen({
    super.key,
    required this.authController,
    this.embedded = false,
  });

  final AuthController authController;
  final bool embedded;

  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {
  static const _pollingInterval = Duration(seconds: 5);
  static const _slate900 = Color(0xFF0F172A);
  static const _slate700 = Color(0xFF334155);
  static const _slate500 = Color(0xFF64748B);
  static const _slate300 = Color(0xFFCBD5E1);
  static const _slate200 = Color(0xFFE2E8F0);
  static const _slate100 = Color(0xFFF1F5F9);
  static const _emerald600 = Color(0xFF059669);
  static const _emerald500 = Color(0xFF10B981);
  static const _emerald100 = Color(0xFFD1FAE5);
  static const _rose600 = Color(0xFFE11D48);
  static const _rose100 = Color(0xFFFFE4E6);
  static const _amber100 = Color(0xFFFEF3C7);
  static const _amber800 = Color(0xFF92400E);

  late final ProductosController _controller;

  ProductosRepository get _repository => _controller.repository;
  TextEditingController get _searchController => _controller.searchController;
  FocusNode get _searchFocusNode => _controller.searchFocusNode;
  ProductosState get _state => _controller.state;
  ProductosQuery get _query => _state.query;
  List<Producto> get _suggestions => _state.suggestions;
  bool get _isLoadingSuggestions => _state.isLoadingSuggestions;
  bool get _showSuggestions => _state.showSuggestions;
  bool get _isInitialLoading => _state.isInitialLoading;
  PaginatedProductosResponse? get _response => _state.response;
  Object? get _loadError => _state.loadError;
  bool get _canCreateProductos => widget.authController.canCreateProductos;
  bool get _canEditProductos => widget.authController.canEditProductos;
  bool get _canToggleProductos => widget.authController.canToggleProductos;

  @override
  void initState() {
    super.initState();
    _controller = ProductosController(
      repository: ProductosRepository(
        ApiClient(token: widget.authController.token),
      ),
      pollingInterval: _pollingInterval,
    )..initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = AdaptiveLayout.isDesktopWidth(constraints.maxWidth);
        final content = AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => SafeArea(
            child: _buildBody(isDesktop),
          ),
        );

        if (widget.embedded) {
          return ColoredBox(color: _slate100, child: content);
        }

        return Scaffold(
          backgroundColor: _slate100,
          body: content,
        );
      },
    );
  }

  Widget _buildBody(bool isDesktop) {
    if (_isInitialLoading && _response == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null && _response == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Error cargando productos: $_loadError',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final response = _response!;
    return isDesktop
        ? _buildDesktopLayout(response)
        : _buildMobileLayout(response);
  }

  Widget _buildMobileLayout(PaginatedProductosResponse response) {
    final productos = response.items;

    return RefreshIndicator(
      color: _emerald600,
      onRefresh: () async => _refresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
        children: [
          _buildHero(response),
          const SizedBox(height: 16),
          _buildFiltersCard(),
          const SizedBox(height: 16),
          if (productos.isEmpty)
            _buildEmptyState()
          else ...[
            for (final producto in productos) ...[
              _buildProductCard(producto),
              const SizedBox(height: 12),
            ],
          ],
          _buildPaginationCard(response),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(PaginatedProductosResponse response) {
    final productos = response.items;

    return RefreshIndicator(
      color: _emerald600,
      onRefresh: () async => _refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(32, 28, 32, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildDesktopHeader(response),
                const SizedBox(height: 24),
                _buildDesktopFiltersCard(),
                const SizedBox(height: 24),
                if (productos.isEmpty)
                  _buildEmptyState()
                else
                  _buildDesktopTableCard(productos),
                const SizedBox(height: 18),
                _buildDesktopPagination(response),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero(PaginatedProductosResponse response) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF134E4A), Color(0xFF0F766E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x260F172A),
            blurRadius: 28,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            ),
            child: const Text(
              'EXPERIENCIA MOVIL',
              style: TextStyle(
                color: Color(0xFFE2E8F0),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Productos',
            style: TextStyle(
              color: Colors.white,
              fontSize: 31,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Consulta, filtra y administra el catalogo con una interfaz movil mas pulida y coherente con el sistema.',
            style: TextStyle(
              color: Color(0xFFE2E8F0),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _canCreateProductos
                    ? FilledButton.icon(
                        onPressed: _openCreateForm,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: _slate900,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text(
                          'Nuevo producto',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      )
                    : _buildReadonlyAccessCard(),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(18),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.12)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pagina',
                      style: TextStyle(
                        color: Color(0xFFBFDBFE),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${response.currentPage}/${response.lastPage}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildHeroMetric(
                  label: 'Visibles',
                  value: '${response.items.length}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildHeroMetric(
                  label: 'Total',
                  value: '${response.total}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildHeroMetric(
                  label: 'Orden',
                  value: _formatOrder(_query.orden),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroMetric({
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFBFDBFE),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _slate200),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 20,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: Color(0xFF047857),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Buscar y filtrar',
                  style: TextStyle(
                    color: _slate900,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Busca por codigo o nombre y combina estado, orden y direccion con controles tactiles mas claros.',
            style: TextStyle(
              color: _slate500,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            onChanged: _onSearchChanged,
            onSubmitted: (value) => _applySearch(value),
            decoration: InputDecoration(
              labelText: 'Buscar producto',
              hintText: 'Ejemplo: MAT-010 o cable',
              filled: true,
              fillColor: _slate100,
              prefixIcon: const Icon(Icons.search_rounded, color: _slate700),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_state.hasDraftSearch)
                    IconButton(
                      onPressed: _clearSearch,
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'Limpiar',
                    ),
                  IconButton(
                    onPressed: () => _applySearch(_searchController.text),
                    icon: const Icon(Icons.arrow_forward_rounded),
                    tooltip: 'Buscar',
                  ),
                ],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(color: _slate300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(color: _slate300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(color: _emerald500, width: 1.6),
              ),
            ),
          ),
          if (_state.hasDraftSearch) ...[
            const SizedBox(height: 12),
            _buildSuggestionsPanel(),
          ],
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildStateChip(
                label: 'Todos',
                selected: _query.activo == null,
                backgroundColor: _slate900,
                foregroundColor: Colors.white,
                inactiveColor: _slate100,
                inactiveForeground: _slate700,
                onTap: () => unawaited(_controller.setActivoFilter(null)),
              ),
              _buildStateChip(
                label: 'Activos',
                selected: _query.activo == true,
                backgroundColor: _emerald600,
                foregroundColor: Colors.white,
                inactiveColor: const Color(0xFFECFDF5),
                inactiveForeground: const Color(0xFF047857),
                onTap: () => unawaited(_controller.setActivoFilter(true)),
              ),
              _buildStateChip(
                label: 'Inactivos',
                selected: _query.activo == false,
                backgroundColor: _rose600,
                foregroundColor: Colors.white,
                inactiveColor: _rose100,
                inactiveForeground: const Color(0xFFBE123C),
                onTap: () => unawaited(_controller.setActivoFilter(false)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  label: 'Ordenar por',
                  value: _query.orden,
                  items: const [
                    DropdownMenuItem(value: 'codigo', child: Text('Codigo')),
                    DropdownMenuItem(value: 'nombre', child: Text('Nombre')),
                    DropdownMenuItem(value: 'stock', child: Text('Stock')),
                    DropdownMenuItem(
                        value: 'precio_venta', child: Text('Precio')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      unawaited(_controller.setOrden(value));
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdown(
                  label: 'Direccion',
                  value: _query.direccion,
                  items: const [
                    DropdownMenuItem(value: 'asc', child: Text('Ascendente')),
                    DropdownMenuItem(value: 'desc', child: Text('Descendente')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      unawaited(_controller.setDireccion(value));
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopHeader(PaginatedProductosResponse response) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF134E4A), Color(0xFF0F766E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F0F172A),
            blurRadius: 30,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.14)),
                  ),
                  child: const Text(
                    'Modulo escritorio',
                    style: TextStyle(
                      color: Color(0xFFE2E8F0),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Productos',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                const SizedBox(
                  width: 720,
                  child: Text(
                    'Administra el catalogo con una vista de escritorio mas ordenada: busqueda horizontal, tabla alineada, estados claros y acciones directas.',
                    style: TextStyle(
                      color: Color(0xFFE2E8F0),
                      height: 1.5,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _canCreateProductos
                  ? FilledButton.icon(
                      onPressed: _openCreateForm,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: _slate900,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text(
                        'Nuevo producto',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    )
                  : _buildDesktopReadonlyPill(),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.end,
                children: [
                  _buildHeaderStat(
                    icon: Icons.inventory_2_outlined,
                    label: 'Total',
                    value: '${response.total}',
                  ),
                  _buildHeaderStat(
                    icon: Icons.view_week_outlined,
                    label: 'Pagina',
                    value: '${response.currentPage}/${response.lastPage}',
                  ),
                  _buildHeaderStat(
                    icon: Icons.sort_by_alpha_rounded,
                    label: 'Orden',
                    value: _formatOrder(_query.orden),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 140),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFBFDBFE),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopFiltersCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _slate200),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Busqueda y filtros',
                      style: TextStyle(
                        color: _slate900,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Filtra por estado, orden y direccion sin perder el contexto de la tabla.',
                      style: TextStyle(
                        color: _slate500,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              _buildStateSegmentedControl(),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      onChanged: _onSearchChanged,
                      onSubmitted: (value) => _applySearch(value),
                      decoration: InputDecoration(
                        labelText: 'Buscar producto',
                        hintText: 'Ejemplo: MAT-010 o cable',
                        filled: true,
                        fillColor: _slate100,
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_state.hasDraftSearch)
                              IconButton(
                                onPressed: _clearSearch,
                                icon: const Icon(Icons.close_rounded),
                                tooltip: 'Limpiar',
                              ),
                            IconButton(
                              onPressed: () =>
                                  _applySearch(_searchController.text),
                              icon: const Icon(Icons.arrow_forward_rounded),
                              tooltip: 'Buscar',
                            ),
                          ],
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: _slate300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: _slate300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide:
                              const BorderSide(color: _emerald500, width: 1.4),
                        ),
                      ),
                    ),
                    if (_state.hasDraftSearch) ...[
                      const SizedBox(height: 12),
                      _buildSuggestionsPanel(),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: _buildDropdown(
                  label: 'Ordenar por',
                  value: _query.orden,
                  items: const [
                    DropdownMenuItem(value: 'codigo', child: Text('Codigo')),
                    DropdownMenuItem(value: 'nombre', child: Text('Nombre')),
                    DropdownMenuItem(value: 'stock', child: Text('Stock')),
                    DropdownMenuItem(
                        value: 'precio_venta', child: Text('Precio')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      unawaited(_controller.setOrden(value));
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: _buildDropdown(
                  label: 'Direccion',
                  value: _query.direccion,
                  items: const [
                    DropdownMenuItem(value: 'asc', child: Text('Ascendente')),
                    DropdownMenuItem(value: 'desc', child: Text('Descendente')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      unawaited(_controller.setDireccion(value));
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStateSegmentedControl() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildStateChip(
          label: 'Todos',
          selected: _query.activo == null,
          backgroundColor: _slate900,
          foregroundColor: Colors.white,
          inactiveColor: _slate100,
          inactiveForeground: _slate700,
          onTap: () => unawaited(_controller.setActivoFilter(null)),
        ),
        _buildStateChip(
          label: 'Activos',
          selected: _query.activo == true,
          backgroundColor: _emerald600,
          foregroundColor: Colors.white,
          inactiveColor: const Color(0xFFECFDF5),
          inactiveForeground: const Color(0xFF047857),
          onTap: () => unawaited(_controller.setActivoFilter(true)),
        ),
        _buildStateChip(
          label: 'Inactivos',
          selected: _query.activo == false,
          backgroundColor: _rose600,
          foregroundColor: Colors.white,
          inactiveColor: _rose100,
          inactiveForeground: const Color(0xFFBE123C),
          onTap: () => unawaited(_controller.setActivoFilter(false)),
        ),
      ],
    );
  }

  Widget _buildSuggestionsPanel() {
    final term = _state.searchText.trim();

    if (!_showSuggestions && !_isLoadingSuggestions) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _slate200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: _isLoadingSuggestions
            ? const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('Buscando productos...'),
                  ],
                ),
              )
            : _suggestions.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      term.isEmpty ? '' : 'No se encontraron productos.',
                      style: const TextStyle(color: _slate500),
                    ),
                  )
                : Column(
                    children: [
                      for (var i = 0; i < _suggestions.length; i++) ...[
                        _buildSuggestionTile(_suggestions[i]),
                        if (i < _suggestions.length - 1)
                          const Divider(height: 1, color: _slate200),
                      ],
                    ],
                  ),
      ),
    );
  }

  Widget _buildSuggestionTile(Producto producto) {
    return InkWell(
      onTap: () => _selectSuggestion(producto),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _slate100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                producto.codigo,
                style: const TextStyle(
                  color: _slate700,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    producto.nombre,
                    style: const TextStyle(
                      color: _slate900,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Stock: ${producto.stock} ${producto.unidadMedida}',
                    style: const TextStyle(color: _slate500),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${PriceFormatter.format(producto.precioVenta)}',
                  style: const TextStyle(
                    color: _slate900,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                _buildBadge(
                  label: producto.activo ? 'Activo' : 'Inactivo',
                  background: producto.activo ? _emerald100 : _slate200,
                  foreground:
                      producto.activo ? const Color(0xFF047857) : _slate700,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Producto producto) {
    final stockBajo = producto.stock <= 5;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _slate200),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 20,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _slate100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        producto.codigo,
                        style: const TextStyle(
                          color: _slate700,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      producto.nombre,
                      style: const TextStyle(
                        color: _slate900,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Unidad: ${producto.unidadMedida}',
                      style: const TextStyle(
                        color: _slate500,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${PriceFormatter.format(producto.precioVenta)}',
                    style: const TextStyle(
                      color: _slate900,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildBadge(
                    label: producto.activo ? 'Activo' : 'Inactivo',
                    background: producto.activo ? _emerald100 : _slate200,
                    foreground:
                        producto.activo ? const Color(0xFF047857) : _slate700,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _buildInfoBlock(
                  label: 'Unidad',
                  value: producto.unidadMedida,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoBlock(
                  label: 'Stock',
                  value: '${producto.stock}',
                  badge: stockBajo
                      ? _buildBadge(
                          label: 'Bajo',
                          background: _amber100,
                          foreground: _amber800,
                        )
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              if (_canEditProductos)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _openEditForm(producto),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _slate700,
                      side: const BorderSide(color: _slate300),
                      backgroundColor: const Color(0xFFF8FAFC),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      'Editar',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              if (_canEditProductos && _canToggleProductos)
                const SizedBox(width: 10),
              if (_canToggleProductos)
                Expanded(
                  child: FilledButton(
                    onPressed: () => _toggleActivo(producto),
                    style: FilledButton.styleFrom(
                      backgroundColor: producto.activo ? _rose600 : _emerald600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(
                      producto.activo ? 'Inactivar' : 'Activar',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              if (!_canEditProductos && !_canToggleProductos)
                Expanded(child: _buildReadonlyInlineMessage()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _slate200),
      ),
      child: const Text(
        'No hay productos para mostrar.',
        textAlign: TextAlign.center,
        style: TextStyle(color: _slate500),
      ),
    );
  }

  Widget _buildDesktopTableCard(List<Producto> productos) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _slate200),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tabla de productos',
                        style: TextStyle(
                          color: _slate900,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Vista alineada para escritorio con estados, stock y acciones rapidas.',
                        style: TextStyle(
                          color: _slate500,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _slate100,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '${productos.length} visibles',
                    style: const TextStyle(
                      color: _slate700,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _slate200),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
            child: Column(
              children: [
                _buildDesktopTableHeader(),
                const SizedBox(height: 10),
                for (var index = 0; index < productos.length; index++) ...[
                  _buildDesktopTableRow(productos[index]),
                  if (index < productos.length - 1)
                    const Divider(height: 1, color: _slate200),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _slate100,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        children: [
          _DesktopTableHeaderCell(label: 'CODIGO', flex: 11),
          _DesktopTableHeaderCell(label: 'PRODUCTO', flex: 24),
          _DesktopTableHeaderCell(label: 'PRECIO', flex: 14),
          _DesktopTableHeaderCell(label: 'STOCK', flex: 12),
          _DesktopTableHeaderCell(label: 'UNIDAD', flex: 11),
          _DesktopTableHeaderCell(label: 'ESTADO', flex: 12),
          _DesktopTableHeaderCell(label: 'ACCIONES', flex: 16),
        ],
      ),
    );
  }

  Widget _buildDesktopTableRow(Producto producto) {
    final stockBajo = producto.stock <= 5;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 11,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _slate100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  producto.codigo,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _slate700,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  producto.nombre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _slate900,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID ${producto.id}',
                  style: const TextStyle(
                    color: _slate500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 14,
            child: Text(
              '\$${PriceFormatter.format(producto.precioVenta)}',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _slate900,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 12,
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    '${producto.stock}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _slate900,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (stockBajo) ...[
                  const SizedBox(width: 6),
                  _buildBadge(
                    label: 'Bajo',
                    background: _amber100,
                    foreground: _amber800,
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            flex: 11,
            child: Text(
              producto.unidadMedida,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _slate700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 12,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildBadge(
                label: producto.activo ? 'Activo' : 'Inactivo',
                background: producto.activo ? _emerald100 : _rose100,
                foreground: producto.activo
                    ? const Color(0xFF047857)
                    : const Color(0xFFBE123C),
              ),
            ),
          ),
          Expanded(
            flex: 16,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (_canEditProductos)
                  TextButton.icon(
                    onPressed: () => _openEditForm(producto),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Editar'),
                    style: TextButton.styleFrom(
                      foregroundColor: _slate700,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                    ),
                  ),
                if (_canToggleProductos)
                  FilledButton.tonalIcon(
                    onPressed: () => _toggleActivo(producto),
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          producto.activo ? _rose100 : const Color(0xFFECFDF5),
                      foregroundColor: producto.activo
                          ? const Color(0xFFBE123C)
                          : const Color(0xFF047857),
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: Icon(
                      producto.activo
                          ? Icons.pause_circle_outline_rounded
                          : Icons.check_circle_outline_rounded,
                      size: 18,
                    ),
                    label: Text(producto.activo ? 'Inactivar' : 'Activar'),
                  ),
                if (!_canEditProductos && !_canToggleProductos)
                  _buildBadge(
                    label: 'Solo lectura',
                    background: _slate100,
                    foreground: _slate700,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopPagination(PaginatedProductosResponse response) {
    final startPage = (response.currentPage - 2).clamp(1, response.lastPage);
    final endPage = (startPage + 4).clamp(1, response.lastPage);
    final adjustedStart = (endPage - 4).clamp(1, response.lastPage);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _slate200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Pagina ${response.currentPage} de ${response.lastPage} • ${response.total} productos',
              style: const TextStyle(
                color: _slate700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          OutlinedButton.icon(
            onPressed: response.currentPage > 1
                ? () => unawaited(
                      _controller.goToPage(response.currentPage - 1),
                    )
                : null,
            icon: const Icon(Icons.chevron_left_rounded),
            label: const Text('Anterior'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _slate700,
              side: const BorderSide(color: _slate300),
            ),
          ),
          const SizedBox(width: 12),
          Wrap(
            spacing: 8,
            children: [
              for (int page = adjustedStart; page <= endPage; page++)
                FilledButton(
                  onPressed: page == response.currentPage
                      ? null
                      : () => unawaited(_controller.goToPage(page)),
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        page == response.currentPage ? _slate900 : _slate100,
                    foregroundColor:
                        page == response.currentPage ? Colors.white : _slate700,
                    disabledBackgroundColor: _slate900,
                    disabledForegroundColor: Colors.white,
                    minimumSize: const Size(44, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text('$page'),
                ),
            ],
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: response.currentPage < response.lastPage
                ? () => unawaited(
                      _controller.goToPage(response.currentPage + 1),
                    )
                : null,
            icon: const Icon(Icons.chevron_right_rounded),
            label: const Text('Siguiente'),
            style: FilledButton.styleFrom(
              backgroundColor: _slate900,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationCard(PaginatedProductosResponse response) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: _slate200),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F0F172A),
              blurRadius: 16,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _slate100,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'Pagina ${response.currentPage}/${response.lastPage}',
                    style: const TextStyle(
                      color: _slate900,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${response.total} total',
                  style: const TextStyle(
                    color: _slate500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: response.currentPage > 1
                        ? () => unawaited(
                              _controller.goToPage(response.currentPage - 1),
                            )
                        : null,
                    icon: const Icon(Icons.chevron_left_rounded),
                    label: const Text('Anterior'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _slate700,
                      backgroundColor: const Color(0xFFF8FAFC),
                      side: const BorderSide(color: _slate300),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: response.currentPage < response.lastPage
                        ? () => unawaited(
                              _controller.goToPage(response.currentPage + 1),
                            )
                        : null,
                    icon: const Icon(Icons.chevron_right_rounded),
                    label: const Text('Siguiente'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _slate900,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: _slate100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: _slate300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: _slate300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: _emerald500, width: 1.4),
        ),
      ),
    );
  }

  Widget _buildStateChip({
    required String label,
    required bool selected,
    required Color backgroundColor,
    required Color foregroundColor,
    required Color inactiveColor,
    required Color inactiveForeground,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? backgroundColor : inactiveColor,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? foregroundColor : inactiveForeground,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildBadge({
    required String label,
    required Color background,
    required Color foreground,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildReadonlyAccessCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Acceso',
            style: TextStyle(
              color: Color(0xFFBFDBFE),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2),
          Text(
            'Solo lectura',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopReadonlyPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: const Text(
        'Acceso solo lectura',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildReadonlyInlineMessage() {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: _slate100,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Text(
        'Solo lectura',
        style: TextStyle(
          color: _slate700,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildInfoBlock({
    required String label,
    required String value,
    Widget? badge,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _slate100,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _slate500,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    color: _slate900,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 8),
                badge,
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _onSearchChanged(String value) {
    _controller.onSearchChanged(value);
  }

  void _selectSuggestion(Producto producto) {
    _controller.selectSuggestion(producto);
  }

  void _clearSearch() {
    _controller.clearSearch();
  }

  void _applySearch(String value) {
    unawaited(_controller.applySearch(value));
  }

  Future<void> _refresh({
    ProductosQuery? query,
    bool silent = true,
  }) async {
    await _controller.refresh(query: query, silent: silent);
  }

  Future<void> _openCreateForm() async {
    if (!_canCreateProductos) {
      _showForbiddenMessage();
      return;
    }

    final created = await Navigator.of(context).push<Producto>(
      MaterialPageRoute(
        builder: (_) => ProductoFormScreen(repository: _repository),
      ),
    );

    if (created != null) {
      await _controller.refreshAfterMutation(
        reason: 'create-product',
        producto: created,
      );
    }
  }

  Future<void> _openEditForm(Producto producto) async {
    if (!_canEditProductos) {
      _showForbiddenMessage();
      return;
    }

    final updated = await Navigator.of(context).push<Producto>(
      MaterialPageRoute(
        builder: (_) => ProductoFormScreen(
          repository: _repository,
          producto: producto,
        ),
      ),
    );

    if (updated != null) {
      await _controller.refreshAfterMutation(
        reason: 'edit-product',
        producto: updated,
      );
    }
  }

  Future<void> _toggleActivo(Producto producto) async {
    if (!_canToggleProductos) {
      _showForbiddenMessage();
      return;
    }

    try {
      await _controller.toggleActivo(producto);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.statusCode == 403
                ? 'No tienes permisos para cambiar el estado del producto.'
                : error.message,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No fue posible cambiar el estado del producto.')),
      );
    }
  }

  void _showForbiddenMessage() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No tienes permisos para realizar esta acción.'),
      ),
    );
  }

  String _formatOrder(String value) {
    switch (value) {
      case 'codigo':
        return 'Codigo';
      case 'nombre':
        return 'Nombre';
      case 'stock':
        return 'Stock';
      case 'precio_venta':
        return 'Precio venta';
      case 'activo':
        return 'Estado';
      default:
        return value;
    }
  }
}

class _DesktopTableHeaderCell extends StatelessWidget {
  const _DesktopTableHeaderCell({
    required this.label,
    required this.flex,
  });

  final String label;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: _ProductosScreenState._slate500,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
