import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../core/layout/adaptive_layout.dart';
import '../../../shared/utils/price_formatter.dart';
import '../data/facturas_query.dart';
import '../data/facturas_repository.dart';
import '../data/paginated_facturas_response.dart';
import '../domain/factura.dart';
import '../facturas_controller.dart';
import '../facturas_state.dart';
import 'factura_detail_screen.dart';
import 'factura_form_screen.dart';

class FacturasScreen extends StatefulWidget {
  const FacturasScreen({
    super.key,
    required this.authController,
    this.embedded = false,
  });

  final AuthController authController;
  final bool embedded;

  @override
  State<FacturasScreen> createState() => _FacturasScreenState();
}

class _FacturasScreenState extends State<FacturasScreen> {
  static const _pollingInterval = Duration(seconds: 5);
  static const _slate900 = Color(0xFF0F172A);
  static const _slate700 = Color(0xFF334155);
  static const _slate500 = Color(0xFF64748B);
  static const _slate200 = Color(0xFFE2E8F0);
  static const _slate100 = Color(0xFFF1F5F9);
  static const _cyan700 = Color(0xFF0F766E);
  static const _emerald600 = Color(0xFF059669);
  static const _amber700 = Color(0xFFB45309);
  static const _rose600 = Color(0xFFE11D48);

  late final FacturasController _controller;

  TextEditingController get _searchController => _controller.searchController;
  FocusNode get _searchFocusNode => _controller.searchFocusNode;
  FacturasState get _state => _controller.state;
  FacturasQuery get _query => _state.query;
  PaginatedFacturasResponse? get _response => _state.response;
  Object? get _loadError => _state.loadError;
  bool get _isInitialLoading => _state.isInitialLoading;
  bool get _canCreate => widget.authController.canCreateFacturacion;
  bool get _canEdit => widget.authController.canEditFacturacion;

  @override
  void initState() {
    super.initState();
    _controller = FacturasController(
      repository: FacturasRepository(
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
          floatingActionButton: !isDesktop && _canCreate
              ? FloatingActionButton.extended(
                  onPressed: _openCreateForm,
                  backgroundColor: _slate900,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text(
                    'Nueva factura',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                )
              : null,
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
            'Error cargando facturas: $_loadError',
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

  Widget _buildMobileLayout(PaginatedFacturasResponse response) {
    final facturas = response.items;

    return RefreshIndicator(
      color: _cyan700,
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
        children: [
          _buildHero(response, isDesktop: false),
          const SizedBox(height: 16),
          _buildFiltersCard(isDesktop: false),
          const SizedBox(height: 16),
          if (facturas.isEmpty)
            _buildEmptyState()
          else ...[
            for (final factura in facturas) ...[
              _buildFacturaCard(factura),
              const SizedBox(height: 12),
            ],
          ],
          const SizedBox(height: 8),
          _buildPaginationCard(response),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(PaginatedFacturasResponse response) {
    final facturas = response.items;

    return RefreshIndicator(
      color: _cyan700,
      onRefresh: _refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(32, 28, 32, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1540),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHero(response, isDesktop: true),
                const SizedBox(height: 24),
                _buildFiltersCard(isDesktop: true),
                const SizedBox(height: 24),
                if (facturas.isEmpty)
                  _buildEmptyState()
                else
                  _buildDesktopTableCard(facturas),
                const SizedBox(height: 18),
                _buildPaginationCard(response),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero(
    PaginatedFacturasResponse response, {
    required bool isDesktop,
  }) {
    final stats = response.stats;

    return Container(
      padding: EdgeInsets.all(isDesktop ? 28 : 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isDesktop ? 32 : 30),
        gradient: const LinearGradient(
          colors: [Color(0xFF082F49), Color(0xFF0F172A), Color(0xFF155E75)],
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
              'FACTURACION INTERNA',
              style: TextStyle(
                color: Color(0xFFE2E8F0),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.3,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Facturas',
            style: TextStyle(
              color: Colors.white,
              fontSize: isDesktop ? 34 : 31,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Módulo de cuentas de cobro por servicios: borrador editable y emisión de documento.',
            style: TextStyle(color: Color(0xFFE2E8F0), height: 1.45),
          ),
          const SizedBox(height: 18),
          if (isDesktop)
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildHeroMetric('Total', '${stats.total}'),
                      _buildHeroMetric('Borrador', '${stats.borrador}'),
                      _buildHeroMetric('Emitida', '${stats.emitida}'),
                    ],
                  ),
                ),
                const SizedBox(width: 18),
                SizedBox(
                  width: 220,
                  child: _buildPrimaryAction(),
                ),
              ],
            )
          else ...[
            _buildPrimaryAction(),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildHeroMetric('Total', '${stats.total}', compact: true),
                _buildHeroMetric(
                  'Borrador',
                  '${stats.borrador}',
                  compact: true,
                ),
                _buildHeroMetric('Emitida', '${stats.emitida}', compact: true),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeroMetric(String label, String value, {bool compact = false}) {
    return Container(
      width: compact ? 145 : 160,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 14 : 16,
        vertical: compact ? 12 : 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFBAE6FD),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 22 : 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryAction() {
    if (!_canCreate) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: const Text(
          'Tu rol no puede crear facturas.',
          style: TextStyle(
            color: Color(0xFFE2E8F0),
            fontWeight: FontWeight.w600,
            height: 1.3,
          ),
        ),
      );
    }

    return FilledButton.icon(
      onPressed: _openCreateForm,
      style: FilledButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: _slate900,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      icon: const Icon(Icons.add_rounded),
      label: const Text(
        'Nueva factura',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildFiltersCard({required bool isDesktop}) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isDesktop ? 'Búsqueda y filtros' : 'Buscar y filtrar',
            style: const TextStyle(
              color: _slate900,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Filtra por cliente, código o estado de la factura.',
            style: TextStyle(color: _slate500, height: 1.4),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            onChanged: _controller.onSearchDraftChanged,
            onSubmitted: (value) => _applySearch(value),
            decoration: InputDecoration(
              labelText: 'Buscar factura',
              hintText: 'Ejemplo: FAC-001 o Cliente S.A.',
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
                    ),
                  IconButton(
                    onPressed: () => _applySearch(_searchController.text),
                    icon: const Icon(Icons.arrow_forward_rounded),
                  ),
                ],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: _slate200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: _slate200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: _cyan700, width: 1.6),
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (isDesktop)
            Row(
              children: [
                Expanded(child: _buildEstadoDropdown()),
                const SizedBox(width: 10),
                Expanded(child: _buildOrdenDropdown()),
                const SizedBox(width: 10),
                Expanded(child: _buildDireccionDropdown()),
              ],
            )
          else
            Column(
              children: [
                _buildEstadoDropdown(),
                const SizedBox(height: 10),
                _buildOrdenDropdown(),
                const SizedBox(height: 10),
                _buildDireccionDropdown(),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildEstadoDropdown() {
    return _buildDropdown(
      label: 'Estado',
      value: _query.estado.isEmpty ? '__all__' : _query.estado,
      items: const [
        DropdownMenuItem(value: '__all__', child: Text('Todos')),
        DropdownMenuItem(value: 'borrador', child: Text('Borrador')),
        DropdownMenuItem(value: 'emitida', child: Text('Emitida')),
      ],
      onChanged: (value) {
        if (value == null) {
          return;
        }
        unawaited(
          _controller.setEstadoFilter(value == '__all__' ? null : value),
        );
      },
    );
  }

  Widget _buildOrdenDropdown() {
    return _buildDropdown(
      label: 'Ordenar por',
      value: _query.orden,
      items: const [
        DropdownMenuItem(value: 'fecha', child: Text('Fecha')),
        DropdownMenuItem(value: 'codigo', child: Text('Código')),
        DropdownMenuItem(value: 'cliente_nombre', child: Text('Cliente')),
        DropdownMenuItem(value: 'subtotal', child: Text('Subtotal')),
        DropdownMenuItem(value: 'total', child: Text('Total')),
        DropdownMenuItem(value: 'estado', child: Text('Estado')),
      ],
      onChanged: (value) {
        if (value == null) {
          return;
        }
        unawaited(_controller.setOrden(value));
      },
    );
  }

  Widget _buildDireccionDropdown() {
    return _buildDropdown(
      label: 'Dirección',
      value: _query.direccion,
      items: const [
        DropdownMenuItem(value: 'asc', child: Text('Ascendente')),
        DropdownMenuItem(value: 'desc', child: Text('Descendente')),
      ],
      onChanged: (value) {
        if (value == null) {
          return;
        }
        unawaited(_controller.setDireccion(value));
      },
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
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _slate200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _slate200),
        ),
      ),
    );
  }

  Widget _buildFacturaCard(Factura factura) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  factura.codigo,
                  style: const TextStyle(
                    color: _slate900,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _buildEstadoChip(factura.estado),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            factura.clienteNombre,
            style: const TextStyle(
              color: _slate700,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Fecha: ${factura.fecha}',
            style: const TextStyle(color: _slate500),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildMoneyMetric(
                  'Subtotal',
                  PriceFormatter.formatCopWhole(factura.subtotal),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMoneyMetric(
                  'Total',
                  PriceFormatter.formatCopWhole(factura.total),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _buildActionButtons(factura, compact: true),
          ),
        ],
      ),
    );
  }

  Widget _buildMoneyMetric(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _slate100,
        borderRadius: BorderRadius.circular(12),
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
          const SizedBox(height: 3),
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

  Widget _buildDesktopTableCard(List<Factura> facturas) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _slate200),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            ),
            child: const Row(
              children: [
                _HeaderCell('Código', flex: 12),
                _HeaderCell('Fecha', flex: 10),
                _HeaderCell('Cliente', flex: 18),
                _HeaderCell('Subtotal', flex: 12),
                _HeaderCell('Total', flex: 12),
                _HeaderCell('Estado', flex: 10),
                _HeaderCell('Acciones', flex: 18, alignEnd: true),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: facturas.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final factura = facturas[index];
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 12,
                      child: Text(
                        factura.codigo,
                        style: const TextStyle(
                          color: _slate900,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 10,
                      child: Text(
                        factura.fecha,
                        style: const TextStyle(color: _slate700),
                      ),
                    ),
                    Expanded(
                      flex: 18,
                      child: Text(
                        factura.clienteNombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _slate700),
                      ),
                    ),
                    Expanded(
                      flex: 12,
                      child: Text(
                        PriceFormatter.formatCopWhole(factura.subtotal),
                        style: const TextStyle(color: _slate700),
                      ),
                    ),
                    Expanded(
                      flex: 12,
                      child: Text(
                        PriceFormatter.formatCopWhole(factura.total),
                        style: const TextStyle(
                          color: _slate900,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 10,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: _buildEstadoChip(factura.estado),
                      ),
                    ),
                    Expanded(
                      flex: 18,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          alignment: WrapAlignment.end,
                          children:
                              _buildActionButtons(factura, compact: false),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActionButtons(Factura factura, {required bool compact}) {
    final canEditar = _canEdit && factura.isBorrador;
    final canEmitir = _canEdit && factura.isBorrador;

    final textStyle = TextStyle(
      fontWeight: FontWeight.w700,
      fontSize: compact ? 12 : 11,
    );

    return [
      OutlinedButton(
        onPressed: () => _openDetailView(factura),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          side: const BorderSide(color: _slate200),
        ),
        child: Text('Ver', style: textStyle),
      ),
      if (canEditar)
        OutlinedButton(
          onPressed: () => _openEditForm(factura),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            side: const BorderSide(color: _slate200),
          ),
          child: Text('Editar', style: textStyle),
        ),
      if (canEmitir)
        FilledButton(
          onPressed: () => _emitirFactura(factura),
          style: FilledButton.styleFrom(
            backgroundColor: _emerald600,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          child: Text('Emitir', style: textStyle),
        ),
    ];
  }

  Widget _buildEstadoChip(String estado) {
    final normalized = estado.trim().toLowerCase();
    final color = switch (normalized) {
      'emitida' => _emerald600,
      _ => _amber700,
    };

    final label = switch (normalized) {
      'emitida' => 'Emitida',
      _ => 'Borrador',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _slate200),
      ),
      child: const Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 46, color: _slate500),
          SizedBox(height: 10),
          Text(
            'No hay facturas para mostrar',
            style: TextStyle(
              color: _slate900,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Crea una factura o ajusta los filtros para ver resultados.',
            style: TextStyle(color: _slate500),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationCard(PaginatedFacturasResponse response) {
    final currentPage = response.currentPage;
    final lastPage = response.lastPage;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _slate200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Página $currentPage de $lastPage · ${response.total} registros',
              style: const TextStyle(
                color: _slate500,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: currentPage > 1
                ? () => unawaited(_controller.goToPage(currentPage - 1))
                : null,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          IconButton(
            onPressed: currentPage < lastPage
                ? () => unawaited(_controller.goToPage(currentPage + 1))
                : null,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }

  Future<void> _refresh() {
    return _controller.refresh(silent: false, reason: 'pull-to-refresh');
  }

  void _applySearch(String value) {
    unawaited(_controller.applySearch(value));
  }

  void _clearSearch() {
    _searchController.clear();
    unawaited(_controller.clearSearch());
  }

  Future<void> _openCreateForm() async {
    final created = await Navigator.of(context).push<Factura>(
      MaterialPageRoute(
        builder: (_) => FacturaFormScreen(
          controller: _controller,
          canEditFacturacion: _canEdit,
          defaultFirmaPath: widget.authController.defaultFirmaPath,
          defaultFirmaNombre: widget.authController.defaultFirmaNombre,
          defaultFirmaCargo: widget.authController.defaultFirmaCargo,
          defaultFirmaEmpresa: widget.authController.defaultFirmaEmpresa,
          onFirmaPredeterminadaActualizada: (
              {firmaPath,
              required firmaNombre,
              required firmaCargo,
              required firmaEmpresa}) {
            widget.authController.defaultFirmaPath = firmaPath;
            widget.authController.defaultFirmaNombre = firmaNombre;
            widget.authController.defaultFirmaCargo = firmaCargo;
            widget.authController.defaultFirmaEmpresa = firmaEmpresa;
          },
        ),
      ),
    );

    if (!mounted || created == null) {
      return;
    }

    _showSnack('Factura ${created.codigo} guardada correctamente.');
    await _controller.refreshAfterMutation(reason: 'created-form');
  }

  Future<void> _openDetailView(Factura factura) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => FacturaDetailScreen(
          controller: _controller,
          factura: factura,
          defaultFirmaPath: widget.authController.defaultFirmaPath,
          defaultFirmaNombre: widget.authController.defaultFirmaNombre,
          defaultFirmaCargo: widget.authController.defaultFirmaCargo,
          defaultFirmaEmpresa: widget.authController.defaultFirmaEmpresa,
        ),
      ),
    );
  }

  Future<void> _openEditForm(Factura factura) async {
    if (!factura.isBorrador) {
      await _openDetailView(factura);
      return;
    }

    final updated = await Navigator.of(context).push<Factura>(
      MaterialPageRoute(
        builder: (_) => FacturaFormScreen(
          controller: _controller,
          canEditFacturacion: _canEdit,
          initialFactura: factura,
          readOnly: false,
          defaultFirmaPath: widget.authController.defaultFirmaPath,
          defaultFirmaNombre: widget.authController.defaultFirmaNombre,
          defaultFirmaCargo: widget.authController.defaultFirmaCargo,
          defaultFirmaEmpresa: widget.authController.defaultFirmaEmpresa,
          onFirmaPredeterminadaActualizada: (
              {firmaPath,
              required firmaNombre,
              required firmaCargo,
              required firmaEmpresa}) {
            widget.authController.defaultFirmaPath = firmaPath;
            widget.authController.defaultFirmaNombre = firmaNombre;
            widget.authController.defaultFirmaCargo = firmaCargo;
            widget.authController.defaultFirmaEmpresa = firmaEmpresa;
          },
        ),
      ),
    );

    if (!mounted || updated == null) {
      return;
    }

    _showSnack('Factura ${updated.codigo} actualizada.');
    await _controller.refreshAfterMutation(reason: 'updated-form');
  }

  Future<void> _emitirFactura(Factura factura) async {
    final confirmed = await _confirmDialog(
      title: 'Emitir factura',
      message:
          'La factura cambiará a emitida y quedará cerrada para edición. ¿Deseas continuar?',
      confirmText: 'Emitir',
      confirmColor: _emerald600,
    );

    if (!mounted || confirmed != true) {
      return;
    }

    try {
      final updated = await _controller.emitirFactura(factura);
      if (!mounted) {
        return;
      }

      _showSnack('Factura ${updated.codigo} emitida correctamente.');
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showSnack('$error', isError: true);
    }
  }

  Future<bool?> _confirmDialog({
    required String title,
    required String message,
    required String confirmText,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(backgroundColor: confirmColor),
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? _rose600 : _slate900,
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(
    this.label, {
    required this.flex,
    this.alignEnd = false,
  });

  final String label;
  final int flex;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Align(
        alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}
