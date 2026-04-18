import 'dart:async';
import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../core/layout/adaptive_layout.dart';
import '../../../shared/utils/price_formatter.dart';
import '../cotizaciones_controller.dart';
import '../cotizaciones_state.dart';
import '../data/cotizaciones_query.dart';
import '../data/cotizaciones_repository.dart';
import '../data/paginated_cotizaciones_response.dart';
import '../domain/cotizacion.dart';
import 'cotizacion_form_screen.dart';

class CotizacionesScreen extends StatefulWidget {
  const CotizacionesScreen({
    super.key,
    required this.authController,
    this.embedded = false,
  });

  final AuthController authController;
  final bool embedded;

  @override
  State<CotizacionesScreen> createState() => _CotizacionesScreenState();
}

class _CotizacionesScreenState extends State<CotizacionesScreen> {
  static const _pollingInterval = Duration(seconds: 5);
  static const _desktopTableMaxWidth = 1440.0;
  static const _desktopCodigoColumnWidth = 120.0;
  static const _desktopClienteColumnWidth = 210.0;
  static const _desktopFechaColumnWidth = 130.0;
  static const _desktopTotalColumnWidth = 170.0;
  static const _desktopEstadoColumnWidth = 140.0;
  static const _desktopActionsColumnWidth = 280.0;
  static const _desktopActionButtonWidth = 120.0;
  static const _desktopTableColumnGap = 28.0;
  static const _slate900 = Color(0xFF0F172A);
  static const _slate700 = Color(0xFF334155);
  static const _slate500 = Color(0xFF64748B);
  static const _slate200 = Color(0xFFE2E8F0);
  static const _slate100 = Color(0xFFF1F5F9);
  static const _cyan700 = Color(0xFF0F766E);
  static const _cyan600 = Color(0xFF0891B2);
  static const _emerald600 = Color(0xFF059669);
  static const _amber700 = Color(0xFFB45309);
  static const _rose600 = Color(0xFFE11D48);

  late final CotizacionesController _controller;

  TextEditingController get _searchController => _controller.searchController;
  FocusNode get _searchFocusNode => _controller.searchFocusNode;
  CotizacionesState get _state => _controller.state;
  CotizacionesQuery get _query => _state.query;
  PaginatedCotizacionesResponse? get _response => _state.response;
  Object? get _loadError => _state.loadError;
  bool get _isInitialLoading => _state.isInitialLoading;
  bool get _canCreateCotizaciones =>
      widget.authController.canCreateCotizaciones;
  bool get _canEditCotizaciones => widget.authController.canEditCotizaciones;
  bool get _isAdministrador => widget.authController.isAdministrador;

  @override
  void initState() {
    super.initState();
    _controller = CotizacionesController(
      repository: CotizacionesRepository(
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
          floatingActionButton: !isDesktop && _canCreateCotizaciones
              ? FloatingActionButton.extended(
                  onPressed: _openCreateDialog,
                  backgroundColor: _slate900,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text(
                    'Nueva cotización',
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
            'Error cargando cotizaciones: $_loadError',
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

  Widget _buildMobileLayout(PaginatedCotizacionesResponse response) {
    final cotizaciones = response.items;

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
          if (cotizaciones.isEmpty)
            _buildEmptyState()
          else ...[
            for (final cotizacion in cotizaciones) ...[
              _buildCotizacionCard(cotizacion),
              const SizedBox(height: 12),
            ],
          ],
          const SizedBox(height: 8),
          _buildPaginationCard(response),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(PaginatedCotizacionesResponse response) {
    final cotizaciones = response.items;

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
                if (cotizaciones.isEmpty)
                  _buildEmptyState()
                else
                  _buildDesktopTableCard(cotizaciones),
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
    PaginatedCotizacionesResponse response, {
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
              'MODULO COMERCIAL',
              style: TextStyle(
                color: Color(0xFFE2E8F0),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Cotizaciones',
            style: TextStyle(
              color: Colors.white,
              fontSize: isDesktop ? 34 : 31,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Base externa del modulo para consultar, filtrar y mantener cotizaciones sin entrar todavia al editor completo ni a la salida PDF.',
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
                      _buildHeroMetric('Pendientes', '${stats.pendiente}'),
                      _buildHeroMetric('Vistas', '${stats.visto}'),
                      _buildHeroMetric('Realizadas', '${stats.realizada}'),
                      _buildHeroMetric('Nulas', '${stats.nula}'),
                    ],
                  ),
                ),
                const SizedBox(width: 18),
                SizedBox(
                  width: 240,
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
                  'Pendientes',
                  '${stats.pendiente}',
                  compact: true,
                ),
                _buildHeroMetric(
                  'Vistas',
                  '${stats.visto}',
                  compact: true,
                ),
                _buildHeroMetric(
                  'Realizadas',
                  '${stats.realizada}',
                  compact: true,
                ),
                _buildHeroMetric(
                  'Nulas',
                  '${stats.nula}',
                  compact: true,
                ),
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
    if (!_canCreateCotizaciones) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: const Text(
          'Acceso solo lectura a la base inicial del modulo.',
          style: TextStyle(
            color: Color(0xFFE2E8F0),
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return FilledButton.icon(
      onPressed: _openCreateDialog,
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
        'Nueva cotizacion',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildFiltersCard({required bool isDesktop}) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _slate200),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 18,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Busqueda, filtros y orden',
                  style: TextStyle(
                    color: _slate900,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Busca por codigo, referencia o cliente y mantén el seguimiento comercial al dia.',
            style: TextStyle(color: _slate500, height: 1.4),
          ),
          const SizedBox(height: 18),
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _buildSearchField()),
                const SizedBox(width: 14),
                Expanded(child: _buildEstadoFilter()),
                const SizedBox(width: 14),
                Expanded(child: _buildOrdenFilter()),
                const SizedBox(width: 14),
                Expanded(child: _buildDireccionFilter()),
              ],
            )
          else ...[
            _buildSearchField(),
            const SizedBox(height: 12),
            _buildEstadoFilter(),
            const SizedBox(height: 12),
            _buildOrdenFilter(),
            const SizedBox(height: 12),
            _buildDireccionFilter(),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      focusNode: _searchFocusNode,
      onChanged: _controller.onSearchDraftChanged,
      onSubmitted: (value) => _controller.applySearch(value),
      decoration: InputDecoration(
        labelText: 'Buscar cotizacion',
        hintText: 'Codigo, referencia o cliente',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _state.hasDraftSearch
            ? IconButton(
                onPressed: () => unawaited(_controller.clearSearch()),
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Limpiar busqueda',
              )
            : null,
        filled: true,
        fillColor: _slate100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildEstadoFilter() {
    return DropdownButtonFormField<String>(
      initialValue: _query.estado.isEmpty ? null : _query.estado,
      items: const [
        DropdownMenuItem<String>(value: null, child: Text('Todos los estados')),
        ...[
          DropdownMenuItem(value: 'pendiente', child: Text('Pendiente')),
          DropdownMenuItem(value: 'visto', child: Text('Visto')),
          DropdownMenuItem(value: 'realizada', child: Text('Realizada')),
          DropdownMenuItem(value: 'nula', child: Text('Nula')),
        ],
      ],
      onChanged: (value) => unawaited(_controller.setEstadoFilter(value)),
      decoration: _dropdownDecoration('Estado'),
    );
  }

  Widget _buildOrdenFilter() {
    return DropdownButtonFormField<String>(
      initialValue: _query.orden,
      items: const [
        DropdownMenuItem(value: 'fecha', child: Text('Fecha')),
        DropdownMenuItem(value: 'codigo', child: Text('Codigo')),
        DropdownMenuItem(value: 'referencia', child: Text('Referencia')),
        DropdownMenuItem(value: 'cliente_nombre', child: Text('Cliente')),
        DropdownMenuItem(value: 'total', child: Text('Total')),
        DropdownMenuItem(value: 'estado', child: Text('Estado')),
      ],
      onChanged: (value) {
        if (value != null) {
          unawaited(_controller.setOrden(value));
        }
      },
      decoration: _dropdownDecoration('Ordenar por'),
    );
  }

  Widget _buildDireccionFilter() {
    return DropdownButtonFormField<String>(
      initialValue: _query.direccion,
      items: const [
        DropdownMenuItem(value: 'desc', child: Text('Descendente')),
        DropdownMenuItem(value: 'asc', child: Text('Ascendente')),
      ],
      onChanged: (value) {
        if (value != null) {
          unawaited(_controller.setDireccion(value));
        }
      },
      decoration: _dropdownDecoration('Direccion'),
    );
  }

  InputDecoration _dropdownDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: _slate100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _buildCotizacionCard(Cotizacion cotizacion) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _slate200),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 18,
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
                    Text(
                      _displayCodigo(cotizacion),
                      style: const TextStyle(
                        color: _slate900,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(cotizacion.fecha),
                      style: const TextStyle(color: _slate500),
                    ),
                  ],
                ),
              ),
              _buildEstadoBadge(cotizacion.estado),
            ],
          ),
          const SizedBox(height: 14),
          _buildLabeledValue('Referencia', cotizacion.referencia),
          const SizedBox(height: 10),
          _buildLabeledValue('Cliente', cotizacion.clienteNombre),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildLabeledValue(
                  'Fecha',
                  _formatDate(cotizacion.fecha),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildLabeledValue(
                  'Total',
                  PriceFormatter.formatCopWhole(cotizacion.total),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildActionBar(cotizacion, compact: true),
        ],
      ),
    );
  }

  Widget _buildDesktopTableCard(List<Cotizacion> cotizaciones) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _desktopTableMaxWidth),
        child: Container(
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
                            'Tabla de cotizaciones',
                            style: TextStyle(
                              color: _slate900,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Vista comercial de escritorio con referencia, cliente, fecha, total, estado y acciones operativas.',
                            style: TextStyle(color: _slate500, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _slate100,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        '${cotizaciones.length} visibles',
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
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 18),
                child: Column(
                  children: [
                    _buildDesktopCotizacionesTableHeader(),
                    const SizedBox(height: 10),
                    for (var index = 0;
                        index < cotizaciones.length;
                        index++) ...[
                      _buildDesktopCotizacionesTableRow(cotizaciones[index]),
                      if (index < cotizaciones.length - 1)
                        const Divider(height: 1, color: _slate200),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopCotizacionesTableHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: _slate100,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        children: [
          _DesktopCotizacionesHeaderCell(
            label: 'CODIGO',
            width: _desktopCodigoColumnWidth,
            textAlign: TextAlign.center,
          ),
          SizedBox(width: _desktopTableColumnGap),
          _DesktopCotizacionesHeaderCell(
            label: 'REFERENCIA',
            flexible: true,
            textAlign: TextAlign.center,
          ),
          SizedBox(width: _desktopTableColumnGap),
          _DesktopCotizacionesHeaderCell(
            label: 'CLIENTE',
            width: _desktopClienteColumnWidth,
            textAlign: TextAlign.center,
          ),
          SizedBox(width: _desktopTableColumnGap),
          _DesktopCotizacionesHeaderCell(
            label: 'FECHA',
            width: _desktopFechaColumnWidth,
            textAlign: TextAlign.center,
          ),
          SizedBox(width: _desktopTableColumnGap),
          _DesktopCotizacionesHeaderCell(
            label: 'TOTAL',
            width: _desktopTotalColumnWidth,
            textAlign: TextAlign.center,
          ),
          SizedBox(width: _desktopTableColumnGap),
          _DesktopCotizacionesHeaderCell(
            label: 'ESTADO',
            width: _desktopEstadoColumnWidth,
            textAlign: TextAlign.center,
          ),
          SizedBox(width: _desktopTableColumnGap),
          _DesktopCotizacionesHeaderCell(
            label: 'ACCIONES',
            width: _desktopActionsColumnWidth,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopCotizacionesTableRow(Cotizacion cotizacion) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: _desktopCodigoColumnWidth,
            child: Align(
              alignment: Alignment.center,
              child: _buildCodigoPill(_displayCodigo(cotizacion)),
            ),
          ),
          const SizedBox(width: _desktopTableColumnGap),
          Expanded(
            child: Text(
              cotizacion.referencia.trim().isEmpty
                  ? '-'
                  : cotizacion.referencia,
              overflow: TextOverflow.visible,
              softWrap: true,
              style: const TextStyle(
                color: _slate900,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: _desktopTableColumnGap),
          SizedBox(
            width: _desktopClienteColumnWidth,
            child: Text(
              cotizacion.clienteNombre,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _slate900,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: _desktopTableColumnGap),
          SizedBox(
            width: _desktopFechaColumnWidth,
            child: Text(
              _formatDate(cotizacion.fecha),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _slate700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: _desktopTableColumnGap),
          SizedBox(
            width: _desktopTotalColumnWidth,
            child: Text(
              PriceFormatter.formatCopWhole(cotizacion.total),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _slate900,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: _desktopTableColumnGap),
          SizedBox(
            width: _desktopEstadoColumnWidth,
            child: Align(
              alignment: Alignment.center,
              child: _buildEstadoBadge(cotizacion.estado),
            ),
          ),
          const SizedBox(width: _desktopTableColumnGap),
          SizedBox(
            width: _desktopActionsColumnWidth,
            child: Align(
              alignment: Alignment.center,
              child: _buildActionBar(cotizacion),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar(Cotizacion cotizacion, {bool compact = false}) {
    final canEdit = _canEditCotizaciones && !_isEstadoFinal(cotizacion.estado);
    final canMarkRealizada = _isAdministrador && cotizacion.estado == 'visto';
    final canMarkNula = _isAdministrador &&
        (cotizacion.estado == 'pendiente' || cotizacion.estado == 'visto');

    final viewButton = _buildActionButton(
      label: 'Ver',
      icon: Icons.visibility_outlined,
      onPressed: () => _openViewDialog(cotizacion),
      compact: compact,
    );

    final editButton = canEdit
        ? _buildActionButton(
            label: 'Editar',
            icon: Icons.edit_outlined,
            onPressed: () => _openEditDialog(cotizacion),
            compact: compact,
          )
        : null;

    final realizadaButton = canMarkRealizada
        ? _buildActionButton(
            label: 'Realizada',
            icon: Icons.check_circle_outline_rounded,
            onPressed: () => _confirmMarcarRealizada(cotizacion),
            compact: compact,
            filled: true,
            backgroundColor: _emerald600,
          )
        : null;

    final nulaButton = canMarkNula
        ? _buildActionButton(
            label: 'Nula',
            icon: Icons.block_outlined,
            onPressed: () => _confirmMarcarNula(cotizacion),
            compact: compact,
            filled: true,
            backgroundColor: _rose600,
          )
        : null;

    if (compact) {
      final hasSecondRow = realizadaButton != null || nulaButton != null;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: viewButton),
              const SizedBox(width: 8),
              Expanded(child: editButton ?? const SizedBox.shrink()),
            ],
          ),
          if (hasSecondRow) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: realizadaButton ?? const SizedBox.shrink()),
                const SizedBox(width: 8),
                Expanded(child: nulaButton ?? const SizedBox.shrink()),
              ],
            ),
          ],
        ],
      );
    }

    final hasSecondRow = realizadaButton != null || nulaButton != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildDesktopActionRow(
          primary: viewButton,
          secondary: editButton,
        ),
        if (hasSecondRow) ...[
          const SizedBox(height: 6),
          _buildDesktopActionRow(
            primary: realizadaButton,
            secondary: nulaButton,
          ),
        ],
      ],
    );
  }

  Widget _buildDesktopActionRow({
    Widget? primary,
    Widget? secondary,
  }) {
    return Row(
      children: [
        _buildDesktopActionSlot(primary),
        const SizedBox(width: _desktopTableColumnGap),
        _buildDesktopActionSlot(secondary),
      ],
    );
  }

  Widget _buildDesktopActionSlot(Widget? child) {
    return Expanded(
      child: child ?? const SizedBox.shrink(),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    required bool compact,
    bool filled = false,
    Color? backgroundColor,
  }) {
    final style = filled
        ? FilledButton.styleFrom(
            backgroundColor: backgroundColor ?? _slate900,
            foregroundColor: Colors.white,
            minimumSize: Size(
              compact ? 0 : _desktopActionButtonWidth,
              compact ? 40 : 32,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: compact ? 10 : 0,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          )
        : OutlinedButton.styleFrom(
            foregroundColor: _slate700,
            minimumSize: Size(
              compact ? 0 : _desktopActionButtonWidth,
              compact ? 40 : 32,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: compact ? 10 : 0,
            ),
            side: const BorderSide(color: _slate200),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          );

    final child = Text(
      label,
      style: TextStyle(
        fontSize: compact ? 12 : 13,
        fontWeight: FontWeight.w700,
      ),
    );

    final button = filled
        ? FilledButton.icon(
            onPressed: onPressed,
            style: style,
            icon: Icon(icon, size: 17),
            label: child,
          )
        : OutlinedButton.icon(
            onPressed: onPressed,
            style: style,
            icon: Icon(icon, size: 17),
            label: child,
          );

    return compact
        ? button
        : SizedBox(
            width: double.infinity,
            child: button,
          );
  }

  Widget _buildEstadoBadge(String estado) {
    final config = _statusConfig(estado);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: config.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: config.foreground.withValues(alpha: 0.16)),
      ),
      child: Text(
        config.label,
        style: TextStyle(
          color: config.foreground,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildCodigoPill(String codigo) {
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

  Widget _buildLabeledValue(String label, String value) {
    return Column(
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
        const SizedBox(height: 4),
        Text(
          value.isEmpty ? '-' : value,
          style: const TextStyle(
            color: _slate900,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _slate200),
      ),
      child: const Column(
        children: [
          Icon(Icons.request_quote_outlined, size: 44, color: _slate500),
          SizedBox(height: 14),
          Text(
            'No hay cotizaciones para esta consulta.',
            style: TextStyle(
              color: _slate900,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'Ajusta la busqueda, cambia el estado o crea una cotizacion nueva para empezar el flujo comercial.',
            style: TextStyle(color: _slate500, height: 1.45),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationCard(PaginatedCotizacionesResponse response) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _slate200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Pagina ${response.currentPage} de ${response.lastPage} · ${response.total} registros filtrados',
              style: const TextStyle(
                color: _slate700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: response.currentPage > 1
                ? () =>
                    unawaited(_controller.goToPage(response.currentPage - 1))
                : null,
            icon: const Icon(Icons.chevron_left_rounded),
            tooltip: 'Pagina anterior',
          ),
          Text(
            '${response.currentPage}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          IconButton(
            onPressed: response.currentPage < response.lastPage
                ? () =>
                    unawaited(_controller.goToPage(response.currentPage + 1))
                : null,
            icon: const Icon(Icons.chevron_right_rounded),
            tooltip: 'Pagina siguiente',
          ),
        ],
      ),
    );
  }

  Future<void> _refresh() {
    return _controller.refresh(silent: false, reason: 'pull-to-refresh');
  }

  Future<void> _openCreateDialog() async {
    final created = await Navigator.of(context).push<Cotizacion>(
      MaterialPageRoute(
        builder: (_) => CotizacionFormScreen(
          controller: _controller,
          onSubmit: _controller.createCotizacion,
          canEditFirma: _isAdministrador,
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

    if (!mounted || created == null) return;
    _showMessage('Cotización ${created.codigo} creada correctamente.');
  }

  Future<void> _openViewDialog(Cotizacion cotizacion) async {
    try {
      final detail = await _controller.fetchCotizacion(cotizacion.id);
      if (!mounted) return;

      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => CotizacionPreviewScreen(cotizacion: detail),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _showMessage('No fue posible cargar la cotización: $error');
    }
  }

  Future<void> _openEditDialog(Cotizacion cotizacion) async {
    final detail = await _controller.fetchCotizacion(cotizacion.id);
    if (!mounted) return;

    final updated = await Navigator.of(context).push<Cotizacion>(
      MaterialPageRoute(
        builder: (_) => CotizacionFormScreen(
          controller: _controller,
          initialCotizacion: detail,
          canEditFirma: _isAdministrador,
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
          onSubmit: (payload) =>
              _controller.updateCotizacion(cotizacion.id, payload),
        ),
      ),
    );

    if (!mounted || updated == null) return;
    _showMessage('Cotización ${updated.codigo} actualizada correctamente.');
  }

  Future<void> _confirmMarcarRealizada(Cotizacion cotizacion) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Marcar como realizada'),
        content: Text(
          'Se marcara ${_displayCodigo(cotizacion)} como realizada. Esta accion representa la decision final de administracion.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Marcar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final updated = await _controller.marcarRealizada(cotizacion);
      if (!mounted) return;
      _showMessage('Cotización ${updated.codigo} marcada como realizada.');
    } catch (error) {
      if (!mounted) return;
      _showMessage(
          'No fue posible marcar la cotización como realizada: $error');
    }
  }

  Future<void> _confirmMarcarNula(Cotizacion cotizacion) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Marcar como nula'),
        content: Text(
          'Se marcara ${_displayCodigo(cotizacion)} como nula. Esta accion mantiene la trazabilidad sin eliminar el registro.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final updated = await _controller.anularCotizacion(cotizacion);
      if (!mounted) return;
      _showMessage('Cotización ${updated.codigo} marcada como nula.');
    } catch (error) {
      if (!mounted) return;
      _showMessage('No fue posible marcar la cotización como nula: $error');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  _StatusConfig _statusConfig(String estado) {
    switch (estado) {
      case 'realizada':
        return const _StatusConfig(
          label: 'Realizada',
          background: Color(0xFFD1FAE5),
          foreground: _emerald600,
        );
      case 'visto':
        return const _StatusConfig(
          label: 'Visto',
          background: Color(0xFFFEF3C7),
          foreground: _amber700,
        );
      case 'nula':
        return const _StatusConfig(
          label: 'Nula',
          background: Color(0xFFFFE4E6),
          foreground: _rose600,
        );
      default:
        return const _StatusConfig(
          label: 'Pendiente',
          background: Color(0xFFE0F2FE),
          foreground: _cyan600,
        );
    }
  }

  bool _isEstadoFinal(String estado) {
    return estado == 'realizada' || estado == 'nula';
  }

  String _displayCodigo(Cotizacion cotizacion) {
    final raw =
        cotizacion.codigo.isNotEmpty ? cotizacion.codigo : cotizacion.numero;
    final match = RegExp(r'^COT-(?:\d{4}-)?(\d+)$').firstMatch(raw.trim());
    if (match == null) {
      return raw;
    }

    final sequence = int.tryParse(match.group(1) ?? '');
    if (sequence == null) {
      return raw;
    }

    return 'COT-${sequence.toString().padLeft(3, '0')}';
  }

  String _formatDate(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;

    final month = parsed.month.toString().padLeft(2, '0');
    final day = parsed.day.toString().padLeft(2, '0');
    return '$day/$month/${parsed.year}';
  }
}

class _StatusConfig {
  const _StatusConfig({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;
}

class _DesktopCotizacionesHeaderCell extends StatelessWidget {
  const _DesktopCotizacionesHeaderCell({
    required this.label,
    this.textAlign = TextAlign.left,
    this.width,
    this.flexible = false,
  });

  final String label;
  final TextAlign textAlign;
  final double? width;
  final bool flexible;

  @override
  Widget build(BuildContext context) {
    final content = Text(
      label,
      textAlign: textAlign,
      style: const TextStyle(
        color: _CotizacionesScreenState._slate500,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
      ),
    );

    if (width != null) {
      return SizedBox(
        width: width,
        child: Align(
          alignment: _alignmentFor(textAlign),
          child: content,
        ),
      );
    }

    if (flexible) {
      return Expanded(
        child: Align(
          alignment: _alignmentFor(textAlign),
          child: content,
        ),
      );
    }

    return content;
  }

  Alignment _alignmentFor(TextAlign textAlign) {
    switch (textAlign) {
      case TextAlign.center:
        return Alignment.center;
      case TextAlign.right:
      case TextAlign.end:
        return Alignment.centerRight;
      case TextAlign.left:
      case TextAlign.start:
      case TextAlign.justify:
        return Alignment.centerLeft;
    }
  }
}
