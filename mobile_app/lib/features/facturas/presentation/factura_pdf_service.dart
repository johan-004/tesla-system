import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/config/app_config.dart';
import '../../../shared/utils/price_formatter.dart';
import '../domain/factura.dart';
import '../domain/factura_item.dart';

const _logoTeslaAsset = 'assets/images/logo_tesla.png';
const _institutionalText =
    'DISEÑO Y EJECUCIÓN DE PROYECTOS ELÉCTRICOS, EN NIVELES DE MEDIA Y BAJA TENSIÓN, MANTENIMIENTO Y CONSTRUCCION DE SUBESTACIONES ELECTRICAS DE DISTRIBUCION, MANTENIMIENTO E INSTALACION DE SISTEMAS Y EQUIPOS ELECTRICOS, EN AMBIENTES INDUSTRIALES, DOMICILIARIO Y OFICINA, DISENO E IMPLEMENTACIÓN DE PLANES DE MITIGACIÓN EN RIESGO ELÉCTRICO, MANTENIMIENTO EN PODA DE VEGETACIÓN CON CONTACTO DIRECTO EN REDES ELÉCTRICAS PRIMARIAS Y SECUNDARIAS.';
const _footerLineOne = 'Calle 13 Sur N° 15 76 - Cel 3004332599';
const _footerLineTwo = 'E-mail proyeccioneselectricastesla@gmail.com';
const _footerLineThree = 'Villavicencio Meta.';

class FacturaPdfService {
  static Future<Uint8List> buildPdf(Factura factura) async {
    final document = pw.Document();
    final robotoRegular = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Roboto-Regular.ttf'),
    );
    final robotoBold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Roboto-Bold.ttf'),
    );
    final theme = pw.ThemeData.withFont(
      base: robotoRegular,
      bold: robotoBold,
      italic: robotoRegular,
      boldItalic: robotoBold,
    );

    final logo = await _loadAssetImage(_logoTeslaAsset);
    final firmaImage = await _loadFirmaImage(factura.firmaPath);
    final rows = _resolveRows(factura);
    final layout = _resolveLayout(rows);

    final ciudadExpedicion = (factura.ciudadExpedicion ?? '').trim().isEmpty
        ? 'Villavicencio, Meta'
        : factura.ciudadExpedicion!.trim();
    final clienteNombre = factura.clienteNombre.trim().isEmpty
        ? 'CLIENTE PENDIENTE'
        : factura.clienteNombre.trim().toUpperCase();
    final clienteNit = (factura.clienteNit ?? '').trim();
    final clienteCiudad = (factura.clienteCiudad ?? '').trim().isEmpty
        ? 'Villavicencio.'
        : factura.clienteCiudad!.trim();
    final cuentaCobroNumero = _extractCuentaCobroNumero(factura);
    final totalNumber = PriceFormatter.parse(factura.total).round();
    final totalWords = '${_numberToSpanishWords(totalNumber)} pesos mcte';
    final totalText = PriceFormatter.formatCopWhole(factura.total);

    final firmaNombreRaw =
        (factura.firmaNombre ?? 'María Alejandra Flórez Ocampo.').trim();
    final firmaNombre = firmaNombreRaw.isEmpty
        ? 'María Alejandra Flórez Ocampo.'
        : firmaNombreRaw;
    final firmaCargoRaw = (factura.firmaCargo ?? 'Representante Legal').trim();
    final firmaCargo =
        firmaCargoRaw.isEmpty ? 'Representante Legal' : firmaCargoRaw;
    final firmaEmpresaRaw =
        (factura.firmaEmpresa ?? 'Proyecciones eléctricas Tesla.').trim();
    final firmaEmpresa = firmaEmpresaRaw.isEmpty
        ? 'Proyecciones eléctricas Tesla.'
        : firmaEmpresaRaw;

    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        margin: const pw.EdgeInsets.fromLTRB(28, 16, 28, 12),
        build: (_) {
          return pw.Container(
            color: PdfColors.white,
            child: pw.Stack(
              children: [
                if (logo != null)
                  pw.Positioned.fill(
                    child: pw.Center(
                      child: pw.Opacity(
                        opacity: layout.watermarkOpacity,
                        child: pw.SizedBox(
                          width: layout.watermarkSize,
                          height: layout.watermarkSize,
                          child: pw.Image(logo, fit: pw.BoxFit.contain),
                        ),
                      ),
                    ),
                  ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    if (logo != null)
                      pw.Image(logo,
                          height: layout.logoHeight,
                          alignment: pw.Alignment.centerLeft),
                    pw.SizedBox(height: layout.headerGap),
                    pw.Text(
                      _institutionalText,
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontSize: layout.institutionalFontSize,
                        lineSpacing: 1.1,
                      ),
                    ),
                    pw.SizedBox(height: layout.headerGap),
                    pw.Text(
                      '$ciudadExpedicion ${_formatFechaLarga(factura.fecha)}',
                      style: pw.TextStyle(
                        fontSize: layout.titleFontSize,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Cuenta de cobro N° $cuentaCobroNumero.',
                      style: pw.TextStyle(
                        fontSize: layout.titleFontSize,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: layout.sectionGap),
                    pw.Text(
                      clienteNombre,
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontSize: layout.centerTitleFontSize,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    if (clienteNit.isNotEmpty)
                      pw.Text(
                        'NIT. $clienteNit',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          fontSize: layout.centerTitleFontSize,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    pw.Text(
                      clienteCiudad,
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(fontSize: layout.centerBodyFontSize),
                    ),
                    pw.SizedBox(height: layout.blockGap),
                    pw.Text(
                      'Debe a:',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(fontSize: layout.centerBodyFontSize),
                    ),
                    pw.Text(
                      'PROYECCIONES ELÉCTRICAS TESLA',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontSize: layout.centerTitleFontSize,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'CC. 1.096.224.844-1.',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(fontSize: layout.centerBodyFontSize),
                    ),
                    pw.SizedBox(height: layout.blockGap),
                    pw.Text(
                      'La suma de:',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(fontSize: layout.centerBodyFontSize),
                    ),
                    pw.Text(
                      '$totalWords ($totalText)',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(fontSize: layout.centerBodyFontSize),
                    ),
                    pw.SizedBox(height: layout.blockGap),
                    pw.Text(
                      'Ref. Cuenta de cobro.',
                      style: pw.TextStyle(
                        fontSize: layout.refFontSize,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Expanded(
                      child: _buildStretchTableArea(
                        rows: rows,
                        total: factura.total,
                        layout: layout,
                      ),
                    ),
                    pw.Text(
                      'Cordialmente,',
                      style:
                          pw.TextStyle(fontSize: layout.signatureTitleFontSize),
                    ),
                    pw.SizedBox(height: 6),
                    if (firmaImage != null)
                      pw.Image(
                        firmaImage,
                        height: layout.signatureImageHeight,
                        fit: pw.BoxFit.contain,
                        alignment: pw.Alignment.centerLeft,
                      )
                    else
                      pw.Text(
                        firmaNombre,
                        style: pw.TextStyle(
                          fontSize: layout.signatureFallbackFontSize,
                          fontStyle: pw.FontStyle.italic,
                        ),
                      ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      firmaNombre,
                      style: pw.TextStyle(
                        fontSize: layout.signatureBodyFontSize,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      firmaCargo,
                      style: pw.TextStyle(
                        fontSize: layout.signatureBodyFontSize,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      firmaEmpresa,
                      style: pw.TextStyle(
                        fontSize: layout.signatureBodyFontSize,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Favor consignar a la cuenta de ahorros N° 05763353119, Bancolombia',
                      style: pw.TextStyle(
                        fontSize: layout.bankLineFontSize,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Container(height: 4, color: PdfColors.black),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      _footerLineOne,
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontSize: layout.footerFontSize,
                        color: PdfColors.grey600,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      _footerLineTwo,
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontSize: layout.footerFontSize,
                        color: PdfColors.grey600,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      _footerLineThree,
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontSize: layout.footerFontSize,
                        color: PdfColors.grey600,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    return document.save();
  }

  static String buildFileName(Factura factura) {
    final rawCodigo = factura.codigo.trim().isEmpty
        ? factura.numero.trim()
        : factura.codigo.trim();
    final normalized = rawCodigo.isEmpty
        ? 'factura'
        : rawCodigo.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '-');
    return '${normalized}_${DateTime.now().millisecondsSinceEpoch}.pdf';
  }

  static pw.Widget _buildStretchTableArea({
    required List<FacturaItem> rows,
    required String total,
    required _FacturaLayout layout,
  }) {
    return pw.LayoutBuilder(
      builder: (context, constraints) {
        final rowCount = rows.isEmpty ? 1 : rows.length;
        final availableHeight = constraints!.maxHeight;
        // Reserve some height for borders/rounding so TOTAL row never gets clipped.
        final rowsAvailable = availableHeight -
            layout.tableHeaderHeight -
            layout.tableTotalHeight -
            14;

        final suggested = rowsAvailable / rowCount;
        final adaptiveCellHeight = suggested.isFinite && suggested > 0
            ? suggested
            : layout.tableCellHeight;

        return pw.Align(
          alignment: pw.Alignment.topCenter,
          child: _buildTable(
            rows: rows,
            total: total,
            layout: layout,
            cellHeightOverride: adaptiveCellHeight,
          ),
        );
      },
    );
  }

  static pw.Widget _buildTable({
    required List<FacturaItem> rows,
    required String total,
    required _FacturaLayout layout,
    double? cellHeightOverride,
  }) {
    final cellHeight = cellHeightOverride ?? layout.tableCellHeight;
    final mainRows = rows
        .asMap()
        .entries
        .map(
          (entry) => <String>[
            entry.value.descripcion.trim().isEmpty ? '' : '${entry.key + 1}',
            entry.value.codigo.trim(),
            _normalizeDescripcion(entry.value.descripcion, layout.maxDescChars),
            entry.value.unidad,
            _formatCantidadEntera(entry.value.cantidad),
            entry.value.descripcion.trim().isEmpty
                ? ''
                : PriceFormatter.formatCopWhole(entry.value.precioUnitario),
            entry.value.descripcion.trim().isEmpty
                ? ''
                : PriceFormatter.formatCopWhole(entry.value.totalLinea),
          ],
        )
        .toList();

    final border = pw.TableBorder.all(color: PdfColors.grey600, width: 0.8);
    const widths = <int, pw.TableColumnWidth>{
      0: pw.FixedColumnWidth(32),
      1: pw.FixedColumnWidth(62),
      2: pw.FlexColumnWidth(3.8),
      3: pw.FixedColumnWidth(46),
      4: pw.FixedColumnWidth(46),
      5: pw.FixedColumnWidth(68),
      6: pw.FixedColumnWidth(80),
    };

    final headerStyle = pw.TextStyle(
      fontWeight: pw.FontWeight.bold,
      fontSize: layout.tableHeaderFontSize,
    );
    final cellStyle = pw.TextStyle(
      fontSize: layout.tableCellFontSize,
      lineSpacing: 1.0,
    );

    final table = pw.Table(
      border: border,
      columnWidths: widths,
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey400),
          children: [
            _tableCell('Ítem',
                style: headerStyle,
                height: layout.tableHeaderHeight,
                align: pw.Alignment.center),
            _tableCell('Código',
                style: headerStyle,
                height: layout.tableHeaderHeight,
                align: pw.Alignment.center),
            _tableCell('Descripción',
                style: headerStyle,
                height: layout.tableHeaderHeight,
                align: pw.Alignment.center),
            _tableCell('Unid.',
                style: headerStyle,
                height: layout.tableHeaderHeight,
                align: pw.Alignment.center),
            _tableCell('Cant.',
                style: headerStyle,
                height: layout.tableHeaderHeight,
                align: pw.Alignment.center),
            _tableCell('V. Unit',
                style: headerStyle,
                height: layout.tableHeaderHeight,
                align: pw.Alignment.centerRight),
            _tableCell('Total',
                style: headerStyle,
                height: layout.tableHeaderHeight,
                align: pw.Alignment.centerRight),
          ],
        ),
        ...mainRows.map(
          (row) => pw.TableRow(
            children: [
              _tableCell(row[0],
                  style: cellStyle,
                  height: cellHeight,
                  align: pw.Alignment.center),
              _tableCell(row[1],
                  style: cellStyle,
                  height: cellHeight,
                  align: pw.Alignment.center),
              _tableCell(row[2],
                  style: cellStyle,
                  height: cellHeight,
                  align: pw.Alignment.centerLeft),
              _tableCell(row[3],
                  style: cellStyle,
                  height: cellHeight,
                  align: pw.Alignment.center),
              _tableCell(row[4],
                  style: cellStyle,
                  height: cellHeight,
                  align: pw.Alignment.center),
              _tableCell(row[5],
                  style: cellStyle,
                  height: cellHeight,
                  align: pw.Alignment.centerRight),
              _tableCell(row[6],
                  style: cellStyle,
                  height: cellHeight,
                  align: pw.Alignment.centerRight),
            ],
          ),
        ),
      ],
    );

    final totalRow = pw.Table(
      border: border,
      columnWidths: const {
        0: pw.FlexColumnWidth(),
        1: pw.FixedColumnWidth(80),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey400),
          children: [
            pw.Container(
              height: layout.tableTotalHeight,
              alignment: pw.Alignment.center,
              child: pw.Text(
                'TOTAL',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: layout.tableHeaderFontSize,
                ),
              ),
            ),
            pw.Container(
              height: layout.tableTotalHeight,
              alignment: pw.Alignment.centerRight,
              padding: const pw.EdgeInsets.symmetric(horizontal: 6),
              child: pw.Text(
                PriceFormatter.formatCopWhole(total),
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: layout.tableHeaderFontSize,
                ),
              ),
            ),
          ],
        ),
      ],
    );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [table, totalRow],
    );
  }

  static pw.Widget _tableCell(
    String value, {
    required pw.TextStyle style,
    required double height,
    required pw.Alignment align,
  }) {
    return pw.Container(
      height: height,
      alignment: align,
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      child: pw.Text(
        value,
        style: style,
        maxLines: 1,
      ),
    );
  }

  static List<FacturaItem> _resolveRows(Factura factura) {
    final rows = <FacturaItem>[...factura.items];
    while (rows.length < 5) {
      rows.add(
        FacturaItem(
          id: -rows.length,
          facturaId: factura.id,
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
    return rows;
  }

  static _FacturaLayout _resolveLayout(List<FacturaItem> rows) {
    final nonEmptyRows = rows
        .where((row) => row.descripcion.trim().isNotEmpty)
        .toList(growable: false);
    final count = nonEmptyRows.isEmpty ? rows.length : nonEmptyRows.length;
    final maxDescLength = nonEmptyRows
        .map((row) => row.descripcion.trim().length)
        .fold<int>(0, (max, len) => len > max ? len : max);

    if (count <= 5 && maxDescLength <= 55) {
      return const _FacturaLayout.regular();
    }
    if (count <= 8 && maxDescLength <= 120) {
      return const _FacturaLayout.compact();
    }
    if (count <= 10 && maxDescLength <= 150) {
      return const _FacturaLayout.tight();
    }
    if (count <= 14) {
      return const _FacturaLayout.ultra();
    }
    if (count <= 24) {
      return const _FacturaLayout.extreme();
    }
    return const _FacturaLayout.mega();
  }

  static String _normalizeDescripcion(String raw, int maxChars) {
    final text = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (text.length <= maxChars) {
      return text;
    }
    return '${text.substring(0, maxChars - 1)}…';
  }

  static String _formatCantidadEntera(String raw) {
    final value = PriceFormatter.parse(raw);
    if (value == 0) {
      return raw.trim().isEmpty ? '' : '0';
    }
    return value.round().toString();
  }

  static String _extractCuentaCobroNumero(Factura factura) {
    final source =
        factura.codigo.trim().isNotEmpty ? factura.codigo : factura.numero;
    final match = RegExp(r'(\d+)$').firstMatch(source.trim());
    if (match == null) return source;
    final number = int.tryParse(match.group(1)!);
    if (number == null) return source;
    return number.toString().padLeft(3, '0');
  }

  static String _formatFechaLarga(String raw) {
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

  static String _numberToSpanishWords(int value) {
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

  static Future<pw.MemoryImage?> _loadAssetImage(String path) async {
    try {
      final bytes = await rootBundle.load(path);
      return pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  static Future<pw.MemoryImage?> _loadFirmaImage(String? rawPath) async {
    final path = (rawPath ?? '').trim();
    if (path.isEmpty) {
      return null;
    }

    try {
      if (path.startsWith('assets/')) {
        final bytes = await rootBundle.load(path);
        return pw.MemoryImage(bytes.buffer.asUint8List());
      }

      if (path.startsWith('http://') || path.startsWith('https://')) {
        final uri = Uri.parse(path);
        final response = await http.get(uri);
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return pw.MemoryImage(response.bodyBytes);
        }
        return null;
      }

      if (path.startsWith('/')) {
        final apiUri = Uri.tryParse(AppConfig.apiBaseUrl);
        if (apiUri == null) {
          return null;
        }

        final base = Uri(
          scheme: apiUri.scheme,
          host: apiUri.host,
          port: apiUri.hasPort ? apiUri.port : null,
        );
        final response = await http.get(base.resolve(path));
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return pw.MemoryImage(response.bodyBytes);
        }
      }

      final file = File(path);
      if (await file.exists()) {
        return pw.MemoryImage(await file.readAsBytes());
      }
    } catch (_) {
      return null;
    }

    return null;
  }
}

class _FacturaLayout {
  const _FacturaLayout({
    required this.logoHeight,
    required this.headerGap,
    required this.sectionGap,
    required this.blockGap,
    required this.afterTableGap,
    required this.institutionalFontSize,
    required this.titleFontSize,
    required this.centerTitleFontSize,
    required this.centerBodyFontSize,
    required this.refFontSize,
    required this.tableHeaderFontSize,
    required this.tableCellFontSize,
    required this.tableHeaderHeight,
    required this.tableCellHeight,
    required this.tableCellMinHeight,
    required this.tableCellMaxHeight,
    required this.tableTotalHeight,
    required this.signatureTitleFontSize,
    required this.signatureImageHeight,
    required this.signatureFallbackFontSize,
    required this.signatureBodyFontSize,
    required this.bankLineFontSize,
    required this.footerFontSize,
    required this.maxDescChars,
    required this.watermarkOpacity,
    required this.watermarkSize,
  });

  const _FacturaLayout.regular()
      : logoHeight = 52,
        headerGap = 8,
        sectionGap = 18,
        blockGap = 8,
        afterTableGap = 4,
        institutionalFontSize = 9.8,
        titleFontSize = 15,
        centerTitleFontSize = 17,
        centerBodyFontSize = 16,
        refFontSize = 16,
        tableHeaderFontSize = 11,
        tableCellFontSize = 10.7,
        tableHeaderHeight = 24,
        tableCellHeight = 28,
        tableCellMinHeight = 22,
        tableCellMaxHeight = 46,
        tableTotalHeight = 24,
        signatureTitleFontSize = 16,
        signatureImageHeight = 54,
        signatureFallbackFontSize = 28,
        signatureBodyFontSize = 14,
        bankLineFontSize = 15,
        footerFontSize = 12.5,
        maxDescChars = 62,
        watermarkOpacity = 0.34,
        watermarkSize = 500;

  const _FacturaLayout.compact()
      : logoHeight = 48,
        headerGap = 6,
        sectionGap = 12,
        blockGap = 5,
        afterTableGap = 3,
        institutionalFontSize = 9,
        titleFontSize = 13.4,
        centerTitleFontSize = 14.6,
        centerBodyFontSize = 13.6,
        refFontSize = 14.4,
        tableHeaderFontSize = 9.8,
        tableCellFontSize = 9.1,
        tableHeaderHeight = 22,
        tableCellHeight = 24.5,
        tableCellMinHeight = 19,
        tableCellMaxHeight = 42,
        tableTotalHeight = 22,
        signatureTitleFontSize = 14.4,
        signatureImageHeight = 44,
        signatureFallbackFontSize = 22,
        signatureBodyFontSize = 11.8,
        bankLineFontSize = 12.8,
        footerFontSize = 11.2,
        maxDescChars = 56,
        watermarkOpacity = 0.38,
        watermarkSize = 520;

  const _FacturaLayout.tight()
      : logoHeight = 42,
        headerGap = 4,
        sectionGap = 8,
        blockGap = 4,
        afterTableGap = 2,
        institutionalFontSize = 8.2,
        titleFontSize = 12,
        centerTitleFontSize = 12.9,
        centerBodyFontSize = 12.1,
        refFontSize = 13,
        tableHeaderFontSize = 9.1,
        tableCellFontSize = 8.2,
        tableHeaderHeight = 20,
        tableCellHeight = 21,
        tableCellMinHeight = 15.5,
        tableCellMaxHeight = 34,
        tableTotalHeight = 20,
        signatureTitleFontSize = 12.8,
        signatureImageHeight = 34,
        signatureFallbackFontSize = 18,
        signatureBodyFontSize = 10.4,
        bankLineFontSize = 10.9,
        footerFontSize = 9.7,
        maxDescChars = 46,
        watermarkOpacity = 0.42,
        watermarkSize = 530;

  const _FacturaLayout.ultra()
      : logoHeight = 38,
        headerGap = 3,
        sectionGap = 6,
        blockGap = 3,
        afterTableGap = 2,
        institutionalFontSize = 7.8,
        titleFontSize = 11.1,
        centerTitleFontSize = 11.8,
        centerBodyFontSize = 10.9,
        refFontSize = 11.8,
        tableHeaderFontSize = 8.1,
        tableCellFontSize = 7.2,
        tableHeaderHeight = 16,
        tableCellHeight = 14.2,
        tableCellMinHeight = 12.2,
        tableCellMaxHeight = 24,
        tableTotalHeight = 16,
        signatureTitleFontSize = 11.2,
        signatureImageHeight = 29,
        signatureFallbackFontSize = 16,
        signatureBodyFontSize = 9.5,
        bankLineFontSize = 10,
        footerFontSize = 9,
        maxDescChars = 30,
        watermarkOpacity = 0.46,
        watermarkSize = 540;

  const _FacturaLayout.extreme()
      : logoHeight = 36,
        headerGap = 2.5,
        sectionGap = 5,
        blockGap = 2.5,
        afterTableGap = 1.5,
        institutionalFontSize = 7.4,
        titleFontSize = 10.4,
        centerTitleFontSize = 11,
        centerBodyFontSize = 10.1,
        refFontSize = 11.1,
        tableHeaderFontSize = 7.6,
        tableCellFontSize = 6.8,
        tableHeaderHeight = 14.5,
        tableCellHeight = 12.8,
        tableCellMinHeight = 10.6,
        tableCellMaxHeight = 20,
        tableTotalHeight = 14.5,
        signatureTitleFontSize = 10.4,
        signatureImageHeight = 24,
        signatureFallbackFontSize = 14,
        signatureBodyFontSize = 8.8,
        bankLineFontSize = 9.3,
        footerFontSize = 8.6,
        maxDescChars = 24,
        watermarkOpacity = 0.50,
        watermarkSize = 545;

  const _FacturaLayout.mega()
      : logoHeight = 34,
        headerGap = 2,
        sectionGap = 4,
        blockGap = 2,
        afterTableGap = 1,
        institutionalFontSize = 7.0,
        titleFontSize = 9.8,
        centerTitleFontSize = 10.4,
        centerBodyFontSize = 9.5,
        refFontSize = 10.5,
        tableHeaderFontSize = 7.1,
        tableCellFontSize = 6.3,
        tableHeaderHeight = 13.5,
        tableCellHeight = 11.2,
        tableCellMinHeight = 8.4,
        tableCellMaxHeight = 16.5,
        tableTotalHeight = 13.5,
        signatureTitleFontSize = 10.0,
        signatureImageHeight = 20,
        signatureFallbackFontSize = 12.0,
        signatureBodyFontSize = 8.1,
        bankLineFontSize = 8.8,
        footerFontSize = 8.1,
        maxDescChars = 20,
        watermarkOpacity = 0.52,
        watermarkSize = 550;

  final double logoHeight;
  final double headerGap;
  final double sectionGap;
  final double blockGap;
  final double afterTableGap;
  final double institutionalFontSize;
  final double titleFontSize;
  final double centerTitleFontSize;
  final double centerBodyFontSize;
  final double refFontSize;
  final double tableHeaderFontSize;
  final double tableCellFontSize;
  final double tableHeaderHeight;
  final double tableCellHeight;
  final double tableCellMinHeight;
  final double tableCellMaxHeight;
  final double tableTotalHeight;
  final double signatureTitleFontSize;
  final double signatureImageHeight;
  final double signatureFallbackFontSize;
  final double signatureBodyFontSize;
  final double bankLineFontSize;
  final double footerFontSize;
  final int maxDescChars;
  final double watermarkOpacity;
  final double watermarkSize;
}
