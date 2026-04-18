import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/layout/adaptive_layout.dart';
import '../../../shared/utils/price_formatter.dart';
import '../domain/factura.dart';
import '../domain/factura_item.dart';
import '../facturas_controller.dart';

const _logoTeslaAsset = 'assets/images/logo_tesla.png';
const _marcaAguaTeslaAsset = 'assets/images/marca_agua_tesla.png';

class FacturaDetailScreen extends StatefulWidget {
  const FacturaDetailScreen({
    super.key,
    required this.controller,
    required this.factura,
  });

  final FacturasController controller;
  final Factura factura;

  @override
  State<FacturaDetailScreen> createState() => _FacturaDetailScreenState();
}

class _FacturaDetailScreenState extends State<FacturaDetailScreen> {
  static const _ink900 = Color(0xFF111827);
  static const _ink700 = Color(0xFF374151);
  static const _ink500 = Color(0xFF6B7280);
  static const _ink200 = Color(0xFFE5E7EB);
  static const _background = Color(0xFFF3F4F6);
  static const _draftBadgeBg = Color(0xFFFDECC8);
  static const _draftBadgeFg = Color(0xFF8A5A08);
  static const _issuedBadgeBg = Color(0xFFD1FAE5);
  static const _issuedBadgeFg = Color(0xFF065F46);

  late Factura _factura;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _factura = widget.factura;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_loadDetail());
    });
  }

  Future<void> _loadDetail() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final detail = await widget.controller.fetchFactura(widget.factura.id);
      if (!mounted) {
        return;
      }

      setState(() {
        _factura = detail;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = '$error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = AdaptiveLayout.isDesktopWidth(constraints.maxWidth);

        return Scaffold(
          backgroundColor: _background,
          appBar: AppBar(
            backgroundColor: _background,
            foregroundColor: _ink900,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            title: const Text(
              'Detalle de factura',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          body: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                isDesktop ? 32 : 14,
                10,
                isDesktop ? 32 : 14,
                24,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: _buildDocumentCard(isDesktop),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDocumentCard(bool isDesktop) {
    final estado = _factura.estado.trim().toLowerCase();
    final statusText = estado == 'emitida' ? 'Emitida' : 'Borrador';
    final statusBg = estado == 'emitida' ? _issuedBadgeBg : _draftBadgeBg;
    final statusFg = estado == 'emitida' ? _issuedBadgeFg : _draftBadgeFg;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _ink200),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: EdgeInsets.all(isDesktop ? 26 : 16),
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: Opacity(
                  opacity: 0.075,
                  child: FractionallySizedBox(
                    widthFactor: isDesktop ? 0.44 : 0.72,
                    child:
                        Image.asset(_marcaAguaTeslaAsset, fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF7CBF29),
                      Color(0xFFCC3E14),
                      Color(0xFF8B8B8B)
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _buildHeader(
                  statusText: statusText,
                  statusBg: statusBg,
                  statusFg: statusFg),
              const SizedBox(height: 16),
              const Divider(height: 1, color: _ink200),
              const SizedBox(height: 16),
              _buildInfoSection(isDesktop),
              const SizedBox(height: 18),
              _buildItemsSection(isDesktop),
              const SizedBox(height: 18),
              _buildTotalsSection(),
              const SizedBox(height: 16),
              const Divider(height: 1, color: _ink200),
              const SizedBox(height: 12),
              _buildFooterSection(),
              if (_isLoading) ...[
                const SizedBox(height: 16),
                const LinearProgressIndicator(minHeight: 3),
              ],
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  'No se pudo actualizar el detalle: $_error',
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader({
    required String statusText,
    required Color statusBg,
    required Color statusFg,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Row(
            children: [
              Image.asset(_logoTeslaAsset, height: 46, fit: BoxFit.contain),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Proyecciones Eléctricas Tesla',
                      style: TextStyle(
                        color: _ink900,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Documento comercial interno',
                      style: TextStyle(color: _ink500, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              'Factura',
              style: TextStyle(
                  color: _ink900, fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              _factura.codigo,
              style: const TextStyle(
                  color: _ink500, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                    color: statusFg, fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoSection(bool isDesktop) {
    final clienteNit = (_factura.clienteNit ?? '').trim();
    final clienteContacto = (_factura.clienteContacto ?? '').trim();
    final clienteDireccion = (_factura.clienteDireccion ?? '').trim();
    final fecha = _formatFechaLarga(_factura.fecha);

    final left = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CLIENTE',
          style: TextStyle(
              color: _ink500, fontSize: 11, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          _factura.clienteNombre,
          style: const TextStyle(
              color: _ink900, fontSize: 14, fontWeight: FontWeight.w700),
        ),
        if (clienteNit.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text('NIT/CC: $clienteNit',
              style: const TextStyle(color: _ink700, fontSize: 12)),
        ],
        if (clienteContacto.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(clienteContacto,
              style: const TextStyle(color: _ink700, fontSize: 12)),
        ],
        if (clienteDireccion.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(clienteDireccion,
              style: const TextStyle(color: _ink700, fontSize: 12)),
        ],
      ],
    );

    final right = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text(
          'DETALLES',
          style: TextStyle(
              color: _ink500, fontSize: 11, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        const Text('Fecha de emisión',
            style: TextStyle(
                color: _ink900, fontSize: 13, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(fecha, style: const TextStyle(color: _ink700, fontSize: 12)),
      ],
    );

    if (!isDesktop) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          left,
          const SizedBox(height: 14),
          Align(alignment: Alignment.centerRight, child: right),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 12),
        Expanded(child: right),
      ],
    );
  }

  Widget _buildItemsSection(bool isDesktop) {
    final items = _factura.items;
    if (items.isEmpty) {
      return const Text(
        'Esta factura no tiene ítems.',
        style: TextStyle(color: _ink500, fontSize: 12),
      );
    }

    if (!isDesktop) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PRODUCTOS Y SERVICIOS',
            style: TextStyle(
                color: _ink500, fontSize: 11, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          for (final item in items) ...[
            _buildItemMobileCard(item),
            const SizedBox(height: 8),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PRODUCTOS Y SERVICIOS',
          style: TextStyle(
              color: _ink500, fontSize: 11, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowHeight: 38,
            dataRowMinHeight: 50,
            dataRowMaxHeight: 72,
            horizontalMargin: 10,
            columnSpacing: 16,
            dividerThickness: 0.5,
            headingTextStyle: const TextStyle(
              color: _ink500,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
            dataTextStyle: const TextStyle(color: _ink900, fontSize: 12),
            columns: const [
              DataColumn(label: Text('Descripción')),
              DataColumn(label: Text('Cant.')),
              DataColumn(label: Text('Precio unit.')),
              DataColumn(label: Text('IVA %')),
              DataColumn(label: Text('IVA valor')),
              DataColumn(label: Text('Subtotal')),
              DataColumn(label: Text('Total')),
            ],
            rows: items.map((item) => _buildRow(item)).toList(growable: false),
          ),
        ),
      ],
    );
  }

  DataRow _buildRow(FacturaItem item) {
    return DataRow(
      cells: [
        DataCell(
          SizedBox(
            width: 220,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.descripcion,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (item.unidad.trim().isNotEmpty)
                  Text(
                    item.unidad,
                    style: const TextStyle(color: _ink500, fontSize: 11),
                  ),
              ],
            ),
          ),
        ),
        DataCell(Text(item.cantidad)),
        DataCell(Text(PriceFormatter.formatCopLatino(item.precioUnitario))),
        DataCell(Text(
            '${PriceFormatter.parse(item.ivaPorcentaje).toStringAsFixed(2)}%')),
        DataCell(Text(PriceFormatter.formatCopLatino(item.ivaValor))),
        DataCell(Text(PriceFormatter.formatCopLatino(item.subtotalLinea))),
        DataCell(
          Text(
            PriceFormatter.formatCopLatino(item.totalLinea),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _buildItemMobileCard(FacturaItem item) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _ink200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.descripcion,
            style: const TextStyle(
                color: _ink900, fontSize: 13, fontWeight: FontWeight.w700),
          ),
          if (item.unidad.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(item.unidad,
                  style: const TextStyle(color: _ink500, fontSize: 11)),
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 6,
            children: [
              _kv('Cant.', item.cantidad),
              _kv('Precio',
                  PriceFormatter.formatCopLatino(item.precioUnitario)),
              _kv('IVA %',
                  '${PriceFormatter.parse(item.ivaPorcentaje).toStringAsFixed(2)}%'),
              _kv('IVA', PriceFormatter.formatCopLatino(item.ivaValor)),
              _kv('Subtotal',
                  PriceFormatter.formatCopLatino(item.subtotalLinea)),
              _kv('Total', PriceFormatter.formatCopLatino(item.totalLinea),
                  bold: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kv(String label, String value, {bool bold = false}) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$label ',
            style: const TextStyle(color: _ink500, fontSize: 11),
          ),
          TextSpan(
            text: value,
            style: TextStyle(
              color: _ink900,
              fontSize: 11,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalsSection() {
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: Column(
          children: [
            _totalRow(
                'Subtotal', PriceFormatter.formatCopLatino(_factura.subtotal)),
            _totalRow(
                'IVA total', PriceFormatter.formatCopLatino(_factura.ivaTotal)),
            const SizedBox(height: 6),
            const Divider(height: 1, color: _ink200),
            const SizedBox(height: 6),
            _totalRow('Total', PriceFormatter.formatCopLatino(_factura.total),
                isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _totalRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isTotal ? _ink900 : _ink500,
                fontSize: isTotal ? 15 : 13,
                fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: _ink900,
              fontSize: isTotal ? 15 : 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterSection() {
    final notes = (_factura.observaciones ?? '').trim().isEmpty
        ? 'Sin observaciones adicionales.'
        : _factura.observaciones!.trim();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'NOTAS',
                style: TextStyle(
                    color: _ink500, fontSize: 11, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                notes,
                style:
                    const TextStyle(color: _ink700, fontSize: 12, height: 1.45),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        const SizedBox(
          width: 170,
          child: Column(
            children: [
              SizedBox(height: 30),
              Divider(height: 1, color: _ink200),
              SizedBox(height: 6),
              Text(
                'Firma autorizada',
                style: TextStyle(color: _ink500, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatFechaLarga(String raw) {
    final date = DateTime.tryParse(raw);
    if (date == null) {
      return raw;
    }

    const months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];

    final month = months[date.month - 1];
    return '${date.day} de $month de ${date.year}';
  }
}
