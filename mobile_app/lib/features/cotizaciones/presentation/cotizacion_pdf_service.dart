import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/config/app_config.dart';
import '../../../shared/utils/price_formatter.dart';
import '../domain/cotizacion.dart';

const _pdfInstitutionalText =
    'DISEÑO Y EJECUCIÓN DE PROYECTOS ELÉCTRICOS, EN NIVELES DE MEDIA Y BAJA TENSIÓN, MANTENIMIENTO Y CONSTRUCCIÓN DE SUBESTACIONES ELÉCTRICAS DE DISTRIBUCIÓN, MANTENIMIENTO E INSTALACIÓN DE SISTEMAS Y EQUIPOS ELÉCTRICOS, EN AMBIENTES INDUSTRIALES, DOMICILIARIO Y OFICINA, DISEÑO E IMPLEMENTACIÓN DE PLANES DE MITIGACIÓN EN RIESGO ELÉCTRICO, MANTENIMIENTO EN PODA DE VEGETACIÓN CON CONTACTO DIRECTO EN REDES ELECTRICAS PRIMARIAS Y SECUNDARIAS.';
const _pdfIntroParagraphOne =
    'En atención a su solicitud, me permito presentar la cotización correspondiente al desarrollo del trabajo eléctrico requerido.';
const _pdfIntroParagraphTwo =
    'El proyecto será entregado cumpliendo todos los requisitos técnicos y normativos, garantizando la seguridad, funcionalidad y legalidad de las instalaciones eléctricas.';
const _pdfFooterLineOne = 'Calle 13 Sur N°15 76 - Cel 3138260081';
const _pdfFooterLineTwo = 'E-mail proyeccioneselectricastesla@gmail.com';
const _pdfFooterLineThree = 'Villavicencio Meta.';
const _pdfDefaultFirmaNombre = 'María Alejandra Flórez Ocampo.';
const _pdfDefaultFirmaCargo = 'Representante.';
const _pdfDefaultFirmaEmpresa = 'Proyecciones eléctricas Tesla';
const _pdfDefaultAlcanceItems = <String>[
  'Tendido de redes de media y baja tensión.',
  'Instalación de una subestación tipo poste equipada con transformador de 112,5 kVA.',
  'Ejecución de actividades conforme a normatividad vigente, incluyendo RETIE y NTC 2050.',
];
const _pdfMaxObservacionesWords = 140;

class CotizacionPdfService {
  static Future<Uint8List> buildPdf(Cotizacion cotizacion) async {
    final document = pw.Document();
    final robotoRegular = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Roboto-Regular.ttf'),
    );
    final robotoBold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Roboto-Bold.ttf'),
    );
    final pdfTheme = pw.ThemeData.withFont(
      base: robotoRegular,
      bold: robotoBold,
      italic: robotoRegular,
      boldItalic: robotoBold,
    );
    final logo = await _loadAssetImage('assets/images/logo_tesla.png');
    final marcaAgua =
        await _loadAssetImage('assets/images/marca_agua_tesla.png');
    final firmaImage = await _loadFirmaImage(cotizacion.firmaPath);
    final fecha = _parseFecha(cotizacion.fecha) ?? DateTime.now();
    final detalles = List<CotizacionDetalle>.from(cotizacion.detalles)
      ..sort((left, right) => left.item.compareTo(right.item));
    final observaciones = _trimObservacionesForPdf(
      cotizacion.observaciones ?? '',
      maxWords: _pdfMaxObservacionesWords,
    );
    final hasObservaciones = observaciones.isNotEmpty;
    final observacionesWords = _countWords(observaciones);
    final targetVisibleRows = _resolveTargetVisibleRows(
      detallesCount: detalles.length,
    );
    final alcance = cotizacion.alcanceItems.isEmpty
        ? _pdfDefaultAlcanceItems
        : cotizacion.alcanceItems;
    final firmaNombre =
        _fallbackText(cotizacion.firmaNombre, fallback: _pdfDefaultFirmaNombre);
    final firmaCargo =
        _fallbackText(cotizacion.firmaCargo, fallback: _pdfDefaultFirmaCargo);
    final firmaEmpresa = _fallbackText(cotizacion.firmaEmpresa,
        fallback: _pdfDefaultFirmaEmpresa);
    final tableLayout = _resolveTableLayout(
      detallesCount: detalles.length,
      hasObservaciones: hasObservaciones,
      observacionesWords: observacionesWords,
      maxDescripcionLength: detalles
          .map((detalle) => detalle.descripcion.trim().length)
          .fold<int>(
              0, (maxValue, length) => length > maxValue ? length : maxValue),
    );

    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pdfTheme,
        margin: pw.EdgeInsets.fromLTRB(
          32,
          tableLayout.pageMarginTop,
          32,
          tableLayout.pageMarginBottom,
        ),
        build: (context) => pw.Container(
          color: PdfColors.white,
          child: pw.Stack(
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                _buildHeader(logo, layout: tableLayout),
                pw.SizedBox(height: tableLayout.headerBottomSpacing),
                pw.Text(
                  '${_fallbackText(cotizacion.ciudad, fallback: 'Ciudad pendiente')}, ${_formatFechaLarga(fecha)}.',
                  style: pw.TextStyle(
                    fontSize: tableLayout.titleFontSize,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: tableLayout.sectionSpacing),
                pw.Text(
                  'Señores:',
                  style: pw.TextStyle(
                    fontSize: tableLayout.bodyTitleFontSize,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  _fallbackText(
                    cotizacion.clienteNombre,
                    fallback: 'CLIENTE PENDIENTE',
                  ).toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: tableLayout.bodyTitleFontSize,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'NIT: ${_fallbackText(cotizacion.clienteNit, fallback: 'PENDIENTE')}',
                  style: pw.TextStyle(
                    fontSize: tableLayout.bodyFontSize,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  _fallbackText(
                    cotizacion.clienteContacto,
                    fallback: 'Representante pendiente',
                  ).toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: tableLayout.bodyFontSize,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  _fallbackText(
                    cotizacion.clienteCargo,
                    fallback: 'Cargo pendiente',
                  ),
                  style: pw.TextStyle(
                    fontSize: tableLayout.bodyFontSize,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  _fallbackText(
                    cotizacion.clienteCiudad,
                    fallback: 'Ciudad pendiente',
                  ),
                  style: pw.TextStyle(
                    fontSize: tableLayout.bodyFontSize,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: tableLayout.sectionSpacing),
                pw.Text(
                  'Ref. COTIZACIÓN, ${_fallbackText(cotizacion.referencia, fallback: 'REFERENCIA PENDIENTE').toUpperCase()}.',
                  style: pw.TextStyle(
                    fontSize: tableLayout.bodyTitleFontSize,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: tableLayout.sectionSpacing),
                pw.Text(
                  _pdfIntroParagraphOne,
                  style: pw.TextStyle(
                    fontSize: tableLayout.paragraphFontSize,
                    lineSpacing: 1.35,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  _pdfIntroParagraphTwo,
                  style: pw.TextStyle(
                    fontSize: tableLayout.paragraphFontSize,
                    lineSpacing: 1.35,
                  ),
                ),
                pw.SizedBox(height: tableLayout.sectionSpacing),
                pw.Text(
                  'Cuadro descriptivo:',
                  style: pw.TextStyle(
                    fontSize: tableLayout.bodyTitleFontSize,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 6),
                _buildDetallesTable(
                  detalles: detalles,
                  total: cotizacion.total,
                  layout: tableLayout,
                  minVisibleRows: targetVisibleRows,
                ),
                pw.SizedBox(height: tableLayout.afterTableSpacing),
                pw.SizedBox(height: tableLayout.observacionesTopSpacing),
                pw.Text(
                  'Observaciones',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Container(
                  width: double.infinity,
                  constraints: const pw.BoxConstraints(minHeight: 54),
                  padding: pw.EdgeInsets.all(tableLayout.observacionesPadding),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400),
                    color: PdfColors.grey200,
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(6),
                    ),
                  ),
                  child: pw.Text(
                    hasObservaciones ? observaciones : '',
                    style: pw.TextStyle(
                      fontSize: tableLayout.observacionesFontSize,
                      lineSpacing: 1.25,
                    ),
                  ),
                ),
                pw.SizedBox(height: tableLayout.beforeFooterSpacing),
                _buildFooter(),
                ],
              ),
              if (marcaAgua != null)
                pw.Positioned.fill(
                  child: pw.Center(
                    child: pw.Opacity(
                      opacity: 0.28,
                      child: pw.SizedBox(
                        width: 360,
                        height: 560,
                        child: pw.Image(marcaAgua, fit: pw.BoxFit.contain),
                      ),
                    ),
                  ),
                ),
          ],
        ),
      ),
      ),
    );

    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pdfTheme,
        margin: const pw.EdgeInsets.fromLTRB(32, 24, 32, 18),
        build: (context) => pw.Container(
          color: PdfColors.white,
          child: pw.Stack(
            children: [
              if (marcaAgua != null)
                pw.Positioned.fill(
                  child: pw.Center(
                    child: pw.Opacity(
                      opacity: 0.34,
                      child: pw.SizedBox(
                        width: 460,
                        height: 700,
                        child: pw.Image(marcaAgua, fit: pw.BoxFit.contain),
                      ),
                    ),
                  ),
                ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                _buildHeader(logo, layout: tableLayout),
                pw.SizedBox(height: 32),
                pw.Text(
                  'EL ALCANCE DEL PROYECTO INCLUYE:',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 5),
                for (final item in alcance) ...[
                  _buildPdfListItem(
                    text: item,
                    fontSize: 10.5,
                    markerType: _PdfMarkerType.bolt,
                    markerColor: const PdfColor.fromInt(0xFF1D4ED8),
                  ),
                  pw.SizedBox(height: 2),
                ],
                pw.SizedBox(height: 36),
                pw.Text(
                  'CONDICIONES DE LA OFERTA:',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 44, right: 34),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.RichText(
                        text: pw.TextSpan(
                          style: const pw.TextStyle(
                            fontSize: 10.5,
                            lineSpacing: 1.3,
                          ),
                          children: [
                            pw.TextSpan(
                              text: 'Tiempo de entrega:',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            ),
                            pw.TextSpan(
                              text:
                                  ' El tiempo estimado para la ejecución del proyecto es de (${cotizacion.ofertaDiasTotales}) días calendario, salvo condiciones especiales que impidan el desarrollo normal de las actividades programadas. La distribución del tiempo de trabajo es la siguiente:',
                            ),
                          ],
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      _buildPdfListItem(
                        text:
                            '(${cotizacion.ofertaDiasEjecucion}) días de ejecución, a partir de este momento los predios podrán conectarse a la red de baja tensión, siempre y cuando cuenten con la acometida, caja para la instalación de medidor, caja de protecciones e instalación interna.',
                        fontSize: 10.5,
                        markerType: _PdfMarkerType.check,
                      ),
                      pw.SizedBox(height: 2),
                      _buildPdfListItem(
                        text:
                            '(${cotizacion.ofertaDiasTramitologia}) días tramitología ante EMSA.',
                        fontSize: 10.5,
                        markerType: _PdfMarkerType.check,
                      ),
                      pw.SizedBox(height: 8),
                      _buildPdfListItem(
                        text: 'Forma de pago:',
                        fontSize: 11.5,
                        markerType: _PdfMarkerType.bolt,
                        markerColor: const PdfColor.fromInt(0xFF1D4ED8),
                        bold: true,
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'La forma de pago para el desarrollo del proyecto se establece de la siguiente manera:',
                        style: const pw.TextStyle(
                          fontSize: 10.5,
                          lineSpacing: 1.3,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(left: 18),
                        child: pw.RichText(
                          text: pw.TextSpan(
                            style: const pw.TextStyle(
                              fontSize: 10.5,
                              lineSpacing: 1.3,
                            ),
                            children: [
                              pw.TextSpan(
                                text: 'Pago 1:',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold),
                              ),
                              pw.TextSpan(
                                text:
                                    ' Correspondiente al ${cotizacion.ofertaPago1Pct}% del valor total del contrato, contra entrega de la orden de servicio.',
                              ),
                            ],
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 1),
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(left: 18),
                        child: pw.RichText(
                          text: pw.TextSpan(
                            style: const pw.TextStyle(
                              fontSize: 10.5,
                              lineSpacing: 1.3,
                            ),
                            children: [
                              pw.TextSpan(
                                text: 'Pago 2:',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold),
                              ),
                              pw.TextSpan(
                                text:
                                    ' Correspondiente al ${cotizacion.ofertaPago2Pct}% del valor total, una vez se energice el transformador y la red de baja tensión.',
                              ),
                            ],
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 1),
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(left: 18),
                        child: pw.RichText(
                          text: pw.TextSpan(
                            style: const pw.TextStyle(
                              fontSize: 10.5,
                              lineSpacing: 1.3,
                            ),
                            children: [
                              pw.TextSpan(
                                text: 'Pago 3:',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold),
                              ),
                              pw.TextSpan(
                                text:
                                    ' Correspondiente al ${cotizacion.ofertaPago3Pct}% restante, último pago parcial, a realizar una vez se instalen los medidores en los predios legalizados.',
                              ),
                            ],
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      _buildPdfListItem(
                        text:
                            'Garantía: ${cotizacion.ofertaGarantiaMeses} meses, bajo condiciones eléctricas normales.',
                        fontSize: 10.5,
                        markerType: _PdfMarkerType.bolt,
                        markerColor: const PdfColor.fromInt(0xFF1D4ED8),
                        bold: true,
                      ),
                    ],
                  ),
                ),
                pw.Spacer(),
                _buildSignatureBlock(
                  firmaImage: firmaImage,
                  firmaNombre: firmaNombre,
                  firmaCargo: firmaCargo,
                  firmaEmpresa: firmaEmpresa,
                ),
                pw.SizedBox(height: 8),
                _buildFooter(),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    return document.save();
  }

  static String buildFileName(Cotizacion cotizacion) {
    final rawCodigo = cotizacion.codigo.trim().isEmpty
        ? cotizacion.numero.trim()
        : cotizacion.codigo.trim();
    final normalizedCodigo = rawCodigo.isEmpty
        ? 'cotizacion'
        : rawCodigo.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '-');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${normalizedCodigo}_$timestamp.pdf';
  }

  static pw.Widget _buildDetallesTable({
    required List<CotizacionDetalle> detalles,
    required String total,
    required _TableLayoutConfig layout,
    required int minVisibleRows,
  }) {
    final rows = detalles.isEmpty
        ? <List<String>>[]
        : detalles
            .map(
              (detalle) => <String>[
                detalle.item > 0 ? '${detalle.item}' : '-',
                _normalizeDescripcionForTable(
                  _fallbackText(detalle.descripcion, fallback: '-'),
                  maxLength: layout.maxDescripcionChars,
                ),
                _fallbackText(detalle.unidad, fallback: '-'),
                _formatCantidad(detalle.cantidad),
                PriceFormatter.formatCopWhole(detalle.precioUnitario),
                PriceFormatter.formatCopWhole(detalle.subtotal),
              ],
            )
            .toList();
    final fillerCount =
        rows.length >= minVisibleRows ? 0 : minVisibleRows - rows.length;
    for (var index = 0; index < fillerCount; index++) {
      rows.add(<String>[
        '${rows.length + 1}',
        '',
        '',
        '',
        '',
        '',
      ]);
    }

    final mainTable = pw.TableHelper.fromTextArray(
      border: const pw.TableBorder(
        left: pw.BorderSide(color: PdfColors.blueGrey100),
        right: pw.BorderSide(color: PdfColors.blueGrey100),
        top: pw.BorderSide(color: PdfColors.blueGrey100),
        bottom: pw.BorderSide.none,
        horizontalInside: pw.BorderSide(color: PdfColors.blueGrey100),
        verticalInside: pw.BorderSide(color: PdfColors.blueGrey100),
      ),
      headers: const [
        'ITEM',
        'DESCRIPCIÓN',
        'MEDIDA',
        'CANT.',
        'C_UNITARIO',
        'C_TOTAL'
      ],
      data: rows,
      headerHeight: layout.headerHeight,
      cellHeight: layout.cellHeight,
      headerStyle: pw.TextStyle(
        fontSize: layout.headerFontSize,
        fontWeight: pw.FontWeight.bold,
      ),
      cellStyle: pw.TextStyle(
        fontSize: layout.cellFontSize,
        lineSpacing: 1.2,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey50),
      cellAlignments: {
        0: pw.Alignment.center,
        2: pw.Alignment.center,
        3: pw.Alignment.center,
        4: pw.Alignment.centerRight,
        5: pw.Alignment.centerRight,
      },
      columnWidths: {
        0: const pw.FixedColumnWidth(36),
        1: const pw.FlexColumnWidth(3.6),
        2: const pw.FixedColumnWidth(58),
        3: const pw.FixedColumnWidth(44),
        4: const pw.FixedColumnWidth(88),
        5: const pw.FixedColumnWidth(88),
      },
    );

    final totalRow = pw.Table(
      border: pw.TableBorder.all(color: PdfColors.blueGrey100),
      columnWidths: const {
        0: pw.FlexColumnWidth(),
        1: pw.FixedColumnWidth(88),
      },
      children: [
        pw.TableRow(
          children: [
            pw.Container(
              height: layout.cellHeight,
              alignment: pw.Alignment.center,
              padding: const pw.EdgeInsets.symmetric(horizontal: 6),
              child: pw.Text(
                'TOTAL',
                style: pw.TextStyle(
                  fontSize: layout.cellFontSize,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Container(
              height: layout.cellHeight,
              alignment: pw.Alignment.centerRight,
              padding: const pw.EdgeInsets.symmetric(horizontal: 6),
              child: pw.Text(
                PriceFormatter.formatCopWhole(total),
                style: pw.TextStyle(
                  fontSize: layout.cellFontSize,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        mainTable,
        totalRow,
      ],
    );
  }

  static _TableLayoutConfig _resolveTableLayout({
    required int detallesCount,
    required bool hasObservaciones,
    required int observacionesWords,
    required int maxDescripcionLength,
  }) {
    if (detallesCount <= 10) {
      if (!hasObservaciones) {
        return const _TableLayoutConfig(
          headerFontSize: 9.2,
          cellFontSize: 9.0,
          titleFontSize: 12,
          bodyTitleFontSize: 11.5,
          bodyFontSize: 11,
          institutionalFontSize: 9.3,
          paragraphFontSize: 10.5,
          observacionesFontSize: 9.8,
          headerHeight: 20,
          cellHeight: 26.0,
          headerLogoHeight: 56,
          headerTextTopSpacing: 8,
          headerBottomSpacing: 12,
          sectionSpacing: 9,
          observacionesTopSpacing: 9,
          observacionesPadding: 8,
          beforeFooterSpacing: 10,
          afterTableSpacing: 4,
          pageMarginTop: 24,
          pageMarginBottom: 18,
          maxDescripcionChars: 100,
        );
      }

      if (observacionesWords >= 90) {
        return const _TableLayoutConfig(
          headerFontSize: 8.5,
          cellFontSize: 8.0,
          titleFontSize: 11.7,
          bodyTitleFontSize: 11.2,
          bodyFontSize: 10.5,
          institutionalFontSize: 9.0,
          paragraphFontSize: 10.1,
          observacionesFontSize: 9.3,
          headerHeight: 19,
          cellHeight: 20.0,
          headerLogoHeight: 54,
          headerTextTopSpacing: 8,
          headerBottomSpacing: 11,
          sectionSpacing: 9,
          observacionesTopSpacing: 8,
          observacionesPadding: 8,
          beforeFooterSpacing: 8,
          afterTableSpacing: 2,
          pageMarginTop: 22,
          pageMarginBottom: 17,
          maxDescripcionChars: 90,
        );
      }

      if (observacionesWords >= 60) {
        return const _TableLayoutConfig(
          headerFontSize: 8.8,
          cellFontSize: 8.4,
          titleFontSize: 11.8,
          bodyTitleFontSize: 11.3,
          bodyFontSize: 10.7,
          institutionalFontSize: 9.1,
          paragraphFontSize: 10.2,
          observacionesFontSize: 9.4,
          headerHeight: 19.5,
          cellHeight: 22.0,
          headerLogoHeight: 55,
          headerTextTopSpacing: 8,
          headerBottomSpacing: 11,
          sectionSpacing: 9,
          observacionesTopSpacing: 8,
          observacionesPadding: 8,
          beforeFooterSpacing: 9,
          afterTableSpacing: 3,
          pageMarginTop: 23,
          pageMarginBottom: 17,
          maxDescripcionChars: 95,
        );
      }

      return const _TableLayoutConfig(
        headerFontSize: 9.0,
        cellFontSize: 8.7,
        titleFontSize: 12,
        bodyTitleFontSize: 11.5,
        bodyFontSize: 11,
        institutionalFontSize: 9.2,
        paragraphFontSize: 10.4,
        observacionesFontSize: 9.6,
        headerHeight: 20,
        cellHeight: 24.0,
        headerLogoHeight: 56,
        headerTextTopSpacing: 8,
        headerBottomSpacing: 12,
        sectionSpacing: 9,
        observacionesTopSpacing: 9,
        observacionesPadding: 8,
        beforeFooterSpacing: 10,
        afterTableSpacing: 4,
        pageMarginTop: 24,
        pageMarginBottom: 18,
        maxDescripcionChars: 100,
      );
    }

    if (detallesCount >= 20 || maxDescripcionLength > 120) {
      return const _TableLayoutConfig(
        headerFontSize: 8,
        cellFontSize: 7.4,
        titleFontSize: 11.4,
        bodyTitleFontSize: 11.0,
        bodyFontSize: 10.2,
        institutionalFontSize: 8.8,
        paragraphFontSize: 9.7,
        observacionesFontSize: 8.8,
        headerHeight: 18,
        cellHeight: 16,
        headerLogoHeight: 50,
        headerTextTopSpacing: 7,
        headerBottomSpacing: 10,
        sectionSpacing: 8,
        observacionesTopSpacing: 7,
        observacionesPadding: 7,
        beforeFooterSpacing: 6,
        afterTableSpacing: 0,
        pageMarginTop: 20,
        pageMarginBottom: 15,
        maxDescripcionChars: 72,
      );
    }

    if (hasObservaciones &&
        (detallesCount >= 10 || maxDescripcionLength > 90)) {
      return const _TableLayoutConfig(
        headerFontSize: 8.2,
        cellFontSize: 7.7,
        titleFontSize: 11.3,
        bodyTitleFontSize: 10.9,
        bodyFontSize: 10.1,
        institutionalFontSize: 8.8,
        paragraphFontSize: 9.8,
        observacionesFontSize: 8.8,
        headerHeight: 18,
        cellHeight: 15.8,
        headerLogoHeight: 50,
        headerTextTopSpacing: 7,
        headerBottomSpacing: 10,
        sectionSpacing: 8,
        observacionesTopSpacing: 6,
        observacionesPadding: 7,
        beforeFooterSpacing: 6,
        afterTableSpacing: 1,
        pageMarginTop: 20,
        pageMarginBottom: 15,
        maxDescripcionChars: 78,
      );
    }

    if (detallesCount >= 14 ||
        (detallesCount >= 12 && hasObservaciones) ||
        maxDescripcionLength > 95) {
      return const _TableLayoutConfig(
        headerFontSize: 8.5,
        cellFontSize: 8,
        titleFontSize: 11.7,
        bodyTitleFontSize: 11.2,
        bodyFontSize: 10.5,
        institutionalFontSize: 9.0,
        paragraphFontSize: 10.1,
        observacionesFontSize: 9.3,
        headerHeight: 19,
        cellHeight: 17,
        headerLogoHeight: 54,
        headerTextTopSpacing: 8,
        headerBottomSpacing: 11,
        sectionSpacing: 9,
        observacionesTopSpacing: 8,
        observacionesPadding: 8,
        beforeFooterSpacing: 8,
        afterTableSpacing: 2,
        pageMarginTop: 22,
        pageMarginBottom: 17,
        maxDescripcionChars: 84,
      );
    }

    if (detallesCount >= 10 || maxDescripcionLength > 80) {
      return const _TableLayoutConfig(
        headerFontSize: 9,
        cellFontSize: 8.8,
        titleFontSize: 12,
        bodyTitleFontSize: 11.5,
        bodyFontSize: 11,
        institutionalFontSize: 9.3,
        paragraphFontSize: 10.5,
        observacionesFontSize: 9.8,
        headerHeight: 20,
        cellHeight: 18.5,
        headerLogoHeight: 56,
        headerTextTopSpacing: 8,
        headerBottomSpacing: 12,
        sectionSpacing: 9,
        observacionesTopSpacing: 9,
        observacionesPadding: 8,
        beforeFooterSpacing: 10,
        afterTableSpacing: 4,
        pageMarginTop: 24,
        pageMarginBottom: 18,
        maxDescripcionChars: 95,
      );
    }

    if (detallesCount <= 5 && !hasObservaciones) {
      return const _TableLayoutConfig(
        headerFontSize: 9,
        cellFontSize: 8.8,
        titleFontSize: 12,
        bodyTitleFontSize: 11.5,
        bodyFontSize: 11,
        institutionalFontSize: 9.3,
        paragraphFontSize: 10.5,
        observacionesFontSize: 9.8,
        headerHeight: 20,
        cellHeight: 18.5,
        headerLogoHeight: 56,
        headerTextTopSpacing: 8,
        headerBottomSpacing: 12,
        sectionSpacing: 9,
        observacionesTopSpacing: 9,
        observacionesPadding: 8,
        beforeFooterSpacing: 10,
        afterTableSpacing: 6,
        pageMarginTop: 24,
        pageMarginBottom: 18,
        maxDescripcionChars: 100,
      );
    }

    return const _TableLayoutConfig(
      headerFontSize: 9,
      cellFontSize: 8.8,
      titleFontSize: 12,
      bodyTitleFontSize: 11.5,
      bodyFontSize: 11,
      institutionalFontSize: 9.3,
      paragraphFontSize: 10.5,
      observacionesFontSize: 9.8,
      headerHeight: 20,
      cellHeight: 18,
      headerLogoHeight: 56,
      headerTextTopSpacing: 8,
      headerBottomSpacing: 12,
      sectionSpacing: 9,
      observacionesTopSpacing: 10,
      observacionesPadding: 8,
      beforeFooterSpacing: 10,
      afterTableSpacing: 8,
      pageMarginTop: 24,
      pageMarginBottom: 18,
      maxDescripcionChars: 100,
    );
  }

  static pw.Widget _buildHeader(
    pw.MemoryImage? logo, {
    required _TableLayoutConfig layout,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        if (logo != null)
          pw.Align(
            alignment: pw.Alignment.centerLeft,
            child: pw.Image(
              logo,
              height: layout.headerLogoHeight,
              fit: pw.BoxFit.contain,
            ),
          ),
        pw.SizedBox(height: layout.headerTextTopSpacing),
        pw.Text(
          _pdfInstitutionalText,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            fontSize: layout.institutionalFontSize,
            fontWeight: pw.FontWeight.bold,
            lineSpacing: 1.17,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildSignatureBlock({
    required pw.MemoryImage? firmaImage,
    required String firmaNombre,
    required String firmaCargo,
    required String firmaEmpresa,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Cordialmente,',
          style: pw.TextStyle(fontSize: 11),
        ),
        pw.SizedBox(height: 8),
        if (firmaImage != null)
          pw.Image(firmaImage, height: 56, fit: pw.BoxFit.contain)
        else
          pw.Text(
            firmaNombre,
            style: pw.TextStyle(
              fontSize: 20,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
        pw.SizedBox(height: 4),
        pw.Text(
          firmaNombre,
          style: pw.TextStyle(
            fontSize: 10.5,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.Text(
          firmaCargo,
          style: pw.TextStyle(
            fontSize: 10.5,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.Text(
          firmaEmpresa,
          style: pw.TextStyle(
            fontSize: 10.5,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Divider(thickness: 2, color: PdfColors.black),
        pw.SizedBox(height: 6),
        pw.Text(
          _pdfFooterLineOne,
          textAlign: pw.TextAlign.center,
          style: const pw.TextStyle(fontSize: 10),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          _pdfFooterLineTwo,
          textAlign: pw.TextAlign.center,
          style: const pw.TextStyle(fontSize: 10),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          _pdfFooterLineThree,
          textAlign: pw.TextAlign.center,
          style: const pw.TextStyle(fontSize: 10),
        ),
      ],
    );
  }

  static pw.Widget _buildPdfListItem({
    required String text,
    required double fontSize,
    required _PdfMarkerType markerType,
    bool bold = false,
    PdfColor markerColor = PdfColors.black,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 18,
          height: 18,
          child: _buildPdfMarker(markerType, markerColor),
        ),
        pw.SizedBox(width: 3),
        pw.Expanded(
          child: pw.Text(
            text,
            style: pw.TextStyle(
              fontSize: fontSize,
              lineSpacing: 1.3,
              fontWeight: bold ? pw.FontWeight.bold : null,
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildPdfMarker(_PdfMarkerType type, PdfColor color) {
    final colorHex = _pdfColorHex(color);
    final svg = switch (type) {
      _PdfMarkerType.bolt =>
        '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path fill="$colorHex" d="M13 2 4 13h6l-1 9 9-12h-6z"/></svg>',
      _PdfMarkerType.check =>
        '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path fill="$colorHex" d="M9 16.2 4.8 12l-1.4 1.4L9 19 21 7l-1.4-1.4z"/></svg>',
    };
    return pw.SvgImage(svg: svg);
  }

  static String _pdfColorHex(PdfColor color) {
    final r = (color.red * 255).round().clamp(0, 255);
    final g = (color.green * 255).round().clamp(0, 255);
    final b = (color.blue * 255).round().clamp(0, 255);
    final rr = r.toRadixString(16).padLeft(2, '0');
    final gg = g.toRadixString(16).padLeft(2, '0');
    final bb = b.toRadixString(16).padLeft(2, '0');
    return '#$rr$gg$bb';
  }
}

enum _PdfMarkerType { bolt, check }

int _resolveTargetVisibleRows({required int detallesCount}) {
  return detallesCount > 10 ? detallesCount : 10;
}

String _trimObservacionesForPdf(String raw, {required int maxWords}) {
  final normalized = raw.trim();
  if (normalized.isEmpty) {
    return '';
  }
  final words = normalized
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();
  if (words.length <= maxWords) {
    return normalized;
  }
  return words.take(maxWords).join(' ');
}

int _countWords(String raw) {
  final normalized = raw.trim();
  if (normalized.isEmpty) {
    return 0;
  }
  return normalized
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .length;
}

class _TableLayoutConfig {
  const _TableLayoutConfig({
    required this.headerFontSize,
    required this.cellFontSize,
    required this.titleFontSize,
    required this.bodyTitleFontSize,
    required this.bodyFontSize,
    required this.institutionalFontSize,
    required this.paragraphFontSize,
    required this.observacionesFontSize,
    required this.headerHeight,
    required this.cellHeight,
    required this.headerLogoHeight,
    required this.headerTextTopSpacing,
    required this.headerBottomSpacing,
    required this.sectionSpacing,
    required this.observacionesTopSpacing,
    required this.observacionesPadding,
    required this.beforeFooterSpacing,
    required this.afterTableSpacing,
    required this.pageMarginTop,
    required this.pageMarginBottom,
    required this.maxDescripcionChars,
  });

  final double headerFontSize;
  final double cellFontSize;
  final double titleFontSize;
  final double bodyTitleFontSize;
  final double bodyFontSize;
  final double institutionalFontSize;
  final double paragraphFontSize;
  final double observacionesFontSize;
  final double headerHeight;
  final double cellHeight;
  final double headerLogoHeight;
  final double headerTextTopSpacing;
  final double headerBottomSpacing;
  final double sectionSpacing;
  final double observacionesTopSpacing;
  final double observacionesPadding;
  final double beforeFooterSpacing;
  final double afterTableSpacing;
  final double pageMarginTop;
  final double pageMarginBottom;
  final int maxDescripcionChars;
}

Future<pw.MemoryImage?> _loadAssetImage(String assetPath) async {
  try {
    final bytes = await rootBundle.load(assetPath);
    return pw.MemoryImage(bytes.buffer.asUint8List());
  } catch (_) {
    return null;
  }
}

Future<pw.MemoryImage?> _loadFirmaImage(String? rawPath) async {
  final normalized = _resolveFirmaPathForRender(rawPath?.trim() ?? '');
  if (normalized.isEmpty) {
    return null;
  }

  if (normalized.startsWith('assets/')) {
    return _loadAssetImage(normalized);
  }

  if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
    try {
      final uri = Uri.parse(normalized);
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return pw.MemoryImage(response.bodyBytes);
      }
    } catch (_) {
      return null;
    }
  }

  try {
    final file = File(normalized);
    if (await file.exists()) {
      return pw.MemoryImage(await file.readAsBytes());
    }
  } catch (_) {
    return null;
  }

  return null;
}

String _resolveFirmaPathForRender(String rawPath) {
  final normalized = rawPath.trim();
  if (normalized.isEmpty) {
    return '';
  }

  if (normalized.startsWith('assets/')) {
    return normalized;
  }

  final apiUri = Uri.tryParse(AppConfig.apiBaseUrl);
  if (apiUri == null) {
    return normalized;
  }

  final apiOrigin = Uri(
    scheme: apiUri.scheme,
    host: apiUri.host,
    port: apiUri.hasPort ? apiUri.port : null,
  );

  if (normalized.startsWith('/')) {
    return apiOrigin.resolve(normalized).toString();
  }

  final parsed = Uri.tryParse(normalized);
  if (parsed == null || !parsed.hasScheme) {
    return normalized;
  }

  if ((parsed.scheme == 'http' || parsed.scheme == 'https') &&
      _isLoopbackHost(parsed.host) &&
      !_isLoopbackHost(apiUri.host)) {
    return parsed
        .replace(
          scheme: apiUri.scheme,
          host: apiUri.host,
          port: apiUri.hasPort ? apiUri.port : null,
        )
        .toString();
  }

  return normalized;
}

bool _isLoopbackHost(String host) =>
    host == 'localhost' || host == '127.0.0.1' || host == '::1';

DateTime? _parseFecha(String? raw) {
  if (raw == null || raw.trim().isEmpty) {
    return null;
  }
  return DateTime.tryParse(raw);
}

String _fallbackText(String? value, {required String fallback}) {
  final normalized = value?.trim() ?? '';
  return normalized.isEmpty ? fallback : normalized;
}

String _formatCantidad(String raw) {
  final value = PriceFormatter.parse(raw);
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }

  return value.toStringAsFixed(2);
}

String _normalizeDescripcionForTable(String text, {required int maxLength}) {
  final collapsed = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (collapsed.length <= maxLength) {
    return collapsed;
  }

  return '${collapsed.substring(0, maxLength - 1)}…';
}

String _formatFechaLarga(DateTime date) {
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

  return '${date.day} de ${months[date.month - 1]} de ${date.year}';
}
