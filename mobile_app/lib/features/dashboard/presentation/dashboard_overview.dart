import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/auth/auth_controller.dart';
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
    this.showHeader = true,
  });

  final AuthController authController;
  final VoidCallback? onOpenProductos;
  final VoidCallback? onOpenServicios;
  final VoidCallback? onOpenCotizaciones;
  final VoidCallback? onOpenFacturas;
  final bool compact;
  final bool showHeader;

  @override
  State<DashboardOverview> createState() => _DashboardOverviewState();
}

class _DashboardOverviewState extends State<DashboardOverview> {
  static const _bg = Color(0xFFF3F6FB);
  static const _card = Colors.white;
  static const _textMain = Color(0xFF0F1D3A);
  static const _textSub = Color(0xFF5D6D8A);
  static const _teal = Color(0xFF0C9A6A);

  late DashboardRepository _repository;
  late Future<DashboardSummary> _future;
  late int _selectedMonth;
  late int _selectedYear;
  int? _activeDailyPointIndex;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = now.month;
    _selectedYear = now.year;
    _repository = DashboardRepository(
      ApiClient(
        token: widget.authController.token,
        tokenType: widget.authController.tokenType,
      ),
    );
    _future = _repository.fetchResumen(
      mes: _selectedMonth,
      anio: _selectedYear,
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = widget.compact || width < 950;

    return Container(
      color: _bg,
      child: FutureBuilder<DashboardSummary>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final error = snapshot.error;
            final message = error is ApiException ? error.message : '$error';
            return _errorState(message);
          }
          final summary = snapshot.data;
          if (summary == null) {
            return _errorState('No se recibió información del dashboard.');
          }

          if (widget.compact) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  if (widget.showHeader) _header(summary, true),
                  if (widget.showHeader) const SizedBox(height: 14),
                  if (!widget.showHeader) _filtersOnly(summary, true),
                  if (!widget.showHeader) const SizedBox(height: 14),
                  _kpis(summary, true),
                  const SizedBox(height: 14),
                  _mainCharts(summary, true),
                  const SizedBox(height: 14),
                  _analysisRow(summary, true),
                  const SizedBox(height: 14),
                  _bottomRow(summary, true),
                ],
              ),
            );
          }

          final list = ListView(
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.all(isMobile ? 14 : 22),
            children: [
              if (widget.showHeader) _header(summary, isMobile),
              if (widget.showHeader) const SizedBox(height: 14),
              if (!widget.showHeader) _filtersOnly(summary, isMobile),
              if (!widget.showHeader) const SizedBox(height: 14),
              _kpis(summary, isMobile),
              const SizedBox(height: 14),
              _mainCharts(summary, isMobile),
              const SizedBox(height: 14),
              _analysisRow(summary, isMobile),
              const SizedBox(height: 14),
              _bottomRow(summary, isMobile),
            ],
          );

          return RefreshIndicator(
            onRefresh: _refresh,
            child: list,
          );
        },
      ),
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _repository.fetchResumen(
        mes: _selectedMonth,
        anio: _selectedYear,
      );
    });
    await _future;
  }

  Widget _header(DashboardSummary summary, bool isMobile) {
    final business = summary.businessDashboard;
    final title = _formatRange(business.periodo.inicio, business.periodo.fin);
    final userName = widget.authController.userName?.trim().isNotEmpty == true
        ? widget.authController.userName!.trim()
        : 'Admin Tesla';

    final availableYears = summary.aniosDisponibles.isEmpty
        ? <int>[_selectedYear]
        : summary.aniosDisponibles;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dashboard',
                      style: TextStyle(
                          color: _textMain,
                          fontSize: isMobile ? 20 : 40,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(
                      isMobile
                          ? 'Resumen general de tu negocio'
                          : 'Resumen general de tu negocio en tiempo real.',
                      style: TextStyle(
                          color: _textSub, fontSize: isMobile ? 13 : 16)),
                ],
              ),
            ),
            if (!isMobile)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: _box(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(userName,
                        style: const TextStyle(
                            color: _textMain, fontWeight: FontWeight.w700)),
                    const Text('Administrador',
                        style: TextStyle(color: _textSub, fontSize: 12)),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (isMobile)
          Wrap(
            runSpacing: 10,
            spacing: 10,
            children: [
              _chipButton(
                icon: Icons.calendar_today_outlined,
                text: title,
                minWidth: double.infinity,
              ),
              SizedBox(
                width: 180,
                child: _monthSelector(),
              ),
              IconButton(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: _card,
                  side: const BorderSide(color: Color(0xFFDCE3EF)),
                ),
                tooltip: 'Actualizar',
              ),
            ],
          )
        else
          Wrap(
            runSpacing: 10,
            spacing: 10,
            children: [
              _chipButton(
                icon: Icons.calendar_today_outlined,
                text: title,
                minWidth: 255,
              ),
              SizedBox(
                width: 180,
                child: _monthSelector(),
              ),
              SizedBox(
                width: 130,
                child: _yearSelector(availableYears),
              ),
              IconButton(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: _card,
                  side: const BorderSide(color: Color(0xFFDCE3EF)),
                ),
                tooltip: 'Actualizar',
              ),
            ],
          ),
      ],
    );
  }

  Widget _filtersOnly(DashboardSummary summary, bool isMobile) {
    final business = summary.businessDashboard;
    final title = _formatRange(business.periodo.inicio, business.periodo.fin);
    final availableYears = summary.aniosDisponibles.isEmpty
        ? <int>[_selectedYear]
        : summary.aniosDisponibles;

    return Wrap(
      runSpacing: 10,
      spacing: 10,
      children: [
        _chipButton(
          icon: Icons.calendar_today_outlined,
          text: title,
          minWidth: isMobile ? double.infinity : 255,
        ),
        SizedBox(width: 180, child: _monthSelector()),
        if (!isMobile)
          SizedBox(width: 130, child: _yearSelector(availableYears)),
        IconButton(
          onPressed: _refresh,
          icon: const Icon(Icons.refresh_rounded),
          style: IconButton.styleFrom(
            backgroundColor: _card,
            side: const BorderSide(color: Color(0xFFDCE3EF)),
          ),
          tooltip: 'Actualizar',
        ),
      ],
    );
  }

  Widget _monthSelector() {
    return DropdownButtonFormField<int>(
      initialValue: _selectedMonth,
      items: List.generate(
        12,
        (index) => DropdownMenuItem(
          value: index + 1,
          child: Text(_monthLabel(index + 1)),
        ),
      ),
      decoration: _inputDecoration(),
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          _selectedMonth = value;
          _future = _repository.fetchResumen(
            mes: _selectedMonth,
            anio: _selectedYear,
          );
        });
      },
    );
  }

  Widget _yearSelector(List<int> availableYears) {
    return DropdownButtonFormField<int>(
      initialValue: availableYears.contains(_selectedYear)
          ? _selectedYear
          : availableYears.first,
      items: availableYears
          .map(
            (year) => DropdownMenuItem<int>(
              value: year,
              child: Text('$year'),
            ),
          )
          .toList(),
      decoration: _inputDecoration(),
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          _selectedYear = value;
          _future = _repository.fetchResumen(
            mes: _selectedMonth,
            anio: _selectedYear,
          );
        });
      },
    );
  }

  String _monthLabel(int month) {
    const labels = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre'
    ];
    return labels[(month - 1).clamp(0, 11)];
  }

  Widget _kpis(DashboardSummary summary, bool isMobile) {
    final desktopEmbedded = !widget.showHeader;
    final k = summary.businessDashboard.kpis;
    final cards = [
      _kpiCard('Ventas (Facturas)', k.ventasFacturas, Icons.attach_money,
          const Color(0xFFDDF7EE), const Color(0xFF10A068),
          isMoney: true),
      _kpiCard(
          'Facturas emitidas',
          k.facturasEmitidas,
          Icons.receipt_long_outlined,
          const Color(0xFFE3F0FF),
          const Color(0xFF2D8DF0)),
      _kpiCard(
          'Cotizaciones enviadas',
          k.cotizacionesEnviadas,
          Icons.request_quote_outlined,
          const Color(0xFFF0E8FF),
          const Color(0xFF8A49FF)),
      _kpiCard(
          'Productos vendidos',
          k.productosVendidos,
          Icons.inventory_2_outlined,
          const Color(0xFFFFF2E2),
          const Color(0xFFEF8F1B)),
      _kpiCard(
          'Servicios facturados',
          k.serviciosFacturados,
          Icons.design_services_outlined,
          const Color(0xFFF2ECFF),
          const Color(0xFF7B45E8)),
    ];

    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 10),
              Expanded(child: cards[1]),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: cards[2]),
              const SizedBox(width: 10),
              Expanded(child: cards[3]),
            ],
          ),
          const SizedBox(height: 10),
          cards[4],
        ],
      );
    }

    return GridView.builder(
      itemCount: cards.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        childAspectRatio: desktopEmbedded ? 1.95 : 1.85,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (_, i) => cards[i],
    );
  }

  Widget _kpiCard(String title, KpiWithVariation kpi, IconData icon,
      Color bgIcon, Color iconColor,
      {bool isMoney = false}) {
    final desktopEmbedded = !widget.showHeader;
    final isMobile = widget.compact || MediaQuery.of(context).size.width < 950;
    final down = kpi.variacionPct < 0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _box(),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
                color: bgIcon, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: _textSub,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  isMoney
                      ? PriceFormatter.formatCopWhole(kpi.valor)
                      : _formatQty(kpi.valor),
                  style: TextStyle(
                      color: _textMain,
                      fontSize: isMobile ? 20 : (desktopEmbedded ? 22 : 30),
                      height: 1,
                      fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  kpi.variacionPct == 0
                      ? 'Sin comparación'
                      : '${down ? '↓' : '↑'} ${kpi.variacionPct.abs().toStringAsFixed(1)}% vs periodo anterior',
                  style: TextStyle(
                      color: down ? const Color(0xFFD92D20) : _teal,
                      fontSize: isMobile ? 11 : (desktopEmbedded ? 11 : 12),
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mainCharts(DashboardSummary summary, bool isMobile) {
    if (widget.compact) {
      return Column(children: [
        _dailySalesCard(summary),
        const SizedBox(height: 10),
        _yearSalesCard(summary)
      ]);
    }

    final width = MediaQuery.of(context).size.width;
    final useTwoColumnsInMobile = isMobile && width >= 780;
    final row = [
      Expanded(child: _dailySalesCard(summary)),
      const SizedBox(width: 10),
      Expanded(child: _yearSalesCard(summary)),
    ];
    if (isMobile && !useTwoColumnsInMobile) {
      return Column(children: [
        _dailySalesCard(summary),
        const SizedBox(height: 10),
        _yearSalesCard(summary)
      ]);
    }
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: row);
  }

  Widget _dailySalesCard(DashboardSummary summary) {
    final data = summary.businessDashboard.graficas.ventasDiariasPeriodo;
    final total = data.fold<double>(0, (sum, item) => sum + item.facturado);
    final compactMode = widget.compact;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _box(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _chartHeader('Ventas diarias (Este mes)',
            'Total: ${PriceFormatter.formatCopWhole(total)}',
            onExpand: () => _openExpandedChart(
                  title: 'Ventas diarias',
                  subtitle: 'Total: ${PriceFormatter.formatCopWhole(total)}',
                  child: _lineChart(data, height: 320),
                )),
        const SizedBox(height: 10),
        data.isEmpty || total <= 0
            ? _empty('Aún no hay ventas en este periodo.')
            : _lineChart(data, height: compactMode ? 150 : 210),
      ]),
    );
  }

  Widget _yearSalesCard(DashboardSummary summary) {
    final data = summary.businessDashboard.graficas.ventasMensualesAnio;
    final total = data.fold<double>(0, (sum, item) => sum + item.total);
    final compactMode = widget.compact;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _box(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _chartHeader('Ventas por mes (Este año)',
            'Total anual: ${PriceFormatter.formatCopWhole(total)}',
            rightLabel: 'Barras',
            onExpand: () => _openExpandedChart(
                  title: 'Ventas por mes',
                  subtitle:
                      'Total anual: ${PriceFormatter.formatCopWhole(total)}',
                  child: _barChart(data, height: 320),
                )),
        const SizedBox(height: 10),
        total <= 0
            ? _empty('Aún no hay ventas registradas en este año.')
            : _barChart(data, height: compactMode ? 150 : 210),
      ]),
    );
  }

  Widget _analysisRow(DashboardSummary summary, bool isMobile) {
    if (widget.compact) {
      return Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SizedBox(
                  height: 340,
                  child: _donutCard(
                    title: 'Ventas por categoría',
                    data: _top3PlusOthers(
                      summary.businessDashboard.graficas
                          .ventasPorCategoriaProductos,
                    ),
                    emptyMessage:
                        'Aún no hay productos vendidos en este periodo.',
                    isMobile: true,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 340,
                  child: _donutCard(
                    title: 'Ventas por tipo',
                    data: summary.businessDashboard.graficas.ventasPorTipo,
                    emptyMessage: 'Aún no hay ventas en este periodo.',
                    isMobile: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _top5Card(summary, isMobile: true),
        ],
      );
    }

    final width = MediaQuery.of(context).size.width;
    final useThreeColumnsInMobile = isMobile && width >= 1100;
    final desktopEmbedded = !widget.showHeader;
    final compactMode = widget.compact;
    final analysisCardHeight =
        compactMode ? 250.0 : (desktopEmbedded ? 300.0 : 330.0);
    final cards = [
      Expanded(
        child: SizedBox(
          height: analysisCardHeight,
          child: _donutCard(
            title: 'Ventas por categoría (Productos)',
            data: _top3PlusOthers(
              summary.businessDashboard.graficas.ventasPorCategoriaProductos,
            ),
            emptyMessage: 'Aún no hay productos vendidos en este periodo.',
            isMobile: compactMode,
          ),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: SizedBox(
          height: analysisCardHeight,
          child: _donutCard(
            title: 'Ventas por tipo',
            data: summary.businessDashboard.graficas.ventasPorTipo,
            emptyMessage: 'Aún no hay ventas en este periodo.',
            isMobile: compactMode,
          ),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: SizedBox(
          height: analysisCardHeight,
          child: _top5Card(summary, isMobile: compactMode),
        ),
      ),
    ];

    if (isMobile && !useThreeColumnsInMobile) {
      return Column(children: [
        _donutCard(
          title: 'Ventas por categoría (Productos)',
          data: _top3PlusOthers(
            summary.businessDashboard.graficas.ventasPorCategoriaProductos,
          ),
          emptyMessage: 'Aún no hay productos vendidos en este periodo.',
          isMobile: true,
        ),
        const SizedBox(height: 10),
        _donutCard(
          title: 'Ventas por tipo',
          data: summary.businessDashboard.graficas.ventasPorTipo,
          emptyMessage: 'Aún no hay ventas en este periodo.',
          isMobile: true,
        ),
        const SizedBox(height: 10),
        _top5Card(summary, isMobile: true),
      ]);
    }

    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: cards);
  }

  Widget _donutCard({
    required String title,
    required VentasDistribucion data,
    required String emptyMessage,
    bool isMobile = false,
  }) {
    final desktopEmbedded = !widget.showHeader;
    final donutSize = isMobile ? 132.0 : (desktopEmbedded ? 174.0 : 262.0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _box(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: TextStyle(
                color: _textMain,
                fontSize: isMobile ? 17 : (desktopEmbedded ? 18 : 26),
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        if (data.total <= 0 || data.items.isEmpty)
          _empty(emptyMessage)
        else if (isMobile)
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: donutSize,
                  height: donutSize,
                  child: _donut(data),
                ),
                const SizedBox(height: 10),
                ...data.items.asMap().entries.map((e) => _legendRow(
                      e.value,
                      _segmentColors[e.key % _segmentColors.length],
                      isMobile: true,
                      centered: true,
                    )),
              ],
            ),
          )
        else
          Align(
            alignment: Alignment.center,
            child:
                Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              SizedBox(
                width: donutSize,
                height: donutSize,
                child: _donut(data),
              ),
              const SizedBox(width: 30),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: data.items
                      .asMap()
                      .entries
                      .map((e) => _legendRow(
                            e.value,
                            _segmentColors[e.key % _segmentColors.length],
                            isMobile: false,
                          ))
                      .toList(),
                ),
              ),
            ]),
          ),
      ]),
    );
  }

  Widget _legendRow(VentasDistribucionItem item, Color color,
      {bool isMobile = false, bool centered = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isMobile ? 4 : 9),
      child: Row(children: [
        Container(
            width: isMobile ? 8 : 10,
            height: isMobile ? 8 : 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        SizedBox(width: isMobile ? 7 : 10),
        Expanded(
          child: Column(
            crossAxisAlignment:
                centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
            children: [
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _textSub,
                  fontSize: isMobile ? 10 : 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: isMobile ? 1 : 2),
              Text(
                '${PriceFormatter.formatCopWhole(item.valor)} (${item.porcentaje.toStringAsFixed(1)}%)',
                style: TextStyle(
                  color: _textSub,
                  fontSize: isMobile ? 9.5 : 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _top5Card(DashboardSummary summary, {bool isMobile = false}) {
    final desktopEmbedded = !widget.showHeader;
    final items = summary.businessDashboard.topItemsVendidos;
    final maxValue = items.isEmpty
        ? 0
        : items.map((e) => e.valorTotal).reduce((a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _box(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Top 5 ítems más vendidos (Este mes)',
            style: TextStyle(
                color: _textMain,
                fontSize: isMobile ? 17 : (desktopEmbedded ? 18 : 26),
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        if (items.isEmpty)
          _empty('Aún no hay ítems vendidos en este periodo.')
        else
          ...items.map((item) {
            final ratio = maxValue <= 0
                ? 0.0
                : (item.valorTotal / maxValue).clamp(0.0, 1.0).toDouble();
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.descripcion.trim().isEmpty
                                ? 'Ítem sin descripción'
                                : item.descripcion,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _textMain,
                              fontWeight: FontWeight.w700,
                              fontSize: isMobile ? 12 : 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${_formatQty(item.cantidad)} ${_normalizeTopUnit(item.unidad)}',
                          style: TextStyle(
                            color: _textSub,
                            fontSize: isMobile ? 11.5 : 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          PriceFormatter.formatCopWhole(item.valorTotal),
                          style: TextStyle(
                            color: _textMain,
                            fontWeight: FontWeight.w800,
                            fontSize: isMobile ? 11.5 : 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LayoutBuilder(builder: (context, constraints) {
                      final barTrackWidth =
                          math.max(24.0, constraints.maxWidth * 0.64);
                      return Row(
                        children: [
                          SizedBox(
                            width: barTrackWidth,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                minHeight: 6,
                                value: ratio,
                                backgroundColor: const Color(0xFFE6EDF7),
                                valueColor: const AlwaysStoppedAnimation(_teal),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ]),
            );
          }),
      ]),
    );
  }

  VentasDistribucion _top3PlusOthers(VentasDistribucion source) {
    if (source.items.length <= 4) {
      return source;
    }

    final sorted = [...source.items]
      ..sort((a, b) => b.valor.compareTo(a.valor));
    final top3 = sorted.take(3).toList();
    final others = sorted.skip(3);
    final othersTotal = others.fold<double>(0, (sum, item) => sum + item.valor);

    final total = source.total <= 0
        ? top3.fold<double>(0, (sum, item) => sum + item.valor) + othersTotal
        : source.total;

    final items = <VentasDistribucionItem>[
      ...top3.map(
        (item) => VentasDistribucionItem(
          label: item.label,
          valor: item.valor,
          porcentaje: total > 0 ? (item.valor / total) * 100 : 0,
        ),
      ),
    ];

    if (othersTotal > 0) {
      items.add(
        VentasDistribucionItem(
          label: 'Otros',
          valor: othersTotal,
          porcentaje: total > 0 ? (othersTotal / total) * 100 : 0,
        ),
      );
    }

    return VentasDistribucion(total: total, items: items);
  }

  String _normalizeTopUnit(String rawUnit) {
    final unit = rawUnit.trim().toLowerCase();
    if (unit.isEmpty) return 'uds';
    switch (unit) {
      case 'und':
      case 'unidad':
      case 'un':
        return 'uds';
      case 'global':
        return 'srv';
      default:
        return unit;
    }
  }

  Widget _bottomRow(DashboardSummary summary, bool isMobile) {
    if (widget.compact) {
      return Column(children: [
        _estadoDocs(summary),
        const SizedBox(height: 10),
        _resumenFinanciero(summary),
      ]);
    }

    final width = MediaQuery.of(context).size.width;
    final useTwoColumnsInMobile = isMobile && width >= 1000;
    if (isMobile) {
      if (!useTwoColumnsInMobile) {
        return Column(children: [
          _estadoDocs(summary),
          const SizedBox(height: 10),
          _resumenFinanciero(summary),
        ]);
      }
    }
    final desktopEmbedded = !widget.showHeader;
    final bottomCardHeight =
        widget.compact ? 282.0 : (desktopEmbedded ? 330.0 : 370.0);
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(
        child: SizedBox(
          height: bottomCardHeight,
          child: _estadoDocs(summary),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: SizedBox(
          height: bottomCardHeight,
          child: _resumenFinanciero(summary),
        ),
      ),
    ]);
  }

  Widget _estadoDocs(DashboardSummary summary) {
    final desktopEmbedded = !widget.showHeader;
    final compactMode = widget.compact;
    final estado = summary.businessDashboard.estadoDocumentos;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _box(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Estado de documentos',
            style: TextStyle(
                color: _textMain,
                fontSize: compactMode ? 18 : (desktopEmbedded ? 18 : 28),
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        if (compactMode) ...[
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 214,
                  child: _estadoCard(
                    'Cotizaciones',
                    estado.cotizaciones,
                    const Color(0xFFEAF3FF),
                    Icons.request_quote_outlined,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 214,
                  child: _estadoCard(
                    'Facturas',
                    estado.facturas,
                    const Color(0xFFF0E9FF),
                    Icons.receipt_long_outlined,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 214,
            child: _estadoCard(
              'Productos',
              estado.productos,
              const Color(0xFFFFF3E8),
              Icons.inventory_2_outlined,
            ),
          ),
        ] else
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _estadoCard(
                    'Cotizaciones',
                    estado.cotizaciones,
                    const Color(0xFFEAF3FF),
                    Icons.request_quote_outlined,
                  ),
                ),
                SizedBox(width: compactMode ? 8 : 12),
                Expanded(
                  child: _estadoCard(
                    'Facturas',
                    estado.facturas,
                    const Color(0xFFF0E9FF),
                    Icons.receipt_long_outlined,
                  ),
                ),
                SizedBox(width: compactMode ? 8 : 12),
                Expanded(
                  child: _estadoCard(
                    'Productos',
                    estado.productos,
                    const Color(0xFFFFF3E8),
                    Icons.inventory_2_outlined,
                  ),
                ),
              ],
            ),
          ),
      ]),
    );
  }

  Widget _estadoCard(
      String title, EstadoDocumentoCard card, Color bg, IconData icon) {
    final compactMode = widget.compact;
    final colors = [
      const Color(0xFFF59E0B),
      const Color(0xFF16A34A),
      const Color(0xFFDC2626)
    ];
    final rows = _estadoRowsForCard(title, card);
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: compactMode ? 10 : 14, vertical: compactMode ? 10 : 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDE5F3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Icon(icon, color: const Color(0xFF35507E)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                    color: _textMain, fontWeight: FontWeight.w700),
              ),
            ),
          ]),
          Text(
            '${card.total}',
            style: const TextStyle(
              fontSize: 34,
              height: 1,
              color: _textMain,
              fontWeight: FontWeight.w800,
            ),
          ),
          Column(
            children: rows.asMap().entries.map((entry) {
              final color = colors[entry.key % colors.length];
              return Padding(
                padding: EdgeInsets.only(bottom: compactMode ? 6 : 10),
                child: Row(children: [
                  Container(
                      width: 8,
                      height: 8,
                      decoration:
                          BoxDecoration(color: color, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${entry.value.$1}: ${entry.value.$2}',
                      style: TextStyle(
                        color: _textSub,
                        fontSize: compactMode ? 11.5 : 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ]),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  List<(String, int)> _estadoRowsForCard(
      String title, EstadoDocumentoCard card) {
    final type = title.trim().toLowerCase();
    if (type.contains('cotizacion')) {
      return [
        ('Pendientes', _metricValue(card, ['pendientes', 'pendiente'])),
        (
          'Realizadas',
          _metricValue(
              card, ['realizadas', 'realizada', 'aceptadas', 'aceptada'])
        ),
        ('Nulas', _metricValue(card, ['nulas', 'nula', 'vencidas', 'vencida'])),
      ];
    }
    if (type.contains('factura')) {
      return [
        ('Pendientes', _metricValue(card, ['pendientes', 'pendiente'])),
        ('Emitidas', _metricValue(card, ['emitidas', 'emitida'])),
        ('Anuladas', _metricValue(card, ['anuladas', 'anulada'])),
      ];
    }
    return [
      ('Con stock', _metricValue(card, ['con_stock', 'con stock'])),
      ('Sin stock', _metricValue(card, ['sin_stock', 'sin stock'])),
      ('Stock bajo', _metricValue(card, ['stock_bajo', 'stock bajo'])),
    ];
  }

  int _metricValue(EstadoDocumentoCard card, List<String> keys) {
    for (final key in keys) {
      final normalizedKey = key.trim().toLowerCase().replaceAll(' ', '_');
      if (card.estados.containsKey(normalizedKey)) {
        return card.estados[normalizedKey] ?? 0;
      }
    }
    return 0;
  }

  Widget _resumenFinanciero(DashboardSummary summary) {
    final desktopEmbedded = !widget.showHeader;
    final compactMode = widget.compact;
    final ventasFacturadas =
        summary.businessDashboard.kpis.ventasFacturas.valor;
    final facturasEmitidas =
        summary.businessDashboard.kpis.facturasEmitidas.valor.round();
    final ventasPorTipo =
        summary.businessDashboard.graficas.ventasPorTipo.items;
    double ventasProductos = 0;
    double ventasServicios = 0;
    for (final item in ventasPorTipo) {
      final label = item.label.trim().toLowerCase();
      if (label == 'producto' || label == 'productos') {
        ventasProductos += item.valor;
      } else if (label == 'servicio' || label == 'servicios') {
        ventasServicios += item.valor;
      }
    }
    final ticketPromedio =
        facturasEmitidas > 0 ? (ventasFacturadas / facturasEmitidas) : 0.0;
    final isMobile = widget.compact || MediaQuery.of(context).size.width < 950;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _box(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Resumen financiero',
            style: TextStyle(
                color: _textMain,
                fontSize: compactMode ? 18 : (desktopEmbedded ? 18 : 28),
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        if (isMobile) ...[
          Column(
            children: [
              _moneyRow('Ventas facturadas',
                  PriceFormatter.formatCopWhole(ventasFacturadas)),
              _moneyRow('Ventas en productos',
                  PriceFormatter.formatCopWhole(ventasProductos)),
              _moneyRow('Ventas en servicios',
                  PriceFormatter.formatCopWhole(ventasServicios)),
              _moneyRow('Facturas emitidas', '$facturasEmitidas'),
              const Divider(height: 24),
              _moneyRow('Ticket promedio',
                  PriceFormatter.formatCopWhole(ticketPromedio),
                  highlight: true),
              const SizedBox(height: 6),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Cálculo basado en ventas facturadas / facturas emitidas',
                  style: TextStyle(
                      color: _textSub,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Center(child: _ticketCircle(ticketPromedio)),
        ] else ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    _moneyRow('Ventas facturadas',
                        PriceFormatter.formatCopWhole(ventasFacturadas)),
                    _moneyRow('Ventas en productos',
                        PriceFormatter.formatCopWhole(ventasProductos)),
                    _moneyRow('Ventas en servicios',
                        PriceFormatter.formatCopWhole(ventasServicios)),
                    _moneyRow('Facturas emitidas', '$facturasEmitidas'),
                    const Divider(height: 24),
                    _moneyRow('Ticket promedio',
                        PriceFormatter.formatCopWhole(ticketPromedio),
                        highlight: true),
                    const SizedBox(height: 6),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Cálculo basado en ventas facturadas / facturas emitidas',
                        style: TextStyle(
                            color: _textSub,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              SizedBox(
                width: 250,
                child: Center(child: _ticketCircle(ticketPromedio)),
              ),
            ],
          ),
        ],
      ]),
    );
  }

  Widget _ticketCircle(double ticketPromedio) {
    return Container(
      width: 208,
      height: 208,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: _teal.withValues(alpha: 0.85),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long_rounded, size: 28, color: _teal),
            const SizedBox(height: 6),
            const Text('Ticket promedio',
                style: TextStyle(
                    color: _textMain,
                    fontWeight: FontWeight.w700,
                    fontSize: 17)),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                PriceFormatter.formatCopWhole(ticketPromedio),
                style: const TextStyle(
                  color: _teal,
                  fontWeight: FontWeight.w800,
                  fontSize: 52,
                  height: 1,
                ),
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _moneyRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: TextStyle(
                    color: highlight ? _teal : _textSub,
                    fontWeight: highlight ? FontWeight.w700 : FontWeight.w600)),
          ),
          Text(value,
              style: TextStyle(
                  color: highlight ? _teal : _textMain,
                  fontWeight: FontWeight.w800,
                  fontSize: 16)),
        ],
      ),
    );
  }

  Widget _lineChart(List<VentaDiaria> data, {double height = 210}) {
    final isCompactMobile = widget.compact;
    final maxValue = data.isEmpty
        ? 0.0
        : data
            .map((e) => e.facturado)
            .reduce((a, b) => a > b ? a : b)
            .toDouble();
    final yMax = _buildLineAxisMax(maxValue);
    const fixedTickDays = <int>{1, 5, 10, 15, 20, 31};
    return SizedBox(
      height: height,
      child: Row(
        children: [
          SizedBox(
            width: 54,
            child: LayoutBuilder(
              builder: (context, axisConstraints) {
                final xLabelsHeight = isCompactMobile ? 22.0 : 32.0;
                final chartAreaHeight =
                    (axisConstraints.maxHeight - xLabelsHeight)
                        .clamp(60.0, double.infinity);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: chartAreaHeight,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_formatCompactMoney(yMax),
                              style: const TextStyle(
                                  color: _textSub, fontSize: 10)),
                          Text(_formatCompactMoney(yMax * 0.75),
                              style: const TextStyle(
                                  color: _textSub, fontSize: 10)),
                          Text(_formatCompactMoney(yMax * 0.50),
                              style: const TextStyle(
                                  color: _textSub, fontSize: 10)),
                          Text(_formatCompactMoney(yMax * 0.25),
                              style: const TextStyle(
                                  color: _textSub, fontSize: 10)),
                          const Text('\$0',
                              style: TextStyle(color: _textSub, fontSize: 10)),
                        ],
                      ),
                    ),
                    SizedBox(height: xLabelsHeight),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final values = data.map((e) => e.facturado).toList();
                      final size =
                          Size(constraints.maxWidth, constraints.maxHeight);

                      void selectAtDx(double dx) {
                        if (data.isEmpty) return;
                        final index = _nearestPointIndex(
                          x: dx.clamp(0.0, size.width),
                          pointCount: data.length,
                          width: size.width,
                        );
                        if (_activeDailyPointIndex != index) {
                          setState(() => _activeDailyPointIndex = index);
                        }
                      }

                      final selectedIndex = _activeDailyPointIndex;
                      final selectedPoint = selectedIndex != null &&
                              selectedIndex >= 0 &&
                              selectedIndex < values.length
                          ? _linePointOffset(
                              index: selectedIndex,
                              values: values,
                              maxY: yMax,
                              size: size,
                            )
                          : null;

                      final chart = Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CustomPaint(
                            painter: _LineChartPainter(
                              values: values,
                              color: _teal,
                              maxY: yMax,
                            ),
                            child: const SizedBox.expand(),
                          ),
                          if (selectedPoint != null)
                            Positioned(
                              left: (selectedPoint.dx - 96).clamp(
                                4.0,
                                math.max(4.0, size.width - 192.0),
                              ),
                              top: math.max(4.0, selectedPoint.dy - 74),
                              child: _buildDailyTooltip(
                                dayLabel: _tooltipDateLabel(
                                  data[selectedIndex!].label,
                                ),
                                valueLabel: PriceFormatter.formatCopWhole(
                                  data[selectedIndex].facturado,
                                ),
                              ),
                            ),
                        ],
                      );

                      if (isCompactMobile) {
                        return chart;
                      }

                      return MouseRegion(
                        onHover: (event) => selectAtDx(event.localPosition.dx),
                        onExit: (_) =>
                            setState(() => _activeDailyPointIndex = null),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTapDown: (details) =>
                              selectAtDx(details.localPosition.dx),
                          onHorizontalDragStart: (details) =>
                              selectAtDx(details.localPosition.dx),
                          onHorizontalDragUpdate: (details) =>
                              selectAtDx(details.localPosition.dx),
                          child: chart,
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: isCompactMobile ? 6 : 10),
                SizedBox(
                  height: isCompactMobile ? 22 : 32,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Builder(
                      builder: (_) {
                        final ticks = (isCompactMobile
                                ? data
                                    .map((e) => _dayNumber(e.label))
                                    .whereType<int>()
                                    .toSet()
                                    .where(fixedTickDays.contains)
                                    .toList()
                                : data
                                    .map((e) => _dayNumber(e.label))
                                    .whereType<int>()
                                    .toList())
                          ..sort();

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: ticks
                              .map(
                                (tick) => Text(
                                  tick.toString().padLeft(2, '0'),
                                  maxLines: 1,
                                  overflow: TextOverflow.clip,
                                  style: const TextStyle(
                                    color: _textSub,
                                    fontSize: 11,
                                  ),
                                ),
                              )
                              .toList(),
                        );
                      },
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

  Widget _barChart(List<PeriodoTotal> data, {double height = 210}) {
    final compactMode = widget.compact;
    final maxValue = data.isEmpty
        ? 0.0
        : data.map((e) => e.total).reduce((a, b) => a > b ? a : b).toDouble();
    final yMax = _buildNiceAxisMax(maxValue);
    return SizedBox(
      height: height,
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: LayoutBuilder(builder: (context, constraints) {
              final monthLabelSpace = compactMode ? 32.0 : 36.0;
              final chartAreaHeight = (constraints.maxHeight - monthLabelSpace)
                  .clamp(60.0, double.infinity);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: chartAreaHeight,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_formatCompactMoney(yMax),
                            style:
                                const TextStyle(color: _textSub, fontSize: 10)),
                        Text(_formatCompactMoney(yMax * 0.75),
                            style:
                                const TextStyle(color: _textSub, fontSize: 10)),
                        Text(_formatCompactMoney(yMax * 0.50),
                            style:
                                const TextStyle(color: _textSub, fontSize: 10)),
                        Text(_formatCompactMoney(yMax * 0.25),
                            style:
                                const TextStyle(color: _textSub, fontSize: 10)),
                        const Text('\$0',
                            style: TextStyle(color: _textSub, fontSize: 10)),
                      ],
                    ),
                  ),
                  SizedBox(height: monthLabelSpace),
                ],
              );
            }),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final monthLabelSpace = compactMode ? 32.0 : 36.0;
                final barWidthFactor = compactMode ? 0.46 : 0.58;
                final slotWidth =
                    constraints.maxWidth / (data.isEmpty ? 12 : data.length);
                final chartAreaHeight =
                    (constraints.maxHeight - monthLabelSpace)
                        .clamp(60.0, double.infinity);
                final valueLabelHeight = compactMode ? 15.0 : 16.0;
                final valueLabelGap = compactMode ? 3.0 : 4.0;
                final drawableBarHeight = chartAreaHeight;

                return Stack(
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      bottom: monthLabelSpace,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(
                          5,
                          (_) => Container(
                            height: 1,
                            color: const Color(0xFFE3EAF4),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: data
                          .map((e) => Expanded(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 3),
                                  child: Column(
                                    children: [
                                      SizedBox(
                                        height: chartAreaHeight,
                                        child: Stack(
                                          clipBehavior: Clip.none,
                                          alignment: Alignment.bottomCenter,
                                          children: [
                                            if (e.total > 0) ...[
                                              Positioned(
                                                bottom: math.min(
                                                  chartAreaHeight -
                                                      valueLabelHeight,
                                                  (yMax <= 0
                                                          ? 0.0
                                                          : (e.total / yMax) *
                                                              drawableBarHeight) +
                                                      valueLabelGap,
                                                ),
                                                child: Container(
                                                  constraints: BoxConstraints(
                                                    minWidth:
                                                        compactMode ? 34 : 44,
                                                    maxWidth: slotWidth *
                                                        (compactMode
                                                            ? 2.0
                                                            : 2.4),
                                                  ),
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 2,
                                                      vertical: 1),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                  ),
                                                  child: Text(
                                                    _formatCompactMoney(
                                                        e.total),
                                                    textAlign: TextAlign.center,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.visible,
                                                    softWrap: false,
                                                    style: const TextStyle(
                                                      color: _textSub,
                                                      fontSize: 10.5,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                            if (e.total <= 0)
                                              const Positioned(
                                                bottom: 6,
                                                child: DecoratedBox(
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.all(
                                                            Radius.circular(4)),
                                                  ),
                                                  child: Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            horizontal: 4,
                                                            vertical: 1),
                                                    child: Text(
                                                      '\$0',
                                                      style: TextStyle(
                                                        color: _textSub,
                                                        fontSize: 10.5,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            Container(
                                              width: constraints.maxWidth /
                                                  (data.isEmpty
                                                      ? 12
                                                      : data.length) *
                                                  barWidthFactor,
                                              height: yMax <= 0
                                                  ? 0
                                                  : (e.total / yMax) *
                                                      drawableBarHeight,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF11A36D),
                                                borderRadius:
                                                    BorderRadius.circular(9),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(
                                        height: monthLabelSpace,
                                        child: Padding(
                                          padding: const EdgeInsets.only(top: 6),
                                          child: Align(
                                            alignment: Alignment.topCenter,
                                            child: Text(
                                              _shortMonth(e.label),
                                              maxLines: 1,
                                              softWrap: false,
                                              overflow: TextOverflow.clip,
                                              style: const TextStyle(
                                                  color: _textSub,
                                                  fontSize: 11),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _donut(VentasDistribucion data) {
    final values = data.items.map((e) => e.valor).toList();
    return CustomPaint(
      painter: _DonutPainter(values: values, colors: _segmentColors),
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(PriceFormatter.formatCopWhole(data.total),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: _textMain, fontWeight: FontWeight.w800, fontSize: 14)),
          const Text('Total', style: TextStyle(color: _textSub)),
        ]),
      ),
    );
  }

  Widget _chartHeader(String title, String subtitle,
      {String rightLabel = 'Lineal', VoidCallback? onExpand}) {
    final desktopEmbedded = !widget.showHeader;
    final isMobile = widget.compact || MediaQuery.of(context).size.width < 950;
    final compactMode = widget.compact;
    return Row(children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              maxLines: compactMode ? 2 : 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: _textMain,
                  fontSize: compactMode
                      ? 14
                      : (isMobile ? 20 : (desktopEmbedded ? 22 : 29)),
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: _textSub,
                  fontSize: compactMode
                      ? 11
                      : (isMobile ? 13 : (desktopEmbedded ? 14 : 17)))),
        ]),
      ),
      Container(
        padding: EdgeInsets.symmetric(
            horizontal: compactMode ? 8 : 10, vertical: compactMode ? 6 : 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFDCE3EF)),
        ),
        child: Text(rightLabel,
            style: TextStyle(
                color: _textMain,
                fontWeight: FontWeight.w700,
                fontSize: compactMode ? 12 : 16)),
      ),
      const SizedBox(width: 8),
      IconButton(
        onPressed: onExpand,
        icon: const Icon(Icons.open_in_full_rounded, size: 19),
        style: IconButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFFDCE3EF)),
        ),
      ),
    ]);
  }

  void _openExpandedChart({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(18),
        child: Container(
          padding: const EdgeInsets.all(18),
          constraints: const BoxConstraints(maxWidth: 1000, maxHeight: 680),
          child: Column(
            children: [
              Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              color: _textMain,
                              fontWeight: FontWeight.w800,
                              fontSize: 24)),
                      Text(subtitle, style: const TextStyle(color: _textSub)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                )
              ]),
              const SizedBox(height: 14),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }

  Widget _empty(String message) {
    return Container(
      height: 170,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE1E8F3)),
      ),
      child: Text(message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: _textSub, fontWeight: FontWeight.w600)),
    );
  }

  Widget _chipButton({
    required IconData icon,
    required String text,
    double minWidth = 150,
    bool multiline = false,
  }) {
    final desktopEmbedded = !widget.showHeader;
    return Container(
      constraints: BoxConstraints(minWidth: minWidth),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: _box(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _textSub, size: 18),
          const SizedBox(width: 8),
          SizedBox(
            width: desktopEmbedded ? 230 : null,
            child: Text(text,
                style: const TextStyle(
                    color: _textMain, fontWeight: FontWeight.w600),
                maxLines: multiline ? 2 : 1,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  BoxDecoration _box() => BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE4F0)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x110F1D3A), blurRadius: 16, offset: Offset(0, 5)),
        ],
      );

  InputDecoration _inputDecoration() {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFDCE3EF)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFDCE3EF)),
      ),
    );
  }

  Widget _errorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, color: Color(0xFFB42318), size: 40),
          const SizedBox(height: 10),
          const Text('No fue posible cargar el dashboard',
              style: TextStyle(
                  color: Color(0xFF7A271A),
                  fontWeight: FontWeight.w800,
                  fontSize: 18)),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reintentar'),
          )
        ]),
      ),
    );
  }

  String _formatQty(double value) {
    final rounded = value.roundToDouble();
    return (value - rounded).abs() < 0.001
        ? rounded.toInt().toString()
        : value.toStringAsFixed(1);
  }

  String _formatCompactMoney(double value) {
    if (value >= 1000000) {
      return '\$${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '\$${(value / 1000).toStringAsFixed(0)}k';
    }
    return '\$${value.round()}';
  }

  double _buildNiceAxisMax(double maxValue) {
    if (maxValue <= 0) return 1;
    if (maxValue <= 10000000) return 10000000;

    const step = 10000000.0;
    final withHeadroom = maxValue * 1.1;
    return (withHeadroom / step).ceil() * step;
  }

  String _monthName(int month) {
    const m = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic'
    ];
    return m[(month - 1).clamp(0, 11)];
  }

  String _shortMonth(String raw) {
    final token = raw.split(' ').first.trim();
    if (token.isEmpty) return raw;
    if (token.length <= 3) return token;
    return token.substring(0, 3);
  }

  String _dayLabel(String raw) {
    final parts = raw.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return raw;
    final day = int.tryParse(parts.first);
    if (day == null) return parts.first;
    return day.toString().padLeft(2, '0');
  }

  int? _dayNumber(String raw) {
    final parts = raw.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return null;
    return int.tryParse(parts.first);
  }

  String _tooltipDateLabel(String raw) {
    final parts = raw.trim().split(RegExp(r'\s+'));
    final dayText = _dayLabel(raw);
    if (parts.length < 2) return '$dayText de mes';
    final month = parts[1].toLowerCase();
    const map = {
      'jan': 'enero',
      'ene': 'enero',
      'feb': 'febrero',
      'mar': 'marzo',
      'apr': 'abril',
      'abr': 'abril',
      'may': 'mayo',
      'jun': 'junio',
      'jul': 'julio',
      'aug': 'agosto',
      'ago': 'agosto',
      'sep': 'septiembre',
      'oct': 'octubre',
      'nov': 'noviembre',
      'dec': 'diciembre',
      'dic': 'diciembre',
    };
    final normalized = month.length >= 3 ? month.substring(0, 3) : month;
    final monthEs = map[normalized] ?? month;
    return '$dayText de $monthEs';
  }

  int _nearestPointIndex({
    required double x,
    required int pointCount,
    required double width,
  }) {
    if (pointCount <= 1 || width <= 0) return 0;
    final ratio = (x / width).clamp(0.0, 1.0);
    return (ratio * (pointCount - 1)).round().clamp(0, pointCount - 1);
  }

  Offset _linePointOffset({
    required int index,
    required List<double> values,
    required double maxY,
    required Size size,
  }) {
    const topPadding = 6.0;
    const bottomPadding = 8.0;
    final chartHeight =
        (size.height - topPadding - bottomPadding).clamp(60.0, double.infinity);
    final chartBottom = topPadding + chartHeight;
    final safeMax = maxY <= 0 ? 1.0 : maxY;
    final pointCount = values.length;
    final x = pointCount <= 1
        ? size.width / 2
        : index * (size.width / (pointCount - 1));
    final normalized = (values[index] / safeMax).clamp(0.0, 1.0);
    final y = chartBottom - normalized * chartHeight;
    return Offset(x, y);
  }

  Widget _buildDailyTooltip({
    required String dayLabel,
    required String valueLabel,
  }) {
    return Container(
      width: 192,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDCE4F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F1D3A),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dayLabel,
            style: const TextStyle(
              color: _textSub,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            valueLabel,
            style: const TextStyle(
              color: _textMain,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  double _buildLineAxisMax(double maxValue) {
    if (maxValue <= 0) return 1000000;
    final withHeadroom = maxValue * 1.15;
    const step = 500000.0;
    return (withHeadroom / step).ceil() * step;
  }

  String _formatRange(String start, String end) {
    DateTime? startDate;
    DateTime? endDate;
    try {
      startDate = DateTime.parse(start);
      endDate = DateTime.parse(end);
    } catch (_) {
      return '$start - $end';
    }
    return '${startDate.day.toString().padLeft(2, '0')} ${_monthName(startDate.month)} ${startDate.year} - ${endDate.day.toString().padLeft(2, '0')} ${_monthName(endDate.month)} ${endDate.year}';
  }

  static const _segmentColors = [
    Color(0xFF10A46F),
    Color(0xFF2C90F2),
    Color(0xFF8A4BF0),
    Color(0xFFF59E0B),
    Color(0xFF14B8A6),
  ];
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({
    required this.values,
    required this.color,
    required this.maxY,
  });

  final List<double> values;
  final Color color;
  final double maxY;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final safeMax = maxY <= 0 ? 1.0 : maxY;
    const topPadding = 6.0;
    const bottomPadding = 8.0;
    final chartHeight =
        (size.height - topPadding - bottomPadding).clamp(60.0, double.infinity);
    final chartBottom = topPadding + chartHeight;

    final grid = Paint()
      ..color = const Color(0xFFE3EAF4)
      ..strokeWidth = 1;

    for (var i = 0; i <= 4; i++) {
      final y = topPadding + (chartHeight * i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x = values.length == 1
          ? size.width / 2
          : i * (size.width / (values.length - 1));
      final normalized = (values[i] / safeMax).clamp(0.0, 1.0);
      final y = chartBottom - normalized * chartHeight;
      points.add(Offset(x, y));
    }

    final line = Path();
    line.moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final cpX = (prev.dx + curr.dx) / 2;
      line.cubicTo(cpX, prev.dy, cpX, curr.dy, curr.dx, curr.dy);
    }

    final area = Path.from(line)
      ..lineTo(points.last.dx, chartBottom)
      ..lineTo(points.first.dx, chartBottom)
      ..close();

    final fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.26), color.withValues(alpha: 0.02)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(area, fill);

    final stroke = Paint()
      ..color = color
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;

    canvas.drawPath(line, stroke);

    final dot = Paint()..color = color;
    final dotBorder = Paint()..color = Colors.white;
    for (final p in points) {
      canvas.drawCircle(p, 4.4, dotBorder);
      canvas.drawCircle(p, 3.1, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.color != color ||
        oldDelegate.maxY != maxY;
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.values, required this.colors});

  final List<double> values;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(0, (a, b) => a + b);
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24
      ..color = const Color(0xFFE7ECF4);
    canvas.drawCircle(center, radius - 12, base);

    if (total <= 0) {
      return;
    }

    var start = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      final sweep = (values[i] / total) * (2 * math.pi);
      if (sweep <= 0) continue;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt
        ..strokeWidth = 24
        ..color = colors[i % colors.length];
      canvas.drawArc(rect.deflate(12), start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.values != values;
  }
}
