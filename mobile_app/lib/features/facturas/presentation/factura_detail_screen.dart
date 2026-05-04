import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../../core/config/app_config.dart';
import '../../../core/layout/adaptive_layout.dart';
import '../../../shared/utils/price_formatter.dart';
import '../domain/factura.dart';
import '../domain/factura_item.dart';
import '../facturas_controller.dart';
import 'factura_pdf_service.dart';

const _logoTeslaAsset = 'assets/images/logo_tesla.png';
const _institutionalText =
    'DISEÑO Y EJECUCIÓN DE PROYECTOS ELÉCTRICOS, EN NIVELES DE MEDIA Y BAJA TENSIÓN, MANTENIMIENTO Y CONSTRUCCION DE SUBESTACIONES ELECTRICAS DE DISTRIBUCION, MANTENIMIENTO E INSTALACION DE SISTEMAS Y EQUIPOS ELECTRICOS, EN AMBIENTES INDUSTRIALES, DOMICILIARIO Y OFICINA, DISENO E IMPLEMENTACIÓN DE PLANES DE MITIGACIÓN EN RIESGO ELÉCTRICO, MANTENIMIENTO EN PODA DE VEGETACIÓN CON CONTACTO DIRECTO EN REDES ELÉCTRICAS PRIMARIAS Y SECUNDARIAS.';
const _footerLineOne = 'Calle 13 Sur N° 15 76 - Cel 3004332599';
const _footerLineTwo = 'E-mail proyeccioneselectricastesla@gmail.com';
const _footerLineThree = 'Villavicencio Meta.';

class FacturaDetailScreen extends StatefulWidget {
  const FacturaDetailScreen({
    super.key,
    required this.controller,
    required this.factura,
    this.defaultFirmaPath,
    this.defaultFirmaNombre,
    this.defaultFirmaCargo,
    this.defaultFirmaEmpresa,
  });

  final FacturasController controller;
  final Factura factura;
  final String? defaultFirmaPath;
  final String? defaultFirmaNombre;
  final String? defaultFirmaCargo;
  final String? defaultFirmaEmpresa;

  @override
  State<FacturaDetailScreen> createState() => _FacturaDetailScreenState();
}

class _FacturaDetailScreenState extends State<FacturaDetailScreen> {
  static const _ink900 = Color(0xFF111827);
  static const _ink700 = Color(0xFF374151);
  static const _ink500 = Color(0xFF6B7280);
  static const _ink300 = Color(0xFFD1D5DB);
  static const _ink200 = Color(0xFFE5E7EB);
  static const _background = Color(0xFFF3F4F6);
  static const _emerald600 = Color(0xFF059669);
  static const _amber700 = Color(0xFFB45309);
  static const _rose600 = Color(0xFFE11D48);

  late Factura _factura;
  bool _isLoading = false;
  bool _isExportingPdf = false;
  String? _error;
  late Future<List<Uint8List>> _mobilePreviewImagesFuture;

  @override
  void initState() {
    super.initState();
    _factura = widget.factura;
    _mobilePreviewImagesFuture = _buildMobilePreviewImages();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_loadDetail());
    });
  }

  Future<void> _loadDetail() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final detail = await widget.controller.fetchFactura(widget.factura.id);
      if (!mounted) return;
      setState(() {
        _factura = detail;
        _mobilePreviewImagesFuture = _buildMobilePreviewImages();
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<Uint8List> _buildFacturaPdfBytes() {
    return FacturaPdfService.buildPdf(_factura);
  }

  Future<List<Uint8List>> _buildMobilePreviewImages() async {
    final pdfBytes = await _buildFacturaPdfBytes();
    final pages = <Uint8List>[];
    await for (final page in Printing.raster(pdfBytes, dpi: 260)) {
      pages.add(await page.toPng());
    }
    if (pages.isEmpty) {
      throw StateError('No fue posible renderizar la vista de factura.');
    }
    return pages;
  }

  Future<void> _sharePdf() async {
    if (_isExportingPdf) {
      return;
    }

    setState(() => _isExportingPdf = true);
    try {
      final bytes = await _buildFacturaPdfBytes();
      final fileName = FacturaPdfService.buildFileName(_factura);
      await Printing.sharePdf(bytes: bytes, filename: fileName);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No fue posible compartir la factura: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isExportingPdf = false);
      }
    }
  }

  Future<void> _printPdf() async {
    if (_isExportingPdf) {
      return;
    }

    setState(() => _isExportingPdf = true);
    try {
      final bytes = await _buildFacturaPdfBytes();
      final fileName = FacturaPdfService.buildFileName(_factura);
      await Printing.layoutPdf(
        name: fileName,
        onLayout: (_) async => bytes,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No fue posible imprimir la factura: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isExportingPdf = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = AdaptiveLayout.isDesktopWidth(constraints.maxWidth);

        return Scaffold(
          backgroundColor: isDesktop ? _background : const Color(0xFF0B1116),
          appBar: AppBar(
            backgroundColor: isDesktop ? _background : const Color(0xFF0B1116),
            foregroundColor: isDesktop ? _ink900 : Colors.white,
            elevation: 0,
            title: const Text('Detalle de factura',
                style: TextStyle(fontWeight: FontWeight.w700)),
            actions: [
              IconButton(
                onPressed: _isExportingPdf ? null : _sharePdf,
                tooltip: 'Compartir PDF',
                icon: _isExportingPdf
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.share_rounded),
              ),
              IconButton(
                onPressed: _isExportingPdf ? null : _printPdf,
                tooltip: 'Imprimir',
                icon: const Icon(Icons.print_rounded),
              ),
            ],
          ),
          body: SafeArea(
            top: false,
            child: isDesktop
                ? SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 12, 28, 22),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 980),
                        child: _buildCuentaCobroCard(true),
                      ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.fromLTRB(6, 8, 6, 10),
                    child: FutureBuilder<List<Uint8List>>(
                      future: _mobilePreviewImagesFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError || !snapshot.hasData) {
                          return const Center(
                            child: Text(
                              'No fue posible cargar la vista de factura.',
                              style: TextStyle(color: Colors.white),
                            ),
                          );
                        }

                        final pages = snapshot.data!;
                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final pageWidth = constraints.maxWidth - 8;
                            return InteractiveViewer(
                              minScale: 1,
                              maxScale: 5.5,
                              panEnabled: true,
                              scaleEnabled: true,
                              constrained: false,
                              boundaryMargin: const EdgeInsets.all(220),
                              child: SizedBox(
                                width: pageWidth,
                                child: Column(
                                  children: [
                                    for (var i = 0; i < pages.length; i++) ...[
                                      Container(
                                        width: pageWidth,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Color(0x22000000),
                                              blurRadius: 10,
                                              offset: Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: Image.memory(
                                            pages[i],
                                            width: pageWidth,
                                            fit: BoxFit.fitWidth,
                                            filterQuality: FilterQuality.high,
                                          ),
                                        ),
                                      ),
                                      if (i < pages.length - 1)
                                        const SizedBox(height: 14),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildCuentaCobroCard(bool isDesktop) {
    final ciudadExpedicion = (_factura.ciudadExpedicion ?? '').trim().isEmpty
        ? 'Villavicencio, Meta'
        : _factura.ciudadExpedicion!.trim();
    final clienteNombre = _factura.clienteNombre.trim().isEmpty
        ? 'CLIENTE PENDIENTE'
        : _factura.clienteNombre.trim().toUpperCase();
    final clienteNit = (_factura.clienteNit ?? '').trim();
    final clienteCiudad = (_factura.clienteCiudad ?? '').trim().isEmpty
        ? 'Villavicencio.'
        : _factura.clienteCiudad!.trim();
    final cuentaCobroNumero = _extractCuentaCobroNumero(_factura);
    final totalNumber = PriceFormatter.parse(_factura.total).round();
    final totalWords = '${_numberToSpanishWords(totalNumber)} pesos mcte';
    final totalText = PriceFormatter.formatCopWhole(_factura.total);

    final firmaPath =
        (_factura.firmaPath ?? widget.defaultFirmaPath ?? '').trim();
    final firmaNombre = (_factura.firmaNombre ??
            widget.defaultFirmaNombre ??
            'María Alejandra Flórez Ocampo.')
        .trim();
    final firmaCargo = (_factura.firmaCargo ??
            widget.defaultFirmaCargo ??
            'Representante Legal')
        .trim();
    final firmaEmpresa = (_factura.firmaEmpresa ??
            widget.defaultFirmaEmpresa ??
            'Proyecciones eléctricas Tesla.')
        .trim();

    return Container(
      padding:
          EdgeInsets.fromLTRB(isDesktop ? 26 : 14, 16, isDesktop ? 26 : 14, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _ink200),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: Opacity(
                  opacity: 0.28,
                  child: FractionallySizedBox(
                    widthFactor: isDesktop ? 0.86 : 1.08,
                    child: Image.asset(_logoTeslaAsset, fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: _buildEstadoChip(_factura.estado),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Image.asset(_logoTeslaAsset,
                      height: isDesktop ? 62 : 44, fit: BoxFit.contain),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                _institutionalText,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: _ink700,
                    fontSize: isDesktop ? 11.3 : 10.1,
                    height: 1.2),
              ),
              const SizedBox(height: 10),
              Text(
                '$ciudadExpedicion ${_formatFechaLarga(_factura.fecha)}',
                style: TextStyle(
                    color: _ink900,
                    fontSize: isDesktop ? 18 : 15.5,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                'Cuenta de cobro N° $cuentaCobroNumero.',
                style: TextStyle(
                    color: _ink900,
                    fontSize: isDesktop ? 18 : 16,
                    fontWeight: FontWeight.w800),
              ),
              SizedBox(height: isDesktop ? 24 : 18),
              Text(clienteNombre,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: _ink900,
                      fontWeight: FontWeight.w800,
                      fontSize: isDesktop ? 19 : 16)),
              if (clienteNit.isNotEmpty)
                Text(
                  'NIT. $clienteNit',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: _ink900,
                      fontWeight: FontWeight.w700,
                      fontSize: isDesktop ? 17 : 14.5),
                ),
              Text(
                clienteCiudad,
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: _ink900, fontSize: isDesktop ? 17 : 14.2),
              ),
              const SizedBox(height: 10),
              Text('Debe a:',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: _ink900, fontSize: isDesktop ? 18 : 15.5)),
              const Text(
                'PROYECCIONES ELÉCTRICAS TESLA',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: _ink900, fontWeight: FontWeight.w800, fontSize: 17),
              ),
              const Text(
                'CC. 1.096.224.844-1.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _ink900, fontSize: 17),
              ),
              const SizedBox(height: 10),
              Text('La suma de:',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: _ink900, fontSize: isDesktop ? 18 : 15.5)),
              Text(
                '$totalWords ($totalText)',
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: _ink900, fontSize: isDesktop ? 18 : 15.3),
              ),
              const SizedBox(height: 10),
              const Text(
                'Ref. Cuenta de cobro.',
                style: TextStyle(
                    color: _ink900, fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              _buildTable(isDesktop),
              const SizedBox(height: 20),
              const Text('Cordialmente,',
                  style: TextStyle(color: _ink900, fontSize: 17)),
              const SizedBox(height: 10),
              _buildSignature(firmaPath: firmaPath, fallbackName: firmaNombre),
              const SizedBox(height: 8),
              Text(
                firmaNombre,
                style: const TextStyle(
                    color: _ink900, fontSize: 15, fontWeight: FontWeight.w800),
              ),
              Text(
                firmaCargo,
                style: const TextStyle(
                    color: _ink900, fontSize: 15, fontWeight: FontWeight.w800),
              ),
              Text(
                firmaEmpresa,
                style: const TextStyle(
                    color: _ink900, fontSize: 15, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              const Text(
                'Favor consignar a la cuenta de ahorros N° 05763353119, Bancolombia',
                style: TextStyle(
                    color: _ink900, fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              Container(height: 5, color: Colors.black),
              const SizedBox(height: 10),
              Text(_footerLineOne,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: _ink300,
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
              Text(_footerLineTwo,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: _ink300,
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
              Text(_footerLineThree,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: _ink300,
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
              if (_isLoading) ...[
                const SizedBox(height: 12),
                const LinearProgressIndicator(minHeight: 3),
              ],
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text('No se pudo refrescar: $_error',
                    style: const TextStyle(color: Colors.red, fontSize: 12)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTable(bool isDesktop) {
    final rows = <FacturaItem>[..._factura.items];
    while (rows.length < 5) {
      rows.add(
        FacturaItem(
          id: -rows.length,
          facturaId: _factura.id,
          tipoItem: 'servicio',
          productoId: null,
          servicioId: null,
          codigo: '',
          orden: rows.length + 1,
          descripcion: '',
          unidad: '',
          cantidad: '',
          precioUnitario: '',
          ivaPorcentaje: '0',
          ivaValor: '0',
          subtotalLinea: '0',
          totalLinea: '0',
        ),
      );
    }

    final headingStyle = TextStyle(
        color: _ink900,
        fontSize: isDesktop ? 15.5 : 13,
        fontWeight: FontWeight.w800);
    final cellStyle =
        TextStyle(color: _ink900, fontSize: isDesktop ? 14.5 : 12.2);

    return Column(
      children: [
        Table(
          border:
              TableBorder.all(color: _ink500.withValues(alpha: 0.5), width: 1),
          columnWidths: const {
            0: FixedColumnWidth(56),
            1: FixedColumnWidth(84),
            2: FlexColumnWidth(3.7),
            3: FixedColumnWidth(68),
            4: FixedColumnWidth(68),
            5: FixedColumnWidth(102),
            6: FixedColumnWidth(118),
          },
          children: [
            TableRow(
              decoration: const BoxDecoration(color: Color(0xFFD6D8DC)),
              children: [
                _th('Ítem', headingStyle),
                _th('Código', headingStyle),
                _th('Descripción', headingStyle),
                _th('Unid.', headingStyle),
                _th('Cant.', headingStyle),
                _th('V. Unit', headingStyle),
                _th('Total', headingStyle),
              ],
            ),
            for (var i = 0; i < rows.length; i++)
              _tableRow(i + 1, rows[i], cellStyle),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Color(0xFFD6D8DC),
                  border: Border(
                    left: BorderSide(
                        color: _ink500.withValues(alpha: 0.5), width: 1),
                    right: BorderSide(
                        color: _ink500.withValues(alpha: 0.5), width: 1),
                    bottom: BorderSide(
                        color: _ink500.withValues(alpha: 0.5), width: 1),
                  ),
                ),
                alignment: Alignment.center,
                child: Text('TOTAL', style: headingStyle),
              ),
            ),
            Container(
              width: 118,
              height: 40,
              decoration: BoxDecoration(
                color: Color(0xFFD6D8DC),
                border: Border(
                  right: BorderSide(
                      color: _ink500.withValues(alpha: 0.5), width: 1),
                  bottom: BorderSide(
                      color: _ink500.withValues(alpha: 0.5), width: 1),
                ),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                PriceFormatter.formatCopWhole(_factura.total),
                style: headingStyle,
              ),
            ),
          ],
        ),
      ],
    );
  }

  TableRow _tableRow(int index, FacturaItem item, TextStyle style) {
    final isEmpty = item.descripcion.trim().isEmpty;
    return TableRow(
      children: [
        _td(isEmpty ? '' : '$index', style, align: TextAlign.center),
        _td(item.codigo, style, align: TextAlign.center),
        _td(item.descripcion, style),
        _td(item.unidad, style, align: TextAlign.center),
        _td(_formatCantidadEntera(item.cantidad), style,
            align: TextAlign.center),
        _td(isEmpty ? '' : PriceFormatter.formatCopWhole(item.precioUnitario),
            style,
            align: TextAlign.right),
        _td(isEmpty ? '' : PriceFormatter.formatCopWhole(item.totalLinea),
            style,
            align: TextAlign.right),
      ],
    );
  }

  Widget _th(String text, TextStyle style) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Text(text, style: style, textAlign: TextAlign.center),
      );

  Widget _buildEstadoChip(String estado) {
    final normalized = estado.trim().toLowerCase();
    final color = switch (normalized) {
      'emitida' => _emerald600,
      'anulada' => _rose600,
      _ => _amber700,
    };

    final label = switch (normalized) {
      'emitida' => 'Emitida',
      'anulada' => 'Anulada',
      _ => 'Pendiente',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        'Estado: $label',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _td(String text, TextStyle style,
          {TextAlign align = TextAlign.left}) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Text(
          text,
          style: style,
          textAlign: align,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
        ),
      );

  Widget _buildSignature(
      {required String firmaPath, required String fallbackName}) {
    if (firmaPath.isEmpty) {
      return SizedBox(
        height: 62,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            fallbackName,
            style: const TextStyle(
                fontFamily: 'serif', fontStyle: FontStyle.italic, fontSize: 36),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }

    if (_isHttpUrl(firmaPath)) {
      return SizedBox(
        height: 62,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Image.network(
            _resolveUrl(firmaPath),
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Text(fallbackName,
                style:
                    const TextStyle(fontStyle: FontStyle.italic, fontSize: 30)),
          ),
        ),
      );
    }

    final file = File(firmaPath);
    if (file.existsSync()) {
      return SizedBox(
        height: 62,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Image.file(file, fit: BoxFit.contain),
        ),
      );
    }

    return SizedBox(
      height: 62,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(fallbackName,
            style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 30)),
      ),
    );
  }

  bool _isHttpUrl(String value) {
    final trimmed = value.trim().toLowerCase();
    return trimmed.startsWith('http://') || trimmed.startsWith('https://');
  }

  String _resolveUrl(String path) {
    final trimmed = path.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    final base = AppConfig.apiBaseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    return '$base${trimmed.startsWith('/') ? '' : '/'}$trimmed';
  }

  String _extractCuentaCobroNumero(Factura factura) {
    final source =
        factura.codigo.trim().isNotEmpty ? factura.codigo : factura.numero;
    final match = RegExp(r'(\d+)$').firstMatch(source.trim());
    if (match == null) return source;
    final number = int.tryParse(match.group(1)!);
    if (number == null) return source;
    return number.toString().padLeft(3, '0');
  }

  String _formatCantidadEntera(String raw) {
    final value = PriceFormatter.parse(raw);
    if (value == 0) {
      return raw.trim().isEmpty ? '' : '0';
    }
    return value.round().toString();
  }

  String _formatFechaLarga(String raw) {
    final date = DateTime.tryParse(raw);
    if (date == null) return raw;

    const months = [
      'de enero de',
      'de febrero de',
      'de marzo de',
      'de abril de',
      'de mayo de',
      'de junio de',
      'de julio de',
      'de agosto de',
      'de septiembre de',
      'de octubre de',
      'de noviembre de',
      'de diciembre de',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _numberToSpanishWords(int value) {
    if (value == 0) return 'Cero';

    String convert(int n) {
      const unidades = [
        '',
        'uno',
        'dos',
        'tres',
        'cuatro',
        'cinco',
        'seis',
        'siete',
        'ocho',
        'nueve'
      ];
      const especiales = [
        'diez',
        'once',
        'doce',
        'trece',
        'catorce',
        'quince',
        'dieciseis',
        'diecisiete',
        'dieciocho',
        'diecinueve'
      ];
      const decenas = [
        '',
        '',
        'veinte',
        'treinta',
        'cuarenta',
        'cincuenta',
        'sesenta',
        'setenta',
        'ochenta',
        'noventa'
      ];
      const centenas = [
        '',
        'ciento',
        'doscientos',
        'trescientos',
        'cuatrocientos',
        'quinientos',
        'seiscientos',
        'setecientos',
        'ochocientos',
        'novecientos'
      ];

      if (n == 0) return '';
      if (n == 100) return 'cien';
      if (n < 10) return unidades[n];
      if (n < 20) return especiales[n - 10];
      if (n < 30) {
        if (n == 20) return 'veinte';
        return 'veinti${unidades[n - 20]}';
      }
      if (n < 100) {
        final d = n ~/ 10;
        final u = n % 10;
        return u == 0 ? decenas[d] : '${decenas[d]} y ${unidades[u]}';
      }
      final c = n ~/ 100;
      final r = n % 100;
      return r == 0 ? centenas[c] : '${centenas[c]} ${convert(r)}';
    }

    final millones = value ~/ 1000000;
    final miles = (value % 1000000) ~/ 1000;
    final cientos = value % 1000;

    final parts = <String>[];
    if (millones > 0) {
      parts.add(millones == 1 ? 'un millon' : '${convert(millones)} millones');
    }
    if (miles > 0) {
      parts.add(miles == 1 ? 'mil' : '${convert(miles)} mil');
    }
    if (cientos > 0) {
      parts.add(convert(cientos));
    }

    final joined = parts.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    return joined.isEmpty
        ? 'Cero'
        : joined[0].toUpperCase() + joined.substring(1);
  }
}
