import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../core/layout/adaptive_layout.dart';
import '../../../shared/utils/price_formatter.dart';
import '../data/paginated_servicios_response.dart';
import '../data/servicios_query.dart';
import '../data/servicios_repository.dart';
import '../domain/servicio.dart';
import 'servicio_form_screen.dart';
import 'servicios_controller.dart';
import 'servicios_state.dart';

class ServiciosScreen extends StatefulWidget {
  const ServiciosScreen({
    super.key,
    required this.authController,
    this.embedded = false,
  });

  final AuthController authController;
  final bool embedded;

  @override
  State<ServiciosScreen> createState() => _ServiciosScreenState();
}

class _ServiciosScreenState extends State<ServiciosScreen> {
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

  late final ServiciosController _controller;

  ServiciosRepository get _repository => _controller.repository;
  TextEditingController get _searchController => _controller.searchController;
  FocusNode get _searchFocusNode => _controller.searchFocusNode;
  ServiciosState get _state => _controller.state;
  ServiciosQuery get _query => _state.query;
  bool get _isInitialLoading => _state.isInitialLoading;
  PaginatedServiciosResponse? get _response => _state.response;
  Object? get _loadError => _state.loadError;
  List<String> get _availableCategories => _state.availableCategories;
  bool get _canCreateServicios => widget.authController.canCreateServicios;
  bool get _canEditServicios => widget.authController.canEditServicios;
  bool get _canToggleServicios => widget.authController.canToggleServicios;

  @override
  void initState() {
    super.initState();
    _controller = ServiciosController(
      repository: ServiciosRepository(
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
          builder: (context, _) => SafeArea(child: _buildBody(isDesktop)),
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
            'Error cargando servicios: $_loadError',
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

  Widget _buildMobileLayout(PaginatedServiciosResponse response) {
    final servicios = response.items;

    return RefreshIndicator(
      color: _emerald600,
      onRefresh: () async => _refresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
        children: [
          _buildHero(response, isDesktop: false),
          const SizedBox(height: 16),
          _buildFiltersCard(isDesktop: false),
          const SizedBox(height: 16),
          if (servicios.isEmpty)
            _buildEmptyState()
          else ...[
            for (final servicio in servicios) ...[
              _buildServiceCard(servicio),
              const SizedBox(height: 12),
            ],
          ],
          _buildPaginationCard(response),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(PaginatedServiciosResponse response) {
    final servicios = response.items;

    return RefreshIndicator(
      color: _emerald600,
      onRefresh: () async => _refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(32, 28, 32, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHero(response, isDesktop: true),
                const SizedBox(height: 24),
                _buildFiltersCard(isDesktop: true),
                const SizedBox(height: 24),
                if (servicios.isEmpty)
                  _buildEmptyState()
                else
                  _buildDesktopTableCard(servicios),
                const SizedBox(height: 18),
                _buildDesktopPagination(response),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero(
    PaginatedServiciosResponse response, {
    required bool isDesktop,
  }) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 28 : 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isDesktop ? 32 : 30),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF14532D), Color(0xFF166534)],
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
      child: isDesktop
          ? _buildDesktopHeroContent(response)
          : _buildMobileHeroContent(response),
    );
  }

  Widget _buildMobileHeroContent(PaginatedServiciosResponse response) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeroPill('EXPERIENCIA MOVIL'),
        const SizedBox(height: 14),
        const Text(
          'Servicios',
          style: TextStyle(
            color: Colors.white,
            fontSize: 31,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Consulta y administra el catalogo de servicios por seccion, estado y precios definidos manualmente.',
          style: TextStyle(color: Color(0xFFE2E8F0), height: 1.45),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _canCreateServicios
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
                        'Nuevo servicio',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    )
                  : _buildReadonlyAccessCard(),
            ),
            const SizedBox(width: 12),
            _buildHeroCounter('${response.currentPage}/${response.lastPage}'),
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
                label: 'Categoria',
                value: _query.categoria.isEmpty
                    ? 'Todas'
                    : formatServiceCategoryLabel(_query.categoria),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopHeroContent(PaginatedServiciosResponse response) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroPill('Modulo escritorio'),
              const SizedBox(height: 16),
              const Text(
                'Servicios',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              const SizedBox(
                width: 760,
                child: Text(
                  'Organiza el catalogo por seccion, busca por codigo o descripcion y controla estados sin mezclar todavia logica de cotizaciones.',
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
            _canCreateServicios
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
                      'Nuevo servicio',
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
                  icon: Icons.miscellaneous_services_outlined,
                  label: 'Total',
                  value: '${response.total}',
                ),
                _buildHeaderStat(
                  icon: Icons.view_week_outlined,
                  label: 'Pagina',
                  value: '${response.currentPage}/${response.lastPage}',
                ),
                _buildHeaderStat(
                  icon: Icons.category_outlined,
                  label: 'Filtro',
                  value: _query.categoria.isEmpty
                      ? 'Todas'
                      : formatServiceCategoryLabel(_query.categoria),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFiltersCard({required bool isDesktop}) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 20),
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
          Text(
            isDesktop ? 'Busqueda y filtros' : 'Buscar y filtrar',
            style: const TextStyle(
              color: _slate900,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Busca por codigo o descripcion y filtra por categoria, estado, orden y direccion.',
            style: TextStyle(color: _slate500, height: 1.4),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            onChanged: _controller.onSearchDraftChanged,
            onSubmitted: (value) => _applySearch(value),
            decoration: InputDecoration(
              labelText: 'Buscar servicio',
              hintText: 'Ejemplo: SER-010, tablero o mantenimiento',
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
          const SizedBox(height: 18),
          if (isDesktop)
            _buildDesktopFilterRow()
          else
            _buildMobileFilterColumn(),
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
        ],
      ),
    );
  }

  Widget _buildDesktopFilterRow() {
    return Row(
      children: [
        Expanded(child: _buildCategoriaDropdown()),
        const SizedBox(width: 12),
        Expanded(child: _buildOrdenDropdown()),
        const SizedBox(width: 12),
        Expanded(child: _buildDireccionDropdown()),
      ],
    );
  }

  Widget _buildMobileFilterColumn() {
    return Column(
      children: [
        _buildCategoriaDropdown(),
        const SizedBox(height: 12),
        _buildOrdenDropdown(),
        const SizedBox(height: 12),
        _buildDireccionDropdown(),
      ],
    );
  }

  Widget _buildCategoriaDropdown() {
    return _buildDropdown(
      label: 'Categoria',
      value: _query.categoria.isEmpty ? '__all__' : _query.categoria,
      items: [
        const DropdownMenuItem(value: '__all__', child: Text('Todas')),
        for (final categoria in _availableCategories)
          DropdownMenuItem(
            value: categoria,
            child: Text(formatServiceCategoryLabel(categoria)),
          ),
      ],
      onChanged: (value) {
        if (value == null) return;
        unawaited(
          _controller.setCategoriaFilter(value == '__all__' ? null : value),
        );
      },
    );
  }

  Widget _buildOrdenDropdown() {
    return _buildDropdown(
      label: 'Ordenar por',
      value: _query.orden,
      items: const [
        DropdownMenuItem(value: 'categoria', child: Text('Categoria')),
        DropdownMenuItem(value: 'codigo', child: Text('Codigo')),
        DropdownMenuItem(value: 'descripcion', child: Text('Descripcion')),
        DropdownMenuItem(
          value: 'precio_unitario',
          child: Text('Precio unitario'),
        ),
        DropdownMenuItem(
          value: 'precio_con_iva',
          child: Text('Precio con IVA'),
        ),
      ],
      onChanged: (value) {
        if (value != null) {
          unawaited(_controller.setOrden(value));
        }
      },
    );
  }

  Widget _buildDireccionDropdown() {
    return _buildDropdown(
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
    );
  }

  Widget _buildServiceCard(Servicio servicio) {
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
                    _buildCodePill(servicio.codigo),
                    const SizedBox(height: 12),
                    Text(
                      servicio.descripcion,
                      style: const TextStyle(
                        color: _slate900,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Categoria: ${formatServiceCategoryLabel(servicio.categoria)}',
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
              _buildBadge(
                label: servicio.activo ? 'Activo' : 'Inactivo',
                background: servicio.activo ? _emerald100 : _rose100,
                foreground: servicio.activo
                    ? const Color(0xFF047857)
                    : const Color(0xFFBE123C),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _buildInfoBlock(
                  label: 'Unidad',
                  value: servicio.unidad,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoBlock(
                  label: 'IVA',
                  value: '\$${PriceFormatter.format(servicio.iva)}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoBlock(
                  label: 'Precio unitario',
                  value: '\$${PriceFormatter.format(servicio.precioUnitario)}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoBlock(
                  label: 'Precio con IVA',
                  value: '\$${PriceFormatter.format(servicio.precioConIva)}',
                ),
              ),
            ],
          ),
          if (servicio.observaciones.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            _buildInfoBlock(
              label: 'Observaciones',
              value: servicio.observaciones,
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              if (_canEditServicios)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _openEditForm(servicio),
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
              if (_canEditServicios && _canToggleServicios)
                const SizedBox(width: 10),
              if (_canToggleServicios)
                Expanded(
                  child: FilledButton(
                    onPressed: () => _toggleActivo(servicio),
                    style: FilledButton.styleFrom(
                      backgroundColor: servicio.activo ? _rose600 : _emerald600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(
                      servicio.activo ? 'Inactivar' : 'Activar',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              if (!_canEditServicios && !_canToggleServicios)
                Expanded(child: _buildReadonlyInlineMessage()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTableCard(List<Servicio> servicios) {
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
                        'Tabla de servicios',
                        style: TextStyle(
                          color: _slate900,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Vista operativa para escritorio con seccion, precios, estado y acciones rapidas.',
                        style: TextStyle(color: _slate500, height: 1.4),
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
                    '${servicios.length} visibles',
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
                for (var index = 0; index < servicios.length; index++) ...[
                  _buildDesktopTableRow(servicios[index]),
                  if (index < servicios.length - 1)
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
          _DesktopTableHeaderCell(label: 'CODIGO', flex: 9),
          _DesktopTableHeaderCell(label: 'DESCRIPCION', flex: 22),
          _DesktopTableHeaderCell(label: 'CATEGORIA', flex: 14),
          _DesktopTableHeaderCell(label: 'UNIDAD', flex: 10),
          _DesktopTableHeaderCell(label: 'PRECIO U.', flex: 12),
          _DesktopTableHeaderCell(label: 'IVA', flex: 10),
          _DesktopTableHeaderCell(label: 'PRECIO + IVA', flex: 12),
          _DesktopTableHeaderCell(label: 'OBS.', flex: 16),
          _DesktopTableHeaderCell(label: 'ESTADO', flex: 10),
          _DesktopTableHeaderCell(label: 'ACCIONES', flex: 17),
        ],
      ),
    );
  }

  Widget _buildDesktopTableRow(Servicio servicio) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
              flex: 9,
              child: Align(
                  alignment: Alignment.centerLeft,
                  child: _buildCodePill(servicio.codigo))),
          Expanded(
            flex: 22,
            child: Text(
              servicio.descripcion,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _slate900,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 14,
            child: Text(
              formatServiceCategoryLabel(servicio.categoria),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: _slate700, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 10,
            child: Text(
              servicio.unidad,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: _slate700, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 12,
            child: Text(
              '\$${PriceFormatter.format(servicio.precioUnitario)}',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: _slate900, fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            flex: 10,
            child: Text(
              '\$${PriceFormatter.format(servicio.iva)}',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: _slate900, fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            flex: 12,
            child: Text(
              '\$${PriceFormatter.format(servicio.precioConIva)}',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: _slate900, fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            flex: 16,
            child: Text(
              servicio.observaciones.trim().isEmpty
                  ? 'Sin notas'
                  : servicio.observaciones,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _slate500),
            ),
          ),
          Expanded(
            flex: 10,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildBadge(
                label: servicio.activo ? 'Activo' : 'Inactivo',
                background: servicio.activo ? _emerald100 : _rose100,
                foreground: servicio.activo
                    ? const Color(0xFF047857)
                    : const Color(0xFFBE123C),
              ),
            ),
          ),
          Expanded(
            flex: 17,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (_canEditServicios)
                  TextButton.icon(
                    onPressed: () => _openEditForm(servicio),
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
                if (_canToggleServicios)
                  FilledButton.tonalIcon(
                    onPressed: () => _toggleActivo(servicio),
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          servicio.activo ? _rose100 : const Color(0xFFECFDF5),
                      foregroundColor: servicio.activo
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
                      servicio.activo
                          ? Icons.pause_circle_outline_rounded
                          : Icons.check_circle_outline_rounded,
                      size: 18,
                    ),
                    label: Text(servicio.activo ? 'Inactivar' : 'Activar'),
                  ),
                if (!_canEditServicios && !_canToggleServicios)
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

  Widget _buildDesktopPagination(PaginatedServiciosResponse response) {
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
              'Pagina ${response.currentPage} de ${response.lastPage} - ${response.total} servicios',
              style: const TextStyle(
                  color: _slate700, fontWeight: FontWeight.w600),
            ),
          ),
          OutlinedButton.icon(
            onPressed: response.currentPage > 1
                ? () =>
                    unawaited(_controller.goToPage(response.currentPage - 1))
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
                ? () =>
                    unawaited(_controller.goToPage(response.currentPage + 1))
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

  Widget _buildPaginationCard(PaginatedServiciosResponse response) {
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

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _slate200),
      ),
      child: const Text(
        'No hay servicios para mostrar.',
        textAlign: TextAlign.center,
        style: TextStyle(color: _slate500),
      ),
    );
  }

  Widget _buildHeroPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFE2E8F0),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
        ),
      ),
    );
  }

  Widget _buildHeroCounter(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
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
            value,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800),
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
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800),
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
                    color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
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

  Widget _buildInfoBlock({
    required String label,
    required String value,
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
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: _slate900,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge({
    required String label,
    required Color background,
    required Color foreground,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: foreground, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildCodePill(String codigo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _slate100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        codigo,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: _slate700, fontWeight: FontWeight.w700),
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
      child: const Text(
        'Solo lectura',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildDesktopReadonlyPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: const Text(
        'Acceso solo lectura',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildReadonlyInlineMessage() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _slate100,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Text(
        'Solo lectura',
        textAlign: TextAlign.center,
        style: TextStyle(color: _slate700, fontWeight: FontWeight.w700),
      ),
    );
  }

  Future<void> _refresh() {
    return _controller.refresh(silent: false, reason: 'pull-to-refresh');
  }

  Future<void> _applySearch(String value) {
    return _controller.applySearch(value);
  }

  Future<void> _clearSearch() {
    return _controller.clearSearch();
  }

  Future<void> _openCreateForm() async {
    final created = await Navigator.of(context).push<Servicio>(
      MaterialPageRoute(
        builder: (_) => ServicioFormScreen(repository: _repository),
      ),
    );

    if (created == null) return;
    if (!mounted) return;
    await _controller.refreshAfterMutation(
        reason: 'create-servicio', servicio: created);
    _showSnackBar('Servicio creado correctamente.');
  }

  Future<void> _openEditForm(Servicio servicio) async {
    final updated = await Navigator.of(context).push<Servicio>(
      MaterialPageRoute(
        builder: (_) => ServicioFormScreen(
          repository: _repository,
          servicio: servicio,
        ),
      ),
    );

    if (updated == null) return;
    if (!mounted) return;
    await _controller.refreshAfterMutation(
        reason: 'update-servicio', servicio: updated);
    _showSnackBar('Servicio actualizado correctamente.');
  }

  Future<void> _toggleActivo(Servicio servicio) async {
    try {
      final updated = await _controller.toggleActivo(servicio);
      if (!mounted) return;
      _showSnackBar(
        updated.activo
            ? 'Servicio activado correctamente.'
            : 'Servicio inactivado correctamente.',
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      _showSnackBar(error.message, isError: true);
    } catch (_) {
      if (!mounted) return;
      _showSnackBar('No fue posible cambiar el estado del servicio.',
          isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? _rose600 : _slate900,
        ),
      );
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
        style: const TextStyle(
          color: _ServiciosScreenState._slate500,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
