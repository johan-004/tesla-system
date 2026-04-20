import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/api/api_client.dart';
import '../../../core/layout/adaptive_layout.dart';
import '../../../shared/utils/price_formatter.dart';
import '../data/dashboard_repository.dart';
import '../domain/dashboard_summary.dart';

class DashboardOverview extends StatefulWidget {
  const DashboardOverview({
    super.key,
    required this.authController,
    this.onOpenProductos,
    this.onOpenServicios,
    this.onOpenCotizaciones,
    this.onOpenFacturas,
    this.compact = false,
  });

  final AuthController authController;
  final VoidCallback? onOpenProductos;
  final VoidCallback? onOpenServicios;
  final VoidCallback? onOpenCotizaciones;
  final VoidCallback? onOpenFacturas;
  final bool compact;

  @override
  State<DashboardOverview> createState() => _DashboardOverviewState();
}

class _DashboardOverviewState extends State<DashboardOverview> {
  static const _navy = Color(0xFF0F172A);
  static const _slate700 = Color(0xFF334155);
  static const _slate500 = Color(0xFF64748B);
  static const _slate300 = Color(0xFFCBD5E1);
  static const _slate200 = Color(0xFFE2E8F0);

  late DashboardRepository _repository;
  late Future<DashboardSummary> _future;

  @override
  void initState() {
    super.initState();
    _repository = DashboardRepository(
      ApiClient(
        token: widget.authController.token,
        tokenType: widget.authController.tokenType,
      ),
    );
    _future = _repository.fetchResumen();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop =
        !widget.compact && AdaptiveLayout.isDesktopContext(context);

    return FutureBuilder<DashboardSummary>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorState('${snapshot.error}');
        }

        final summary = snapshot.data;
        if (summary == null) {
          return _buildErrorState('No se recibió información del dashboard.');
        }

        return ListView(
          padding: EdgeInsets.all(isDesktop ? 28 : 16),
          children: [
            _buildHero(summary),
            const SizedBox(height: 18),
            _buildKpiBlock(summary, isDesktop: isDesktop),
            const SizedBox(height: 18),
            _buildChartsBlock(summary, isDesktop: isDesktop),
            const SizedBox(height: 18),
            _buildOperativeBlock(summary, isDesktop: isDesktop),
            const SizedBox(height: 12),
            _buildQuickAccess(isDesktop: isDesktop),
          ],
        );
      },
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFFECACA)),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Color(0xFFB91C1C)),
                const SizedBox(height: 10),
                Text(
                  'No fue posible cargar el dashboard',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF7F1D1D),
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF7F1D1D)),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () {
                    setState(() {
                      _future = _repository.fetchResumen();
                    });
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero(DashboardSummary summary) {
    final periodo = [summary.periodoMesInicio, summary.periodoMesFin]
        .whereType<String>()
        .where((value) => value.trim().isNotEmpty)
        .join(' al ');

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF134E4A), Color(0xFF0F766E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dashboard operativo',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Flujo real: productos para inventario, servicios para cotizar, cotizaciones como gestión comercial y facturas como ingreso final.',
            style: const TextStyle(color: Color(0xFFE2E8F0), height: 1.45),
          ),
          if (periodo.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Corte mes actual: $periodo',
              style: const TextStyle(
                color: Color(0xFFCCFBF1),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildKpiBlock(DashboardSummary summary, {required bool isDesktop}) {
    final kpis = [
      _KpiData('Cotizaciones pendientes',
          '${summary.kpis.cotizacionesPendientes}', Icons.schedule_outlined),
      _KpiData('Cotizaciones vistas', '${summary.kpis.cotizacionesVistas}',
          Icons.visibility_outlined),
      _KpiData('Cotizaciones realizadas',
          '${summary.kpis.cotizacionesRealizadas}', Icons.task_alt_outlined),
      _KpiData('Facturas borrador', '${summary.kpis.facturasBorrador}',
          Icons.edit_document),
      _KpiData('Facturas emitidas', '${summary.kpis.facturasEmitidas}',
          Icons.receipt_long_outlined),
      _KpiData(
          'Total facturado del mes',
          PriceFormatter.formatCopWhole(summary.kpis.totalFacturadoMes),
          Icons.paid_outlined),
      _KpiData('Productos con stock bajo', '${summary.kpis.productosStockBajo}',
          Icons.inventory_2_outlined),
      _KpiData('Productos inactivos', '${summary.kpis.productosInactivos}',
          Icons.inventory_outlined),
    ];

    final cardWidth = isDesktop ? 260.0 : 180.0;

    return _SectionCard(
      title: 'KPI',
      subtitle: 'Indicadores principales del flujo comercial y operativo.',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final kpi in kpis)
            SizedBox(
              width: cardWidth,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: const Color(0xFFF8FAFC),
                  border: Border.all(color: _slate200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(kpi.icon, color: const Color(0xFF0F766E), size: 20),
                    const SizedBox(height: 8),
                    Text(
                      kpi.value,
                      style: const TextStyle(
                        color: _navy,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      kpi.label,
                      style: const TextStyle(color: _slate500, height: 1.35),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChartsBlock(DashboardSummary summary,
      {required bool isDesktop}) {
    return _SectionCard(
      title: 'Graficas',
      subtitle:
          'Lectura rápida de estados, facturación mensual y servicios más cotizados.',
      child: Column(
        children: [
          _buildEstadoChart(summary.cotizacionesPorEstado),
          const SizedBox(height: 14),
          _buildFacturacionMensualChart(summary.facturacionPorMes),
          const SizedBox(height: 14),
          _buildTopServiciosChart(summary.serviciosTopCotizados,
              isDesktop: isDesktop),
        ],
      ),
    );
  }

  Widget _buildEstadoChart(List<EstadoTotal> items) {
    final maxValue =
        items.fold<int>(0, (max, item) => item.total > max ? item.total : max);
    final safeMax = maxValue <= 0 ? 1 : maxValue;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cotizaciones por estado',
            style: TextStyle(color: _navy, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                children: [
                  SizedBox(
                    width: 82,
                    child: Text(
                      _estadoLabel(item.estado),
                      style: const TextStyle(color: _slate700, fontSize: 13),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        minHeight: 10,
                        value: item.total / safeMax,
                        backgroundColor: const Color(0xFFE2E8F0),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _estadoColor(item.estado),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 24,
                    child: Text(
                      '${item.total}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: _navy,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFacturacionMensualChart(List<PeriodoTotal> items) {
    final maxValue = items.fold<double>(
        0, (max, item) => item.total > max ? item.total : max);
    final safeMax = maxValue <= 0 ? 1 : maxValue;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Facturación por mes (emitidas)',
            style: TextStyle(color: _navy, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final item in items)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                width: double.infinity,
                                constraints: BoxConstraints(
                                  minHeight: item.total <= 0 ? 4 : 18,
                                ),
                                height: ((item.total / safeMax) * 120)
                                    .clamp(4, 120),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: const Color(0xFF0F766E),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _mesLabel(item.label),
                            style: const TextStyle(
                              color: _slate700,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopServiciosChart(
    List<ServicioTop> items, {
    required bool isDesktop,
  }) {
    final maxValue =
        items.fold<int>(0, (max, item) => item.veces > max ? item.veces : max);
    final safeMax = maxValue <= 0 ? 1 : maxValue;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Servicios más usados en cotizaciones',
            style: TextStyle(color: _navy, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            const Text(
              'Aún no hay servicios cotizados para mostrar un top.',
              style: TextStyle(color: _slate500),
            ),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.servicio,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _navy,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: LinearProgressIndicator(
                            minHeight: 8,
                            value: item.veces / safeMax,
                            backgroundColor: const Color(0xFFE2E8F0),
                            valueColor: const AlwaysStoppedAnimation(
                              Color(0xFF0EA5E9),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${item.veces} usos',
                        style: const TextStyle(
                          color: _slate700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: isDesktop ? 130 : 120,
                        child: Text(
                          PriceFormatter.formatCopWhole(item.valorTotal),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: _slate700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOperativeBlock(
    DashboardSummary summary, {
    required bool isDesktop,
  }) {
    final cotizaciones = _buildSimpleListSection(
      title: 'Últimas cotizaciones',
      rows: summary.ultimasCotizaciones
          .map((item) => _SimpleRow(
                title: item.codigo,
                subtitle:
                    '${item.clienteNombre} · ${_estadoLabel(item.estado)} · ${_shortDate(item.fecha)}',
                trailing: PriceFormatter.formatCopWhole(item.total),
              ))
          .toList(),
    );

    final facturas = _buildSimpleListSection(
      title: 'Últimas facturas emitidas',
      rows: summary.ultimasFacturasEmitidas
          .map((item) => _SimpleRow(
                title: item.codigo,
                subtitle: '${item.clienteNombre} · ${_shortDate(item.fecha)}',
                trailing: PriceFormatter.formatCopWhole(item.total),
              ))
          .toList(),
    );

    final stockBajo = _buildSimpleListSection(
      title: 'Productos con stock bajo',
      rows: summary.productosStockBajo
          .map((item) => _SimpleRow(
                title: '${item.codigo} · ${item.nombre}',
                subtitle: 'Stock actual: ${item.stock} ${item.unidadMedida}',
                trailing: 'Bajo',
              ))
          .toList(),
      emptyMessage: 'No hay productos con stock bajo en este momento.',
    );

    final inactivos = _buildSimpleListSection(
      title: 'Productos inactivos',
      rows: summary.productosInactivos
          .map((item) => _SimpleRow(
                title: '${item.codigo} · ${item.nombre}',
                subtitle: 'Stock: ${item.stock} ${item.unidadMedida}',
                trailing: 'Inactivo',
              ))
          .toList(),
      emptyMessage: 'No hay productos inactivos registrados.',
    );

    if (!isDesktop) {
      return Column(
        children: [
          cotizaciones,
          const SizedBox(height: 12),
          facturas,
          const SizedBox(height: 12),
          stockBajo,
          const SizedBox(height: 12),
          inactivos,
        ],
      );
    }

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: cotizaciones),
            const SizedBox(width: 12),
            Expanded(child: facturas),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: stockBajo),
            const SizedBox(width: 12),
            Expanded(child: inactivos),
          ],
        ),
      ],
    );
  }

  Widget _buildSimpleListSection({
    required String title,
    required List<_SimpleRow> rows,
    String emptyMessage = 'Sin registros aún.',
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: _navy, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          if (rows.isEmpty)
            Text(
              emptyMessage,
              style: const TextStyle(color: _slate500),
            ),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          row.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _slate700,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          row.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _slate500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    row.trailing,
                    style: const TextStyle(
                      color: _navy,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickAccess({required bool isDesktop}) {
    final accesses = [
      _AccessData(
        title: 'Productos',
        subtitle: 'Inventario y stock.',
        icon: Icons.inventory_2_outlined,
        onTap: widget.onOpenProductos,
      ),
      _AccessData(
        title: 'Servicios',
        subtitle: 'Catálogo comercial/técnico.',
        icon: Icons.design_services_outlined,
        onTap: widget.onOpenServicios,
      ),
      _AccessData(
        title: 'Cotizaciones',
        subtitle: 'Gestión comercial.',
        icon: Icons.request_quote_outlined,
        onTap: widget.onOpenCotizaciones,
      ),
      _AccessData(
        title: 'Facturas',
        subtitle: 'Ingreso final.',
        icon: Icons.receipt_long_outlined,
        onTap: widget.onOpenFacturas,
      ),
    ];

    return _SectionCard(
      title: 'Accesos rápidos',
      subtitle: 'Navegación directa a los módulos del flujo.',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final access in accesses)
            SizedBox(
              width: isDesktop ? 220 : double.infinity,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: access.onTap,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _slate200),
                  ),
                  child: Row(
                    children: [
                      Icon(access.icon, color: const Color(0xFF0F766E)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              access.title,
                              style: const TextStyle(
                                color: _navy,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              access.subtitle,
                              style: const TextStyle(
                                color: _slate500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: _slate300),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _estadoLabel(String rawEstado) {
    final estado = rawEstado.trim().toLowerCase();
    switch (estado) {
      case 'pendiente':
        return 'Pendiente';
      case 'visto':
        return 'Visto';
      case 'realizada':
        return 'Realizada';
      case 'nula':
        return 'Nula';
      default:
        return estado.isEmpty ? '-' : estado;
    }
  }

  Color _estadoColor(String rawEstado) {
    final estado = rawEstado.trim().toLowerCase();
    switch (estado) {
      case 'pendiente':
        return const Color(0xFFF59E0B);
      case 'visto':
        return const Color(0xFF0EA5E9);
      case 'realizada':
        return const Color(0xFF10B981);
      case 'nula':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF94A3B8);
    }
  }

  String _mesLabel(String label) {
    final parts = label.trim().split(' ');
    return parts.isEmpty ? label : parts.first;
  }

  String _shortDate(String? rawDate) {
    final value = (rawDate ?? '').trim();
    if (value.isEmpty) {
      return 'Sin fecha';
    }

    final datePart = value.length >= 10 ? value.substring(0, 10) : value;
    final chunks = datePart.split('-');
    if (chunks.length != 3) {
      return datePart;
    }

    return '${chunks[2]}/${chunks[1]}/${chunks[0]}';
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: Color(0xFF64748B), height: 1.35),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _KpiData {
  const _KpiData(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;
}

class _SimpleRow {
  const _SimpleRow({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final String title;
  final String subtitle;
  final String trailing;
}

class _AccessData {
  const _AccessData({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;
}
