import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:printing/printing.dart';
import 'package:signature/signature.dart';

import '../../../core/config/app_config.dart';
import '../../../core/layout/adaptive_layout.dart';
import '../../../shared/utils/price_formatter.dart';
import '../../servicios/domain/servicio.dart';
import '../cotizaciones_controller.dart';
import '../domain/cotizacion.dart';
import 'cotizacion_pdf_service.dart';

const _institutionalText =
    'DISEÑO Y EJECUCIÓN DE PROYECTOS ELÉCTRICOS, EN NIVELES DE MEDIA Y BAJA TENSIÓN, MANTENIMIENTO Y CONSTRUCCIÓN DE SUBESTACIONES ELÉCTRICAS DE DISTRIBUCIÓN, MANTENIMIENTO E INSTALACIÓN DE SISTEMAS Y EQUIPOS ELÉCTRICOS, EN AMBIENTES INDUSTRIALES, DOMICILIARIO Y OFICINA, DISEÑO E IMPLEMENTACIÓN DE PLANES DE MITIGACIÓN EN RIESGO ELÉCTRICO, MANTENIMIENTO EN PODA DE VEGETACIÓN CON CONTACTO DIRECTO EN REDES ELECTRICAS PRIMARIAS Y SECUNDARIAS.';
const _introParagraphOne =
    'En atención a su solicitud, me permito presentar la cotización correspondiente al desarrollo del trabajo eléctrico requerido.';
const _introParagraphTwo =
    'El proyecto será entregado cumpliendo todos los requisitos técnicos y normativos, garantizando la seguridad, funcionalidad y legalidad de las instalaciones eléctricas.';
const _footerLineOne = 'Calle 13 Sur N°15 76 - Cel 3138260081';
const _footerLineTwo = 'E-mail proyeccioneselectricastesla@gmail.com';
const _footerLineThree = 'Villavicencio Meta.';
const _defaultFirmaNombre = 'María Alejandra Flórez Ocampo.';
const _defaultFirmaCargo = 'Representante.';
const _defaultFirmaEmpresa = 'Proyecciones eléctricas Tesla';
const _defaultAlcanceItems = <String>[
  'Tendido de redes de media y baja tensión.',
  'Instalación de una subestación tipo poste equipada con transformador de 112,5 kVA.',
  'Ejecución de actividades conforme a normatividad vigente, incluyendo RETIE y NTC 2050.',
];
const _minVisibleServiceRows = 10;
const _maxObservacionesWords = 140;
const _logoTeslaAsset = 'assets/images/logo_tesla.png';
const _marcaAguaTeslaAsset = 'assets/images/marca_agua_tesla.png';

class CotizacionFormScreen extends StatefulWidget {
  const CotizacionFormScreen({
    super.key,
    required this.controller,
    required this.onSubmit,
    this.initialCotizacion,
    this.canEditFirma = false,
    this.defaultFirmaPath,
    this.defaultFirmaNombre,
    this.defaultFirmaCargo,
    this.defaultFirmaEmpresa,
    this.onFirmaPredeterminadaActualizada,
  });

  final CotizacionesController controller;
  final Future<Cotizacion> Function(Map<String, dynamic> payload) onSubmit;
  final Cotizacion? initialCotizacion;
  final bool canEditFirma;
  final String? defaultFirmaPath;
  final String? defaultFirmaNombre;
  final String? defaultFirmaCargo;
  final String? defaultFirmaEmpresa;
  final void Function({
    String? firmaPath,
    required String firmaNombre,
    required String firmaCargo,
    required String firmaEmpresa,
  })? onFirmaPredeterminadaActualizada;

  @override
  State<CotizacionFormScreen> createState() => _CotizacionFormScreenState();
}

class CotizacionPreviewScreen extends StatefulWidget {
  const CotizacionPreviewScreen({
    super.key,
    required this.cotizacion,
  });

  final Cotizacion cotizacion;

  @override
  State<CotizacionPreviewScreen> createState() =>
      _CotizacionPreviewScreenState();
}

class _CotizacionPreviewScreenState extends State<CotizacionPreviewScreen> {
  bool _isExportingPdf = false;

  Future<Uint8List> _buildCotizacionPdfBytes() {
    return CotizacionPdfService.buildPdf(widget.cotizacion);
  }

  Future<void> _sharePdf() async {
    if (_isExportingPdf) {
      return;
    }

    setState(() => _isExportingPdf = true);
    try {
      final bytes = await _buildCotizacionPdfBytes();
      final fileName = CotizacionPdfService.buildFileName(widget.cotizacion);
      await Printing.sharePdf(
        bytes: bytes,
        filename: fileName,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('No fue posible compartir la cotización en PDF: $error'),
        ),
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
      final bytes = await _buildCotizacionPdfBytes();
      final fileName = CotizacionPdfService.buildFileName(widget.cotizacion);
      await Printing.layoutPdf(
        name: fileName,
        onLayout: (_) async => bytes,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No fue posible imprimir la cotización: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isExportingPdf = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cotizacion = widget.cotizacion;
    final date = _parseFecha(cotizacion.fecha) ?? DateTime.now();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = AdaptiveLayout.isDesktopWidth(constraints.maxWidth);
        return Scaffold(
          backgroundColor: _CotizacionFormScreenState._pageBackground,
          appBar: AppBar(
            backgroundColor: _CotizacionFormScreenState._pageBackground,
            foregroundColor: _CotizacionFormScreenState._ink900,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            title: Text(
              cotizacion.codigo.isEmpty
                  ? 'Ver cotización'
                  : 'Cotización ${cotizacion.codigo}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            actions: [
              IconButton(
                onPressed: _isExportingPdf ? null : _sharePdf,
                tooltip: 'Compartir PDF',
                icon: _isExportingPdf
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.2),
                      )
                    : const Icon(Icons.share_outlined),
              ),
              if (isDesktop)
                IconButton(
                  onPressed: _isExportingPdf ? null : _printPdf,
                  tooltip: 'Imprimir PDF',
                  icon: const Icon(Icons.print_outlined),
                ),
            ],
          ),
          body: SafeArea(
            top: false,
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                isDesktop ? 32 : 16,
                8,
                isDesktop ? 32 : 16,
                32,
              ),
              children: [
                if (isDesktop)
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1160),
                      child: Column(
                        children: [
                          _PreviewDocumentSheet(
                            cotizacion: cotizacion,
                            fecha: date,
                            isDesktop: isDesktop,
                          ),
                          const SizedBox(height: 22),
                          _PreviewSecondDocumentSheet(
                            cotizacion: cotizacion,
                            isDesktop: isDesktop,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Column(
                    children: [
                      _PreviewDocumentSheet(
                        cotizacion: cotizacion,
                        fecha: date,
                        isDesktop: isDesktop,
                      ),
                      const SizedBox(height: 16),
                      _PreviewSecondDocumentSheet(
                        cotizacion: cotizacion,
                        isDesktop: isDesktop,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CotizacionFormScreenState extends State<CotizacionFormScreen> {
  static const _pageBackground = Color(0xFFF1F5F9);
  static const _ink900 = Color(0xFF0F172A);
  static const _ink700 = Color(0xFF334155);
  static const _ink500 = Color(0xFF64748B);
  static const _line = Color(0xFFD7DEE8);
  static const _paperLine = Color(0xFFE5E7EB);
  static const _danger = Color(0xFFBE123C);

  late final TextEditingController _ciudadController;
  late final TextEditingController _clienteNombreController;
  late final TextEditingController _clienteNitController;
  late final TextEditingController _representanteController;
  late final TextEditingController _cargoController;
  late final TextEditingController _clienteCiudadController;
  late final TextEditingController _referenciaController;
  late final TextEditingController _observacionesController;
  late final TextEditingController _ofertaDiasTotalesController;
  late final TextEditingController _ofertaDiasEjecucionController;
  late final TextEditingController _ofertaDiasTramitologiaController;
  late final TextEditingController _ofertaPago1PctController;
  late final TextEditingController _ofertaPago2PctController;
  late final TextEditingController _ofertaPago3PctController;
  late final TextEditingController _ofertaGarantiaMesesController;
  late final TextEditingController _firmaPathController;
  late final TextEditingController _firmaNombreController;
  late final TextEditingController _firmaCargoController;
  late final TextEditingController _firmaEmpresaController;

  final List<_LineaCotizacionDraft> _lineas = [];
  final List<TextEditingController> _alcanceControllers = [];

  DateTime _fecha = DateTime.now();
  bool _isSaving = false;
  bool _isLoadingServicios = false;
  bool _isUploadingFirma = false;
  bool _usarFirmaPredeterminada = false;
  bool _isNormalizingObservaciones = false;
  String _lastValidObservacionesText = '';
  String? _error;
  String? _catalogoError;

  bool get _isEditing => widget.initialCotizacion != null;
  String get _screenTitle =>
      _isEditing ? 'Editar cotización' : 'Nueva cotización';
  String get _submitLabel =>
      _isEditing ? 'Guardar cambios' : 'Crear cotización';
  List<Servicio> get _servicios => widget.controller.state.catalogoServicios;
  bool get _canEditFirma => widget.canEditFirma;

  @override
  void initState() {
    super.initState();
    final cotizacion = widget.initialCotizacion;
    _fecha = _parseFecha(cotizacion?.fecha) ?? DateTime.now();
    _ciudadController = TextEditingController(text: cotizacion?.ciudad ?? '');
    _clienteNombreController =
        TextEditingController(text: cotizacion?.clienteNombre ?? '');
    _clienteNitController =
        TextEditingController(text: cotizacion?.clienteNit ?? '');
    _representanteController =
        TextEditingController(text: cotizacion?.clienteContacto ?? '');
    _cargoController =
        TextEditingController(text: cotizacion?.clienteCargo ?? '');
    _clienteCiudadController =
        TextEditingController(text: cotizacion?.clienteCiudad ?? '');
    _referenciaController =
        TextEditingController(text: cotizacion?.referencia ?? '');
    _observacionesController = TextEditingController(
      text: _truncateToWordLimit(
          cotizacion?.observaciones ?? '', _maxObservacionesWords),
    );
    _lastValidObservacionesText = _observacionesController.text;
    _observacionesController.addListener(_enforceObservacionesLimit);
    final alcanceInicial = cotizacion?.alcanceItems ?? const [];
    final alcanceFuente =
        alcanceInicial.isNotEmpty ? alcanceInicial : _defaultAlcanceItems;
    for (final item in alcanceFuente) {
      _alcanceControllers.add(TextEditingController(text: item));
    }
    _ofertaDiasTotalesController = TextEditingController(
      text: '${cotizacion?.ofertaDiasTotales ?? 30}',
    );
    _ofertaDiasEjecucionController = TextEditingController(
      text: '${cotizacion?.ofertaDiasEjecucion ?? 15}',
    );
    _ofertaDiasTramitologiaController = TextEditingController(
      text: '${cotizacion?.ofertaDiasTramitologia ?? 15}',
    );
    _ofertaPago1PctController = TextEditingController(
      text: cotizacion?.ofertaPago1Pct ?? '50',
    );
    _ofertaPago2PctController = TextEditingController(
      text: cotizacion?.ofertaPago2Pct ?? '25',
    );
    _ofertaPago3PctController = TextEditingController(
      text: cotizacion?.ofertaPago3Pct ?? '25',
    );
    _ofertaGarantiaMesesController = TextEditingController(
      text: '${cotizacion?.ofertaGarantiaMeses ?? 6}',
    );
    _firmaPathController = TextEditingController(
      text: cotizacion?.firmaPath ?? widget.defaultFirmaPath ?? '',
    );
    _firmaNombreController = TextEditingController(
      text: cotizacion?.firmaNombre ??
          widget.defaultFirmaNombre ??
          _defaultFirmaNombre,
    );
    _firmaCargoController = TextEditingController(
      text: cotizacion?.firmaCargo ??
          widget.defaultFirmaCargo ??
          _defaultFirmaCargo,
    );
    _firmaEmpresaController = TextEditingController(
      text: cotizacion?.firmaEmpresa ??
          widget.defaultFirmaEmpresa ??
          _defaultFirmaEmpresa,
    );

    if (cotizacion != null && cotizacion.detalles.isNotEmpty) {
      for (final detalle in cotizacion.detalles) {
        _lineas.add(_LineaCotizacionDraft.fromDetalle(detalle));
      }
    } else {
      _lineas.add(_LineaCotizacionDraft.empty(item: 1));
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(_loadServicios());
    });
  }

  @override
  void dispose() {
    _ciudadController.dispose();
    _clienteNombreController.dispose();
    _clienteNitController.dispose();
    _representanteController.dispose();
    _cargoController.dispose();
    _clienteCiudadController.dispose();
    _referenciaController.dispose();
    _observacionesController.removeListener(_enforceObservacionesLimit);
    _observacionesController.dispose();
    _ofertaDiasTotalesController.dispose();
    _ofertaDiasEjecucionController.dispose();
    _ofertaDiasTramitologiaController.dispose();
    _ofertaPago1PctController.dispose();
    _ofertaPago2PctController.dispose();
    _ofertaPago3PctController.dispose();
    _ofertaGarantiaMesesController.dispose();
    _firmaPathController.dispose();
    _firmaNombreController.dispose();
    _firmaCargoController.dispose();
    _firmaEmpresaController.dispose();
    for (final alcanceController in _alcanceControllers) {
      alcanceController.dispose();
    }
    for (final linea in _lineas) {
      linea.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = AdaptiveLayout.isDesktopWidth(constraints.maxWidth);
        return Scaffold(
          backgroundColor: _pageBackground,
          appBar: AppBar(
            backgroundColor: _pageBackground,
            foregroundColor: _ink900,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            title: Text(
              _screenTitle,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          body: SafeArea(
            top: false,
            child: isDesktop
                ? ListView(
                    padding: const EdgeInsets.fromLTRB(32, 8, 32, 160),
                    children: [
                      _buildTopSummary(true),
                      const SizedBox(height: 18),
                      _buildSheetViewport(
                        isDesktop: true,
                        child: _buildDocumentSheet(true),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        _buildErrorBanner(_error!),
                      ],
                    ],
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 160),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildTopSummary(false),
                        const SizedBox(height: 18),
                        _buildMobileDocumentSheet(),
                        if (_error != null) ...[
                          const SizedBox(height: 16),
                          _buildErrorBanner(_error!),
                        ],
                      ],
                    ),
                  ),
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                isDesktop ? 32 : 16,
                12,
                isDesktop ? 32 : 16,
                16,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                border: const Border(top: BorderSide(color: _line)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x120F172A),
                    blurRadius: 20,
                    offset: Offset(0, -8),
                  ),
                ],
              ),
              child: isDesktop
                  ? Row(
                      children: [
                        Expanded(child: _buildBottomMeta()),
                        const SizedBox(width: 18),
                        _buildBottomActions(compact: false),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildBottomMeta(),
                        const SizedBox(height: 12),
                        _buildBottomActions(compact: true),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopSummary(bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF111827), Color(0xFF14532D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x220F172A),
            blurRadius: 26,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: isDesktop
          ? Row(
              children: [
                Expanded(child: _buildTopSummaryText()),
                const SizedBox(width: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildMetricCard('Servicios', '${_lineas.length}'),
                    _buildMetricCard(
                      'Total',
                      PriceFormatter.formatCopLatino(_totalGeneral),
                    ),
                  ],
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopSummaryText(),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildMetricCard('Servicios', '${_lineas.length}'),
                    _buildMetricCard(
                      'Total',
                      PriceFormatter.formatCopLatino(_totalGeneral),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildTopSummaryText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: Text(
            _isEditing
                ? 'Edición estructurada'
                : 'Fase 2 · Editor estructurado',
            style: const TextStyle(
              color: Color(0xFFE2E8F0),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          _screenTitle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'La pantalla replica la primera hoja de la cotización real como un documento editable, integrando servicios y cálculo automático por filas.',
          style: TextStyle(color: Color(0xFFE2E8F0), height: 1.45),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value) {
    return Container(
      width: 170,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentSheet(bool isDesktop) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1160),
        child: Column(
          children: [
            _buildFirstDocumentPage(isDesktop),
            const SizedBox(height: 22),
            _buildSecondDocumentPage(isDesktop),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileDocumentSheet() {
    return Column(
      children: [
        _buildFirstDocumentPage(false),
        const SizedBox(height: 16),
        _buildSecondDocumentPage(false),
      ],
    );
  }

  Widget _buildFirstDocumentPage(bool isDesktop) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isDesktop ? 32 : 24),
        border: Border.all(color: _line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              isDesktop ? 40 : 18,
              isDesktop ? 30 : 18,
              isDesktop ? 40 : 18,
              isDesktop ? 34 : 22,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildDocumentHeader(),
                const SizedBox(height: 24),
                _buildCityDateSection(isDesktop),
                const SizedBox(height: 18),
                _buildClientSection(isDesktop),
                const SizedBox(height: 18),
                _buildReferenceSection(),
                const SizedBox(height: 18),
                _buildIntroSection(),
                const SizedBox(height: 18),
                _buildDescriptiveTableSection(),
                const SizedBox(height: 20),
                _buildObservacionesSection(),
                const SizedBox(height: 26),
                const Divider(color: _ink900, thickness: 4),
                const SizedBox(height: 14),
                _buildFooter(),
              ],
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: ColorFiltered(
                  colorFilter: const ColorFilter.matrix([
                    1.25,
                    -0.12,
                    -0.12,
                    0,
                    0,
                    -0.12,
                    1.25,
                    -0.12,
                    0,
                    0,
                    -0.12,
                    -0.12,
                    1.25,
                    0,
                    0,
                    0,
                    0,
                    0,
                    1,
                    0,
                  ]),
                  child: Opacity(
                    opacity: 0.21,
                    child: FractionallySizedBox(
                      widthFactor: 0.40,
                      heightFactor: 0.58,
                      child: Image.asset(
                        _marcaAguaTeslaAsset,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSheetViewport({
    required bool isDesktop,
    required Widget child,
  }) {
    return child;
  }

  Widget _buildDocumentHeader() {
    final isDesktop = AdaptiveLayout.isDesktopContext(context);

    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Image(
            image: AssetImage(_logoTeslaAsset),
            height: isDesktop ? 70 : 56,
            fit: BoxFit.contain,
          ),
        ),
        SizedBox(height: isDesktop ? 18 : 14),
        Text(
          _institutionalText,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _ink900,
            fontSize: isDesktop ? 14 : 12,
            fontWeight: FontWeight.w700,
            height: 1.25,
          ),
        ),
      ],
    );
  }

  Widget _buildCityDateSection(bool isDesktop) {
    final dateLabel = _formatFechaLarga(_fecha);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_ciudadController.text.trim().isEmpty ? 'Ciudad pendiente' : _ciudadController.text.trim()}, $dateLabel.',
          style: const TextStyle(
            color: _ink900,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        isDesktop
            ? Row(
                children: [
                  Expanded(
                    child: _DocumentInput(
                      label: 'Ciudad',
                      controller: _ciudadController,
                      hintText: 'Villavicencio-Meta',
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DateInput(
                      label: 'Fecha',
                      value: dateLabel,
                      onTap: _pickFecha,
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  _DocumentInput(
                    label: 'Ciudad',
                    controller: _ciudadController,
                    hintText: 'Villavicencio-Meta',
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  _DateInput(
                    label: 'Fecha',
                    value: dateLabel,
                    onTap: _pickFecha,
                  ),
                ],
              ),
      ],
    );
  }

  Widget _buildClientSection(bool isDesktop) {
    final editorFields = [
      SizedBox(
        width: isDesktop ? 320 : null,
        child: _DocumentInput(
          label: 'Cliente',
          controller: _clienteNombreController,
          hintText: 'Nombre o razón social',
          onChanged: (_) => setState(() {}),
        ),
      ),
      SizedBox(
        width: isDesktop ? 220 : null,
        child: _DocumentInput(
          label: 'NIT',
          controller: _clienteNitController,
          hintText: '90158014-1',
          onChanged: (_) => setState(() {}),
        ),
      ),
      SizedBox(
        width: isDesktop ? 320 : null,
        child: _DocumentInput(
          label: 'Representante',
          controller: _representanteController,
          hintText: 'Nombre del representante',
          onChanged: (_) => setState(() {}),
        ),
      ),
      SizedBox(
        width: isDesktop ? 220 : null,
        child: _DocumentInput(
          label: 'Cargo',
          controller: _cargoController,
          hintText: 'Representante legal',
          onChanged: (_) => setState(() {}),
        ),
      ),
      SizedBox(
        width: isDesktop ? 220 : null,
        child: _DocumentInput(
          label: 'Ciudad',
          controller: _clienteCiudadController,
          hintText: 'Villavicencio',
          onChanged: (_) => setState(() {}),
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Señores:',
          style: TextStyle(
            color: _ink900,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          (_clienteNombreController.text.trim().isEmpty
                  ? 'CLIENTE PENDIENTE'
                  : _clienteNombreController.text.trim())
              .toUpperCase(),
          style: const TextStyle(
            color: _ink900,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'NIT: ${_clienteNitController.text.trim().isEmpty ? 'PENDIENTE' : _clienteNitController.text.trim()}',
          style: const TextStyle(
            color: _ink900,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          (_representanteController.text.trim().isEmpty
                  ? 'Representante pendiente'
                  : _representanteController.text.trim())
              .toUpperCase(),
          style: const TextStyle(
            color: _ink900,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          _cargoController.text.trim().isEmpty
              ? 'Cargo pendiente'
              : _cargoController.text.trim(),
          style: const TextStyle(
            color: _ink900,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          _clienteCiudadController.text.trim().isEmpty
              ? 'Ciudad pendiente'
              : _clienteCiudadController.text.trim(),
          style: const TextStyle(
            color: _ink900,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        if (isDesktop)
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: editorFields,
          )
        else
          Column(
            children: [
              for (var i = 0; i < editorFields.length; i++) ...[
                editorFields[i],
                if (i < editorFields.length - 1) const SizedBox(height: 12),
              ],
            ],
          ),
      ],
    );
  }

  Widget _buildReferenceSection() {
    final reference = _referenciaController.text.trim().isEmpty
        ? 'REFERENCIA PENDIENTE'
        : _referenciaController.text.trim().toUpperCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ref. COTIZACIÓN, $reference.',
          style: const TextStyle(
            color: _ink900,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        _DocumentInput(
          label: 'Referencia de cotización',
          controller: _referenciaController,
          hintText: 'TENDIDO DE REDES DE MEDIA Y BAJA TENSIÓN',
          textCapitalization: TextCapitalization.characters,
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildIntroSection() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _introParagraphOne,
          style: TextStyle(
            color: _ink900,
            fontSize: 16,
            height: 1.45,
          ),
        ),
        SizedBox(height: 14),
        Text(
          _introParagraphTwo,
          style: TextStyle(
            color: _ink900,
            fontSize: 16,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptiveTableSection() {
    final isDesktop = AdaptiveLayout.isDesktopContext(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cuadro descriptivo:',
          style: TextStyle(
            color: _ink900,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        if (_isLoadingServicios) ...[
          const LinearProgressIndicator(minHeight: 3),
          const SizedBox(height: 10),
          if (_servicios.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _paperLine),
              ),
              child: const Text(
                'Cargando servicios para habilitar el autocompletado del cuadro descriptivo...',
                style: TextStyle(
                  color: _ink700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (_servicios.isEmpty) const SizedBox(height: 10),
        ],
        if (_catalogoError != null) ...[
          _buildErrorBanner(_catalogoError!),
          const SizedBox(height: 10),
        ],
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: _paperLine),
            borderRadius: BorderRadius.circular(22),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: _editableTableMinWidth(isDesktop),
              ),
              child: Column(
                children: [
                  _buildTableHeaderRow(),
                  for (var index = 0; index < _lineas.length; index++)
                    _buildEditableLineRow(_lineas[index], index),
                  _buildTotalRow(),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FilledButton.icon(
              onPressed: _isSaving ? null : _agregarLinea,
              style: FilledButton.styleFrom(
                backgroundColor: _ink900,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Agregar fila',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(
              width: 420,
              child: Text(
                'Selecciona un servicio y escribe solo la cantidad. El total se calcula automáticamente.',
                style: TextStyle(
                  color: _ink500,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTableHeaderRow() {
    final isDesktop = AdaptiveLayout.isDesktopContext(context);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(bottom: BorderSide(color: _paperLine)),
      ),
      child: Row(
        children: [
          _TableHeaderCell(width: _editableItemWidth(isDesktop), label: 'ITEM'),
          _TableHeaderCell(
            width: _editableDescripcionWidth(isDesktop),
            label: 'DESCRIPCIÓN',
          ),
          _TableHeaderCell(
            width: _editableUnidadWidth(isDesktop),
            label: 'UNIDAD',
          ),
          _TableHeaderCell(
            width: _editableCantidadWidth(isDesktop),
            label: 'CANT.',
          ),
          _TableHeaderCell(
            width: _editableValorWidth(isDesktop),
            label: 'VALOR UNITARIO',
          ),
          _TableHeaderCell(
            width: _editableTotalWidth(isDesktop),
            label: 'TOTAL',
          ),
          _TableHeaderCell(
            width: _editableAccionWidth(isDesktop),
            label: 'ACC.',
          ),
        ],
      ),
    );
  }

  Widget _buildEditableLineRow(_LineaCotizacionDraft linea, int index) {
    final isDesktop = AdaptiveLayout.isDesktopContext(context);

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _paperLine)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TableValueCell(
            width: _editableItemWidth(isDesktop),
            alignment: Alignment.centerRight,
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: _ink900,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _TableValueCell(
            width: _editableDescripcionWidth(isDesktop),
            child: _ServicioPickerField(
              enabled: !_isSaving &&
                  (_servicios.isNotEmpty || _catalogoError != null),
              selectedLabel: linea.descripcion,
              servicios: _servicios,
              catalogoError: _catalogoError,
              onSelected: (servicio) {
                setState(() {
                  linea.applyServicio(servicio);
                });
              },
            ),
          ),
          _TableValueCell(
            width: _editableUnidadWidth(isDesktop),
            child: Text(
              linea.unidad.isEmpty ? '-' : linea.unidad,
              style: TextStyle(
                color: linea.unidad.isEmpty ? _ink500 : _ink900,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _TableValueCell(
            width: _editableCantidadWidth(isDesktop),
            child: TextField(
              controller: linea.cantidadController,
              enabled: !_isSaving,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: '0',
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          _TableValueCell(
            width: _editableValorWidth(isDesktop),
            alignment: Alignment.centerRight,
            child: Text(
              PriceFormatter.formatCopLatino(linea.precioUnitario),
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: _ink900,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _TableValueCell(
            width: _editableTotalWidth(isDesktop),
            alignment: Alignment.centerRight,
            child: Text(
              PriceFormatter.formatCopLatino(linea.total),
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: _ink900,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          _TableValueCell(
            width: _editableAccionWidth(isDesktop),
            child: Center(
              child: IconButton(
                onPressed: _isSaving ? null : () => _eliminarLinea(index),
                tooltip: 'Eliminar fila',
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow() {
    final isDesktop = AdaptiveLayout.isDesktopContext(context);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
      ),
      child: Row(
        children: [
          SizedBox(
            width: _editableTotalLabelWidth(isDesktop),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Text(
                'TOTAL GENERAL',
                style: TextStyle(
                  color: _ink900,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          SizedBox(
            width: _editableTotalValueWidth(isDesktop),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Text(
                PriceFormatter.formatCopLatino(_totalGeneral),
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: _ink900,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildObservacionesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Observaciones',
          style: TextStyle(
            color: _ink900,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _observacionesController,
          enabled: !_isSaving,
          maxLines: 5,
          minLines: 4,
          onChanged: _handleObservacionesChanged,
          decoration: InputDecoration(
            hintText: 'Agrega observaciones adicionales de la cotización.',
            helperText:
                'Máximo $_maxObservacionesWords palabras (${_countWords(_observacionesController.text)}/$_maxObservacionesWords).',
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: _paperLine),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: _paperLine),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: _ink900),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return const Column(
      children: [
        Text(
          _footerLineOne,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _ink900,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2),
        Text(
          _footerLineTwo,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _ink900,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2),
        Text(
          _footerLineThree,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _ink900,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSecondDocumentPage(bool isDesktop) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isDesktop ? 32 : 24),
        border: Border.all(color: _line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: ColorFiltered(
                  colorFilter: const ColorFilter.matrix([
                    1.25,
                    -0.12,
                    -0.12,
                    0,
                    0,
                    -0.12,
                    1.25,
                    -0.12,
                    0,
                    0,
                    -0.12,
                    -0.12,
                    1.25,
                    0,
                    0,
                    0,
                    0,
                    0,
                    1,
                    0,
                  ]),
                  child: Opacity(
                    opacity: 0.21,
                    child: FractionallySizedBox(
                      widthFactor: 0.40,
                      heightFactor: 0.58,
                      child: Image.asset(
                        _marcaAguaTeslaAsset,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              isDesktop ? 40 : 18,
              isDesktop ? 30 : 18,
              isDesktop ? 40 : 18,
              isDesktop ? 34 : 22,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildDocumentHeader(),
                const SizedBox(height: 24),
                _buildAlcanceSection(isDesktop),
                const SizedBox(height: 22),
                _buildCondicionesSection(isDesktop),
                const SizedBox(height: 22),
                _buildFirmaSection(isDesktop),
                const SizedBox(height: 26),
                const Divider(color: _ink900, thickness: 4),
                const SizedBox(height: 14),
                _buildFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlcanceSection(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'EL ALCANCE DEL PROYECTO INCLUYE:',
          style: TextStyle(
            color: _ink900,
            fontSize: 17,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < _alcanceControllers.length; i++) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.bolt_rounded,
                  size: 20,
                  color: Color(0xFF1D4ED8),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _alcanceControllers[i],
                  enabled: !_isSaving,
                  maxLines: null,
                  style: const TextStyle(
                    color: _ink900,
                    fontSize: 16,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              if (!_isSaving)
                IconButton(
                  tooltip: 'Eliminar línea',
                  onPressed: () => _removeAlcanceLine(i),
                  icon: const Icon(Icons.close_rounded, size: 18),
                ),
            ],
          ),
          if (i < _alcanceControllers.length - 1) const SizedBox(height: 4),
        ],
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _isSaving ? null : _addAlcanceLine,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Agregar línea de alcance'),
        ),
      ],
    );
  }

  Widget _buildCondicionesSection(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CONDICIONES DE LA OFERTA:',
          style: TextStyle(
            color: _ink900,
            fontSize: 17,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _smallNumberEditor(
              label: 'Días totales',
              controller: _ofertaDiasTotalesController,
              suffix: 'd',
              isDesktop: isDesktop,
            ),
            _smallNumberEditor(
              label: 'Días ejecución',
              controller: _ofertaDiasEjecucionController,
              suffix: 'd',
              isDesktop: isDesktop,
            ),
            _smallNumberEditor(
              label: 'Días tramitología',
              controller: _ofertaDiasTramitologiaController,
              suffix: 'd',
              isDesktop: isDesktop,
            ),
            _smallNumberEditor(
              label: 'Pago 1',
              controller: _ofertaPago1PctController,
              suffix: '%',
              isDesktop: isDesktop,
            ),
            _smallNumberEditor(
              label: 'Pago 2',
              controller: _ofertaPago2PctController,
              suffix: '%',
              isDesktop: isDesktop,
            ),
            _smallNumberEditor(
              label: 'Pago 3',
              controller: _ofertaPago3PctController,
              suffix: '%',
              isDesktop: isDesktop,
            ),
            _smallNumberEditor(
              label: 'Garantía',
              controller: _ofertaGarantiaMesesController,
              suffix: 'meses',
              isDesktop: isDesktop,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.only(left: 52, right: 44),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    color: _ink900,
                    fontSize: 16,
                    height: 1.45,
                    fontWeight: FontWeight.w400,
                  ),
                  children: [
                    const TextSpan(
                      text: 'Tiempo de entrega:',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    TextSpan(
                      text:
                          ' El tiempo estimado para la ejecución del proyecto es de (${_intValue(_ofertaDiasTotalesController, 30)}) días calendario, salvo condiciones especiales que impidan el desarrollo normal de las actividades programadas. La distribución del tiempo de trabajo es la siguiente:',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 1),
                    child: Text(
                      '✓',
                      style: TextStyle(
                        color: _ink900,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '(${_intValue(_ofertaDiasEjecucionController, 15)}) días de ejecución, a partir de este momento los predios podrán conectarse a la red de baja tensión, siempre y cuando cuenten con la acometida, caja para la instalación de medidor, caja de protecciones e instalación interna.',
                      style: const TextStyle(
                        color: _ink900,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 1),
                    child: Text(
                      '✓',
                      style: TextStyle(
                        color: _ink900,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '(${_intValue(_ofertaDiasTramitologiaController, 15)}) días tramitología ante EMSA.',
                      style: const TextStyle(
                        color: _ink900,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.bolt_rounded,
                      size: 20,
                      color: Color(0xFF1D4ED8),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Forma de pago:',
                      style: TextStyle(
                        color: _ink900,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'La forma de pago para el desarrollo del proyecto se establece de la siguiente manera:',
                style: TextStyle(
                  color: _ink900,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 26),
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      color: _ink900,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      height: 1.45,
                    ),
                    children: [
                      const TextSpan(
                        text: 'Pago 1:',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      TextSpan(
                        text:
                            ' Correspondiente al ${_pctValue(_ofertaPago1PctController, '50')}% del valor total del contrato, contra entrega de la orden de servicio.',
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 26),
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      color: _ink900,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      height: 1.45,
                    ),
                    children: [
                      const TextSpan(
                        text: 'Pago 2:',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      TextSpan(
                        text:
                            ' Correspondiente al ${_pctValue(_ofertaPago2PctController, '25')}% del valor total, una vez se energice el transformador y la red de baja tensión.',
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 26),
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      color: _ink900,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      height: 1.45,
                    ),
                    children: [
                      const TextSpan(
                        text: 'Pago 3:',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      TextSpan(
                        text:
                            ' Correspondiente al ${_pctValue(_ofertaPago3PctController, '25')}% restante, último pago parcial, a realizar una vez se instalen los medidores en los predios legalizados.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.bolt_rounded,
                      size: 20,
                      color: Color(0xFF1D4ED8),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Garantía: ${_intValue(_ofertaGarantiaMesesController, 6)} meses, bajo condiciones eléctricas normales.',
                      style: const TextStyle(
                        color: _ink900,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFirmaSection(bool isDesktop) {
    final firmaPath = _firmaPathController.text.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cordialmente,',
          style: TextStyle(
            color: _ink900,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 14),
        if (_canEditFirma) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: (_isSaving || _isUploadingFirma)
                    ? null
                    : _pickAndUploadFirma,
                icon: _isUploadingFirma
                    ? const SizedBox(
                        height: 14,
                        width: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload_file_rounded),
                label: const Text('Subir firma (PNG/JPG)'),
              ),
              OutlinedButton.icon(
                onPressed: (_isSaving || _isUploadingFirma)
                    ? null
                    : _drawAndUploadFirma,
                icon: const Icon(Icons.gesture_rounded),
                label: const Text('Dibujar firma'),
              ),
              TextButton.icon(
                onPressed: _isSaving
                    ? null
                    : () {
                        setState(() {
                          _firmaPathController.clear();
                        });
                      },
                icon: const Icon(Icons.draw_rounded),
                label: const Text('Usar firma virtual'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SizedBox(
                width: isDesktop ? 440 : double.infinity,
                child: _DocumentInput(
                  label: 'Firma digital (URL o asset path)',
                  controller: _firmaPathController,
                  hintText: 'https://.../firma.png',
                  onChanged: (_) => setState(() {}),
                ),
              ),
              SizedBox(
                width: isDesktop ? 280 : double.infinity,
                child: _DocumentInput(
                  label: 'Nombre firma',
                  controller: _firmaNombreController,
                  hintText: _defaultFirmaNombre,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              SizedBox(
                width: isDesktop ? 220 : double.infinity,
                child: _DocumentInput(
                  label: 'Cargo',
                  controller: _firmaCargoController,
                  hintText: _defaultFirmaCargo,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              SizedBox(
                width: isDesktop ? 300 : double.infinity,
                child: _DocumentInput(
                  label: 'Empresa',
                  controller: _firmaEmpresaController,
                  hintText: _defaultFirmaEmpresa,
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'La administradora puede cambiar esta firma para la cotización actual. Queda lista la base para futura firma predeterminada.',
            style: TextStyle(color: _ink500, height: 1.35),
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            value: _usarFirmaPredeterminada,
            contentPadding: EdgeInsets.zero,
            dense: true,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text(
              'Colocar firma predeterminada para nuevas cotizaciones',
              style: TextStyle(
                color: _ink900,
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: const Text(
              'No modifica automáticamente cotizaciones viejas ya compartidas.',
              style: TextStyle(color: _ink500),
            ),
            onChanged: _isSaving
                ? null
                : (value) =>
                    setState(() => _usarFirmaPredeterminada = value ?? false),
          ),
          const SizedBox(height: 14),
        ],
        _buildFirmaGraphic(firmaPath),
        const SizedBox(height: 8),
        Text(
          _firmaNombreController.text.trim().isEmpty
              ? _defaultFirmaNombre
              : _firmaNombreController.text.trim(),
          style: const TextStyle(
            color: _ink900,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          _firmaCargoController.text.trim().isEmpty
              ? _defaultFirmaCargo
              : _firmaCargoController.text.trim(),
          style: const TextStyle(
            color: _ink900,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          _firmaEmpresaController.text.trim().isEmpty
              ? _defaultFirmaEmpresa
              : _firmaEmpresaController.text.trim(),
          style: const TextStyle(
            color: _ink900,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildFirmaGraphic(String firmaPath) {
    final resolvedFirmaPath = _resolveFirmaPathForRender(firmaPath);

    if (firmaPath.isEmpty) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text(
          _firmaNombreController.text.trim().isEmpty
              ? _defaultFirmaNombre
              : _firmaNombreController.text.trim(),
          style: const TextStyle(
            color: _ink700,
            fontSize: 36,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    if (resolvedFirmaPath.startsWith('http://') ||
        resolvedFirmaPath.startsWith('https://')) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Image.network(
          resolvedFirmaPath,
          height: 76,
          alignment: Alignment.centerLeft,
          fit: BoxFit.fitHeight,
          errorBuilder: (_, __, ___) => const Text(
            'No fue posible cargar la imagen de firma.',
            style: TextStyle(color: _danger, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    if (resolvedFirmaPath.startsWith('assets/')) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Image.asset(
          resolvedFirmaPath,
          height: 76,
          alignment: Alignment.centerLeft,
          fit: BoxFit.fitHeight,
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        resolvedFirmaPath,
        style: const TextStyle(
          color: _ink700,
          fontSize: 14,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _smallNumberEditor({
    required String label,
    required TextEditingController controller,
    required String suffix,
    required bool isDesktop,
  }) {
    return SizedBox(
      width: isDesktop ? 160 : 150,
      child: TextField(
        controller: controller,
        enabled: !_isSaving,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          suffixText: suffix,
          isDense: true,
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _paperLine),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _paperLine),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _ink900),
          ),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildBottomMeta() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${_lineas.length} filas · ${PriceFormatter.formatCopLatino(_totalGeneral)}',
          style: const TextStyle(
            color: _ink900,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _isEditing
              ? 'Puedes actualizar la hoja 1 y la hoja 2 sin tocar el flujo de cálculo.'
              : 'La pantalla guarda dos hojas de cotización con plantilla documental editable.',
          style: const TextStyle(
            color: _ink500,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions({required bool compact}) {
    final buttons = [
      Expanded(
        child: OutlinedButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).maybePop(),
          style: OutlinedButton.styleFrom(
            foregroundColor: _ink700,
            side: const BorderSide(color: _line),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: const Text(
            'Cancelar',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: FilledButton(
          onPressed: _isSaving ? null : _guardar,
          style: FilledButton.styleFrom(
            backgroundColor: _ink900,
            foregroundColor: Colors.white,
            disabledBackgroundColor: _line,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: _isSaving
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  _submitLabel,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
        ),
      ),
    ];

    return compact
        ? Row(children: buttons)
        : SizedBox(width: 340, child: Row(children: buttons));
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFDA4AF)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: _danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: _danger,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadServicios() async {
    if (!mounted || _isLoadingServicios) {
      return;
    }

    setState(() {
      _isLoadingServicios = true;
      _catalogoError = null;
    });

    try {
      await widget.controller.ensureCatalogoServiciosLoaded(
        notifyListeners: false,
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingServicios = false;
        for (final linea in _lineas) {
          final servicioId = linea.servicioId;
          if (servicioId == null) {
            continue;
          }

          Servicio? match;
          for (final servicio in _servicios) {
            if (servicio.id == servicioId) {
              match = servicio;
              break;
            }
          }
          if (match != null) {
            linea.applyServicio(match, preserveCantidad: true);
          }
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingServicios = false;
        _catalogoError =
            'No fue posible cargar los servicios para el autocompletado. Puedes reintentar cerrando y abriendo la pantalla.';
      });
    }
  }

  Future<void> _pickFecha() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _fecha = selected;
    });
  }

  void _agregarLinea() {
    setState(() {
      _lineas.add(_LineaCotizacionDraft.empty(item: _lineas.length + 1));
    });
  }

  void _addAlcanceLine() {
    setState(() {
      _alcanceControllers.add(TextEditingController());
    });
  }

  void _removeAlcanceLine(int index) {
    if (_alcanceControllers.length == 1) {
      _alcanceControllers.first.clear();
      setState(() {});
      return;
    }

    final removed = _alcanceControllers.removeAt(index);
    removed.dispose();
    setState(() {});
  }

  Future<void> _pickAndUploadFirma() async {
    String? selectedPath;
    final fileResult = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg'],
      allowMultiple: false,
      withData: false,
    );

    if (fileResult != null &&
        fileResult.files.isNotEmpty &&
        fileResult.files.first.path != null) {
      selectedPath = fileResult.files.first.path!;
    } else {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 95,
      );
      if (picked != null) {
        selectedPath = picked.path;
      }
    }

    if (selectedPath == null || !mounted) {
      return;
    }

    await _uploadFirmaFromPath(selectedPath);
  }

  Future<void> _drawAndUploadFirma() async {
    final bytes = await showDialog<Uint8List>(
      context: context,
      builder: (_) => const _FirmaCanvasDialog(),
    );
    if (bytes == null || !mounted) {
      return;
    }

    final signatureBytes = _trimTransparentPng(bytes) ?? bytes;
    final file = File(
      '${Directory.systemTemp.path}/firma_draw_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(signatureBytes, flush: true);

    if (!mounted) {
      return;
    }

    await _uploadFirmaFromPath(file.path);
  }

  Future<void> _uploadFirmaFromPath(String path) async {
    setState(() {
      _isUploadingFirma = true;
    });

    try {
      final uploadedPath = await widget.controller.repository.uploadFirma(
        path,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _firmaPathController.text = uploadedPath;
        _isUploadingFirma = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isUploadingFirma = false;
        _error = 'No fue posible cargar la firma. $error';
      });
    }
  }

  void _eliminarLinea(int index) {
    if (_lineas.length == 1) {
      setState(() {
        _lineas.first.reset();
      });
      return;
    }

    final removed = _lineas.removeAt(index);
    removed.dispose();

    for (var i = 0; i < _lineas.length; i++) {
      _lineas[i].item = i + 1;
    }

    setState(() {});
  }

  Future<void> _guardar() async {
    final validationMessage = _validate();
    if (validationMessage != null) {
      setState(() => _error = validationMessage);
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final totalNormalizado =
          PriceFormatter.normalize(_totalGeneral.toString());
      final alcanceItems = _alcanceControllers
          .map((controller) => controller.text.trim())
          .where((item) => item.isNotEmpty)
          .toList();
      final payload = <String, dynamic>{
        'fecha': _formatApiDate(_fecha),
        'ciudad': _ciudadController.text.trim(),
        'cliente_nombre': _clienteNombreController.text.trim(),
        'cliente_nit': _nullIfEmpty(_clienteNitController.text),
        'cliente_contacto': _nullIfEmpty(_representanteController.text),
        'cliente_cargo': _nullIfEmpty(_cargoController.text),
        'cliente_ciudad': _nullIfEmpty(_clienteCiudadController.text),
        'cliente_direccion': _nullIfEmpty(_clienteCiudadController.text),
        'referencia': _referenciaController.text.trim(),
        'observaciones': _nullIfEmpty(
          _truncateToWordLimit(
              _observacionesController.text, _maxObservacionesWords),
        ),
        'alcance_items': alcanceItems,
        'oferta_dias_totales': _intValue(_ofertaDiasTotalesController, 30),
        'oferta_dias_ejecucion': _intValue(_ofertaDiasEjecucionController, 15),
        'oferta_dias_tramitologia':
            _intValue(_ofertaDiasTramitologiaController, 15),
        'oferta_pago_1_pct': _pctValue(_ofertaPago1PctController, '50'),
        'oferta_pago_2_pct': _pctValue(_ofertaPago2PctController, '25'),
        'oferta_pago_3_pct': _pctValue(_ofertaPago3PctController, '25'),
        'oferta_garantia_meses': _intValue(_ofertaGarantiaMesesController, 6),
        'firma_path': _nullIfEmpty(_firmaPathController.text),
        'firma_nombre': _firmaNombreController.text.trim().isEmpty
            ? _defaultFirmaNombre
            : _firmaNombreController.text.trim(),
        'firma_cargo': _firmaCargoController.text.trim().isEmpty
            ? _defaultFirmaCargo
            : _firmaCargoController.text.trim(),
        'firma_empresa': _firmaEmpresaController.text.trim().isEmpty
            ? _defaultFirmaEmpresa
            : _firmaEmpresaController.text.trim(),
        'subtotal': totalNormalizado,
        'total': totalNormalizado,
        'detalles': _lineas.map((linea) => linea.toPayload()).toList(),
      };

      final cotizacion = await widget.onSubmit(payload);
      if (_canEditFirma && _usarFirmaPredeterminada) {
        final firmaPath = _nullIfEmpty(_firmaPathController.text);
        final firmaNombre = _firmaNombreController.text.trim().isEmpty
            ? _defaultFirmaNombre
            : _firmaNombreController.text.trim();
        final firmaCargo = _firmaCargoController.text.trim().isEmpty
            ? _defaultFirmaCargo
            : _firmaCargoController.text.trim();
        final firmaEmpresa = _firmaEmpresaController.text.trim().isEmpty
            ? _defaultFirmaEmpresa
            : _firmaEmpresaController.text.trim();
        await widget.controller.repository.guardarFirmaPredeterminada(
          firmaPath: firmaPath,
          firmaNombre: firmaNombre,
          firmaCargo: firmaCargo,
          firmaEmpresa: firmaEmpresa,
        );
        widget.onFirmaPredeterminadaActualizada?.call(
          firmaPath: firmaPath,
          firmaNombre: firmaNombre,
          firmaCargo: firmaCargo,
          firmaEmpresa: firmaEmpresa,
        );
      }
      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(cotizacion);
      return;
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
        _error = 'No fue posible guardar la cotización. $error';
      });
      return;
    }
  }

  String? _validate() {
    if (_ciudadController.text.trim().isEmpty) {
      return 'Debes indicar la ciudad de emisión.';
    }
    if (_clienteNombreController.text.trim().isEmpty) {
      return 'Debes indicar el nombre del cliente.';
    }
    if (_referenciaController.text.trim().isEmpty) {
      return 'Debes indicar la referencia de la cotización.';
    }
    if (_isUploadingFirma) {
      return 'Espera a que termine la carga de la firma.';
    }
    final alcanceValidos = _alcanceControllers
        .map((controller) => controller.text.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    if (alcanceValidos.isEmpty) {
      return 'Debes incluir al menos una línea en el alcance del proyecto.';
    }
    if (_intValue(_ofertaDiasTotalesController, 30) <= 0) {
      return 'Los días totales de la oferta deben ser mayores a cero.';
    }
    if (_intValue(_ofertaDiasEjecucionController, 15) < 0 ||
        _intValue(_ofertaDiasTramitologiaController, 15) < 0) {
      return 'Los días de ejecución y tramitología no pueden ser negativos.';
    }
    if (_intValue(_ofertaGarantiaMesesController, 6) < 0) {
      return 'La garantía en meses no puede ser negativa.';
    }
    if (_countWords(_observacionesController.text) > _maxObservacionesWords) {
      return 'Observaciones permite máximo $_maxObservacionesWords palabras.';
    }

    for (final linea in _lineas) {
      if (linea.descripcion.trim().isEmpty) {
        return 'Cada fila debe tener un servicio seleccionado desde el catálogo.';
      }
      if (linea.unidad.trim().isEmpty) {
        return 'Cada fila debe completar la unidad desde el servicio seleccionado.';
      }
      if (linea.precioUnitario <= 0) {
        return 'Cada fila debe tener valor unitario válido.';
      }
      if (linea.cantidad <= 0) {
        return 'Cada fila debe tener una cantidad mayor que cero.';
      }
    }

    return null;
  }

  double get _totalGeneral =>
      _lineas.fold<double>(0, (sum, linea) => sum + linea.total);

  DateTime? _parseFecha(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    return DateTime.tryParse(raw);
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

  String _formatApiDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String? _nullIfEmpty(String raw) {
    final value = raw.trim();
    return value.isEmpty ? null : value;
  }

  int _countWords(String raw) {
    return RegExp(r'\S+').allMatches(raw).length;
  }

  String _truncateToWordLimit(String raw, int maxWords) {
    final words = RegExp(r'\S+')
        .allMatches(raw)
        .map((match) => match.group(0) ?? '')
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.length <= maxWords) {
      return raw;
    }
    return words.take(maxWords).join(' ');
  }

  void _enforceObservacionesLimit() {
    if (_isNormalizingObservaciones) {
      return;
    }
    final current = _observacionesController.text;
    final truncated = _truncateToWordLimit(current, _maxObservacionesWords);
    if (truncated == current) {
      return;
    }
    _isNormalizingObservaciones = true;
    _observacionesController.value = TextEditingValue(
      text: truncated,
      selection: TextSelection.collapsed(offset: truncated.length),
    );
    _isNormalizingObservaciones = false;
    if (mounted) {
      setState(() {});
    }
  }

  void _handleObservacionesChanged(String _) {
    if (_isNormalizingObservaciones) {
      return;
    }

    final current = _observacionesController.text;
    final currentWords = _countWords(current);
    final previousWords = _countWords(_lastValidObservacionesText);

    if (currentWords > _maxObservacionesWords) {
      _enforceObservacionesLimit();
      return;
    }

    // Once 140 words are reached, block any growth in raw text length.
    // Users can still delete content or replace existing text.
    if (previousWords >= _maxObservacionesWords &&
        current.length > _lastValidObservacionesText.length) {
      _isNormalizingObservaciones = true;
      _observacionesController.value = TextEditingValue(
        text: _lastValidObservacionesText,
        selection:
            TextSelection.collapsed(offset: _lastValidObservacionesText.length),
      );
      _isNormalizingObservaciones = false;
      if (mounted) {
        setState(() {});
      }
      return;
    }

    _lastValidObservacionesText = current;
    if (mounted) {
      setState(() {});
    }
  }

  int _intValue(TextEditingController controller, int fallback) {
    return int.tryParse(controller.text.trim()) ?? fallback;
  }

  String _pctValue(TextEditingController controller, String fallback) {
    final raw = controller.text.trim();
    if (raw.isEmpty) {
      return fallback;
    }
    return raw;
  }

  Uint8List? _trimTransparentPng(Uint8List sourceBytes) {
    final decoded = img.decodePng(sourceBytes);
    if (decoded == null) {
      return null;
    }

    int minX = decoded.width;
    int minY = decoded.height;
    int maxX = -1;
    int maxY = -1;

    for (var y = 0; y < decoded.height; y++) {
      for (var x = 0; x < decoded.width; x++) {
        final pixel = decoded.getPixel(x, y);
        final alpha = pixel.a.toInt();
        if (alpha <= 2) {
          continue;
        }

        if (x < minX) minX = x;
        if (y < minY) minY = y;
        if (x > maxX) maxX = x;
        if (y > maxY) maxY = y;
      }
    }

    if (maxX < minX || maxY < minY) {
      return null;
    }

    const padding = 8;
    final cropX = (minX - padding).clamp(0, decoded.width - 1);
    final cropY = (minY - padding).clamp(0, decoded.height - 1);
    final cropW =
        (maxX - minX + 1 + padding * 2).clamp(1, decoded.width - cropX);
    final cropH =
        (maxY - minY + 1 + padding * 2).clamp(1, decoded.height - cropY);

    final cropped = img.copyCrop(
      decoded,
      x: cropX,
      y: cropY,
      width: cropW,
      height: cropH,
    );

    final encoded = img.encodePng(cropped);
    return Uint8List.fromList(encoded);
  }
}

class _PreviewDocumentSheet extends StatelessWidget {
  const _PreviewDocumentSheet({
    required this.cotizacion,
    required this.fecha,
    required this.isDesktop,
  });

  final Cotizacion cotizacion;
  final DateTime fecha;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: _CotizacionFormScreenState._line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x160F172A),
            blurRadius: 26,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              isDesktop ? 40 : 18,
              isDesktop ? 30 : 18,
              isDesktop ? 40 : 18,
              isDesktop ? 34 : 22,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _PreviewDocumentHeader(),
                const SizedBox(height: 24),
                _PreviewCityDateSection(cotizacion: cotizacion, fecha: fecha),
                const SizedBox(height: 18),
                _PreviewClientSection(cotizacion: cotizacion),
                const SizedBox(height: 18),
                _PreviewReferenceSection(cotizacion: cotizacion),
                const SizedBox(height: 18),
                const _PreviewIntroSection(),
                const SizedBox(height: 18),
                _PreviewDescriptiveTableSection(cotizacion: cotizacion),
                if ((cotizacion.observaciones ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _PreviewObservacionesSection(cotizacion: cotizacion),
                ],
                const SizedBox(height: 26),
                const Divider(
                  color: _CotizacionFormScreenState._ink900,
                  thickness: 4,
                ),
                const SizedBox(height: 14),
                const _PreviewFooter(),
              ],
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: ColorFiltered(
                  colorFilter: const ColorFilter.matrix([
                    1.25,
                    -0.12,
                    -0.12,
                    0,
                    0,
                    -0.12,
                    1.25,
                    -0.12,
                    0,
                    0,
                    -0.12,
                    -0.12,
                    1.25,
                    0,
                    0,
                    0,
                    0,
                    0,
                    1,
                    0,
                  ]),
                  child: Opacity(
                    opacity: 0.21,
                    child: FractionallySizedBox(
                      widthFactor: 0.40,
                      heightFactor: 0.58,
                      child: Image.asset(
                        _marcaAguaTeslaAsset,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewSecondDocumentSheet extends StatelessWidget {
  const _PreviewSecondDocumentSheet({
    required this.cotizacion,
    required this.isDesktop,
  });

  final Cotizacion cotizacion;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final alcance = cotizacion.alcanceItems.isEmpty
        ? _defaultAlcanceItems
        : cotizacion.alcanceItems;

    final firmaNombre =
        _fallbackText(cotizacion.firmaNombre, fallback: _defaultFirmaNombre);
    final firmaCargo =
        _fallbackText(cotizacion.firmaCargo, fallback: _defaultFirmaCargo);
    final firmaEmpresa =
        _fallbackText(cotizacion.firmaEmpresa, fallback: _defaultFirmaEmpresa);
    final firmaPath = (cotizacion.firmaPath ?? '').trim();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: _CotizacionFormScreenState._line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x160F172A),
            blurRadius: 26,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: ColorFiltered(
                  colorFilter: const ColorFilter.matrix([
                    1.25,
                    -0.12,
                    -0.12,
                    0,
                    0,
                    -0.12,
                    1.25,
                    -0.12,
                    0,
                    0,
                    -0.12,
                    -0.12,
                    1.25,
                    0,
                    0,
                    0,
                    0,
                    0,
                    1,
                    0,
                  ]),
                  child: Opacity(
                    opacity: 0.21,
                    child: FractionallySizedBox(
                      widthFactor: 0.40,
                      heightFactor: 0.58,
                      child: Image.asset(
                        _marcaAguaTeslaAsset,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              isDesktop ? 40 : 18,
              isDesktop ? 30 : 18,
              isDesktop ? 40 : 18,
              isDesktop ? 34 : 22,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _PreviewDocumentHeader(),
                const SizedBox(height: 24),
                const Text(
                  'EL ALCANCE DEL PROYECTO INCLUYE:',
                  style: TextStyle(
                    color: _CotizacionFormScreenState._ink900,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 10),
                for (final item in alcance) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.bolt_rounded,
                          size: 20,
                          color: Color(0xFF1D4ED8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item,
                          style: const TextStyle(
                            color: _CotizacionFormScreenState._ink900,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
                const SizedBox(height: 16),
                const Text(
                  'CONDICIONES DE LA OFERTA:',
                  style: TextStyle(
                    color: _CotizacionFormScreenState._ink900,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.only(left: 52, right: 44),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            color: _CotizacionFormScreenState._ink900,
                            fontSize: 16,
                            height: 1.45,
                            fontWeight: FontWeight.w400,
                          ),
                          children: [
                            const TextSpan(
                              text: 'Tiempo de entrega:',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                            TextSpan(
                              text:
                                  ' El tiempo estimado para la ejecución del proyecto es de (${cotizacion.ofertaDiasTotales}) días calendario, salvo condiciones especiales que impidan el desarrollo normal de las actividades programadas. La distribución del tiempo de trabajo es la siguiente:',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 1),
                            child: Text(
                              '✓',
                              style: TextStyle(
                                color: _CotizacionFormScreenState._ink900,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                height: 1.1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '(${cotizacion.ofertaDiasEjecucion}) días de ejecución, a partir de este momento los predios podrán conectarse a la red de baja tensión, siempre y cuando cuenten con la acometida, caja para la instalación de medidor, caja de protecciones e instalación interna.',
                              style: const TextStyle(
                                color: _CotizacionFormScreenState._ink900,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 1),
                            child: Text(
                              '✓',
                              style: TextStyle(
                                color: _CotizacionFormScreenState._ink900,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                height: 1.1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '(${cotizacion.ofertaDiasTramitologia}) días tramitología ante EMSA.',
                              style: const TextStyle(
                                color: _CotizacionFormScreenState._ink900,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(
                              Icons.bolt_rounded,
                              size: 20,
                              color: Color(0xFF1D4ED8),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Forma de pago:',
                              style: TextStyle(
                                color: _CotizacionFormScreenState._ink900,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'La forma de pago para el desarrollo del proyecto se establece de la siguiente manera:',
                        style: TextStyle(
                          color: _CotizacionFormScreenState._ink900,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 26),
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              color: _CotizacionFormScreenState._ink900,
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              height: 1.45,
                            ),
                            children: [
                              const TextSpan(
                                text: 'Pago 1:',
                                style: TextStyle(fontWeight: FontWeight.w900),
                              ),
                              TextSpan(
                                text:
                                    ' Correspondiente al ${cotizacion.ofertaPago1Pct}% del valor total del contrato, contra entrega de la orden de servicio.',
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 26),
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              color: _CotizacionFormScreenState._ink900,
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              height: 1.45,
                            ),
                            children: [
                              const TextSpan(
                                text: 'Pago 2:',
                                style: TextStyle(fontWeight: FontWeight.w900),
                              ),
                              TextSpan(
                                text:
                                    ' Correspondiente al ${cotizacion.ofertaPago2Pct}% del valor total, una vez se energice el transformador y la red de baja tensión.',
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 26),
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              color: _CotizacionFormScreenState._ink900,
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              height: 1.45,
                            ),
                            children: [
                              const TextSpan(
                                text: 'Pago 3:',
                                style: TextStyle(fontWeight: FontWeight.w900),
                              ),
                              TextSpan(
                                text:
                                    ' Correspondiente al ${cotizacion.ofertaPago3Pct}% restante, último pago parcial, a realizar una vez se instalen los medidores en los predios legalizados.',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(
                              Icons.bolt_rounded,
                              size: 20,
                              color: Color(0xFF1D4ED8),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Garantía: ${cotizacion.ofertaGarantiaMeses} meses, bajo condiciones eléctricas normales.',
                              style: const TextStyle(
                                color: _CotizacionFormScreenState._ink900,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Cordialmente,',
                  style: TextStyle(
                    color: _CotizacionFormScreenState._ink900,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),
                _PreviewFirmaGraphic(
                    firmaPath: firmaPath, fallbackName: firmaNombre),
                const SizedBox(height: 8),
                Text(
                  firmaNombre,
                  style: const TextStyle(
                    color: _CotizacionFormScreenState._ink900,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  firmaCargo,
                  style: const TextStyle(
                    color: _CotizacionFormScreenState._ink900,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  firmaEmpresa,
                  style: const TextStyle(
                    color: _CotizacionFormScreenState._ink900,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 26),
                const Divider(
                  color: _CotizacionFormScreenState._ink900,
                  thickness: 4,
                ),
                const SizedBox(height: 14),
                const _PreviewFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewFirmaGraphic extends StatelessWidget {
  const _PreviewFirmaGraphic({
    required this.firmaPath,
    required this.fallbackName,
  });

  final String firmaPath;
  final String fallbackName;

  @override
  Widget build(BuildContext context) {
    final resolvedFirmaPath = _resolveFirmaPathForRender(firmaPath);

    if (firmaPath.isEmpty) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text(
          fallbackName,
          style: const TextStyle(
            color: _CotizacionFormScreenState._ink700,
            fontSize: 36,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    if (resolvedFirmaPath.startsWith('http://') ||
        resolvedFirmaPath.startsWith('https://')) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Image.network(
          resolvedFirmaPath,
          height: 76,
          alignment: Alignment.centerLeft,
          fit: BoxFit.fitHeight,
          errorBuilder: (_, __, ___) => const Text(
            'No fue posible cargar la imagen de firma.',
            style: TextStyle(
              color: _CotizacionFormScreenState._danger,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    if (resolvedFirmaPath.startsWith('assets/')) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Image.asset(
          resolvedFirmaPath,
          height: 76,
          alignment: Alignment.centerLeft,
          fit: BoxFit.fitHeight,
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        resolvedFirmaPath,
        style: const TextStyle(
          color: _CotizacionFormScreenState._ink700,
          fontSize: 14,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

class _PreviewDocumentHeader extends StatelessWidget {
  const _PreviewDocumentHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Image(
            image: AssetImage(_logoTeslaAsset),
            height: 70,
            fit: BoxFit.contain,
          ),
        ),
        SizedBox(height: 18),
        Text(
          _institutionalText,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _CotizacionFormScreenState._ink900,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            height: 1.25,
          ),
        ),
      ],
    );
  }
}

class _PreviewCityDateSection extends StatelessWidget {
  const _PreviewCityDateSection({
    required this.cotizacion,
    required this.fecha,
  });

  final Cotizacion cotizacion;
  final DateTime fecha;

  @override
  Widget build(BuildContext context) {
    return Text(
      '${_fallbackText(cotizacion.ciudad, fallback: 'Ciudad pendiente')}, ${_formatFechaLarga(fecha)}.',
      style: const TextStyle(
        color: _CotizacionFormScreenState._ink900,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _PreviewClientSection extends StatelessWidget {
  const _PreviewClientSection({
    required this.cotizacion,
  });

  final Cotizacion cotizacion;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Señores:',
          style: TextStyle(
            color: _CotizacionFormScreenState._ink900,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _fallbackText(cotizacion.clienteNombre, fallback: 'CLIENTE PENDIENTE')
              .toUpperCase(),
          style: const TextStyle(
            color: _CotizacionFormScreenState._ink900,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'NIT: ${_fallbackText(cotizacion.clienteNit, fallback: 'PENDIENTE')}',
          style: const TextStyle(
            color: _CotizacionFormScreenState._ink900,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          _fallbackText(
            cotizacion.clienteContacto,
            fallback: 'Representante pendiente',
          ).toUpperCase(),
          style: const TextStyle(
            color: _CotizacionFormScreenState._ink900,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          _fallbackText(cotizacion.clienteCargo, fallback: 'Cargo pendiente'),
          style: const TextStyle(
            color: _CotizacionFormScreenState._ink900,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          _fallbackText(cotizacion.clienteCiudad, fallback: 'Ciudad pendiente'),
          style: const TextStyle(
            color: _CotizacionFormScreenState._ink900,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _PreviewReferenceSection extends StatelessWidget {
  const _PreviewReferenceSection({
    required this.cotizacion,
  });

  final Cotizacion cotizacion;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Ref. COTIZACIÓN, ${_fallbackText(cotizacion.referencia, fallback: 'REFERENCIA PENDIENTE').toUpperCase()}.',
      style: const TextStyle(
        color: _CotizacionFormScreenState._ink900,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _PreviewIntroSection extends StatelessWidget {
  const _PreviewIntroSection();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _introParagraphOne,
          style: TextStyle(
            color: _CotizacionFormScreenState._ink900,
            fontSize: 16,
            height: 1.45,
          ),
        ),
        SizedBox(height: 14),
        Text(
          _introParagraphTwo,
          style: TextStyle(
            color: _CotizacionFormScreenState._ink900,
            fontSize: 16,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _PreviewDescriptiveTableSection extends StatelessWidget {
  const _PreviewDescriptiveTableSection({
    required this.cotizacion,
  });

  final Cotizacion cotizacion;

  @override
  Widget build(BuildContext context) {
    final detalles = List<CotizacionDetalle>.from(cotizacion.detalles)
      ..sort((left, right) => left.item.compareTo(right.item));
    final emptyRowsCount = detalles.length >= _minVisibleServiceRows
        ? 0
        : _minVisibleServiceRows - detalles.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cuadro descriptivo:',
          style: TextStyle(
            color: _CotizacionFormScreenState._ink900,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: _CotizacionFormScreenState._paperLine,
              ),
              color: Colors.white.withValues(alpha: 0.80),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: _previewTableMinWidth(
                    AdaptiveLayout.isDesktopContext(context),
                  ),
                ),
                child: Column(
                  children: [
                    const _PreviewTableHeaderRow(),
                    for (final detalle in detalles)
                      _PreviewTableDataRow(detalle: detalle),
                    for (var index = 0; index < emptyRowsCount; index++)
                      _PreviewTablePlaceholderRow(
                        itemLabel: '${detalles.length + index + 1}',
                      ),
                    _PreviewTableTotalRow(cotizacion: cotizacion),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PreviewObservacionesSection extends StatelessWidget {
  const _PreviewObservacionesSection({
    required this.cotizacion,
  });

  final Cotizacion cotizacion;

  @override
  Widget build(BuildContext context) {
    final observaciones = _trimObservacionesForLayout(
      cotizacion.observaciones ?? '',
      maxWords: _maxObservacionesWords,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Observaciones',
          style: TextStyle(
            color: _CotizacionFormScreenState._ink900,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _CotizacionFormScreenState._paperLine),
          ),
          child: Text(
            observaciones,
            style: const TextStyle(
              color: _CotizacionFormScreenState._ink900,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}

class _PreviewFooter extends StatelessWidget {
  const _PreviewFooter();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Text(
          _footerLineOne,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _CotizacionFormScreenState._ink900,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2),
        Text(
          _footerLineTwo,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _CotizacionFormScreenState._ink900,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2),
        Text(
          _footerLineThree,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _CotizacionFormScreenState._ink900,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _PreviewTableHeaderRow extends StatelessWidget {
  const _PreviewTableHeaderRow();

  @override
  Widget build(BuildContext context) {
    final isDesktop = AdaptiveLayout.isDesktopContext(context);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF1F5F9),
        border: Border(
            bottom: BorderSide(color: _CotizacionFormScreenState._paperLine)),
      ),
      child: Row(
        children: [
          _PreviewTableCell(
            width: _previewItemWidth(isDesktop),
            label: 'ITEM',
            isHeader: true,
            alignment: Alignment.center,
          ),
          _PreviewTableCell(
            width: _previewDescripcionWidth(isDesktop),
            label: 'DESCRIPCIÓN',
            isHeader: true,
            alignment: Alignment.center,
          ),
          _PreviewTableCell(
            width: _previewUnidadWidth(isDesktop),
            label: 'MEDIDA',
            isHeader: true,
            alignment: Alignment.center,
          ),
          _PreviewTableCell(
            width: _previewCantidadWidth(isDesktop),
            label: 'CANT.',
            isHeader: true,
            alignment: Alignment.center,
          ),
          _PreviewTableCell(
            width: _previewValorWidth(isDesktop),
            label: 'C_UNITARIO',
            isHeader: true,
            alignment: Alignment.center,
          ),
          _PreviewTableCell(
            width: _previewTotalWidth(isDesktop),
            label: 'C_TOTAL',
            isHeader: true,
            alignment: Alignment.center,
          ),
        ],
      ),
    );
  }
}

class _PreviewTableDataRow extends StatelessWidget {
  const _PreviewTableDataRow({
    required this.detalle,
  });

  final CotizacionDetalle detalle;

  @override
  Widget build(BuildContext context) {
    final isDesktop = AdaptiveLayout.isDesktopContext(context);
    final itemLabel = detalle.item > 0 ? '${detalle.item}' : '-';
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: _CotizacionFormScreenState._paperLine),
        ),
      ),
      child: Row(
        children: [
          _PreviewTableCell(
            width: _previewItemWidth(isDesktop),
            label: itemLabel,
            alignment: Alignment.centerRight,
          ),
          _PreviewTableCell(
            width: _previewDescripcionWidth(isDesktop),
            label: _fallbackText(detalle.descripcion, fallback: '-'),
          ),
          _PreviewTableCell(
            width: _previewUnidadWidth(isDesktop),
            label: _fallbackText(detalle.unidad, fallback: '-'),
            alignment: Alignment.center,
          ),
          _PreviewTableCell(
            width: _previewCantidadWidth(isDesktop),
            label: _formatCantidadPreview(detalle.cantidad),
            alignment: Alignment.center,
          ),
          _PreviewTableCell(
            width: _previewValorWidth(isDesktop),
            label: PriceFormatter.formatCopWhole(detalle.precioUnitario),
            alignment: Alignment.center,
          ),
          _PreviewTableCell(
            width: _previewTotalWidth(isDesktop),
            label: PriceFormatter.formatCopWhole(detalle.subtotal),
            alignment: Alignment.center,
            emphasize: true,
          ),
        ],
      ),
    );
  }
}

class _PreviewTablePlaceholderRow extends StatelessWidget {
  const _PreviewTablePlaceholderRow({
    required this.itemLabel,
  });

  final String itemLabel;

  @override
  Widget build(BuildContext context) {
    final isDesktop = AdaptiveLayout.isDesktopContext(context);
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: _CotizacionFormScreenState._paperLine),
        ),
      ),
      child: Row(
        children: [
          _PreviewTableCell(
            width: _previewItemWidth(isDesktop),
            label: itemLabel,
            alignment: Alignment.centerRight,
          ),
          _PreviewTableCell(
            width: _previewDescripcionWidth(isDesktop),
            label: '',
          ),
          _PreviewTableCell(
            width: _previewUnidadWidth(isDesktop),
            label: '',
            alignment: Alignment.center,
          ),
          _PreviewTableCell(
            width: _previewCantidadWidth(isDesktop),
            label: '',
            alignment: Alignment.center,
          ),
          _PreviewTableCell(
            width: _previewValorWidth(isDesktop),
            label: '',
            alignment: Alignment.center,
          ),
          _PreviewTableCell(
            width: _previewTotalWidth(isDesktop),
            label: '',
            alignment: Alignment.center,
          ),
        ],
      ),
    );
  }
}

class _PreviewTableTotalRow extends StatelessWidget {
  const _PreviewTableTotalRow({
    required this.cotizacion,
  });

  final Cotizacion cotizacion;

  @override
  Widget build(BuildContext context) {
    final isDesktop = AdaptiveLayout.isDesktopContext(context);

    return Row(
      children: [
        _PreviewTableCell(
          width: _previewTotalLabelWidth(isDesktop),
          label: 'TOTAL',
          isHeader: true,
          alignment: Alignment.center,
        ),
        _PreviewTableCell(
          width: _previewTotalWidth(isDesktop),
          label: PriceFormatter.formatCopWhole(cotizacion.total),
          alignment: Alignment.centerRight,
          emphasize: true,
          isHeader: true,
        ),
      ],
    );
  }
}

class _PreviewTableCell extends StatelessWidget {
  const _PreviewTableCell({
    required this.width,
    required this.label,
    this.alignment = Alignment.centerLeft,
    this.isHeader = false,
    this.emphasize = false,
  });

  final double width;
  final String label;
  final Alignment alignment;
  final bool isHeader;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(color: _CotizacionFormScreenState._paperLine),
        ),
      ),
      child: Text(
        label,
        textAlign: alignment == Alignment.center
            ? TextAlign.center
            : (alignment == Alignment.centerRight
                ? TextAlign.right
                : TextAlign.left),
        style: TextStyle(
          color: _CotizacionFormScreenState._ink900,
          fontSize: isHeader ? 13 : 15,
          fontWeight: isHeader || emphasize ? FontWeight.w800 : FontWeight.w600,
          height: 1.35,
        ),
      ),
    );
  }
}

class _FirmaCanvasDialog extends StatefulWidget {
  const _FirmaCanvasDialog();

  @override
  State<_FirmaCanvasDialog> createState() => _FirmaCanvasDialogState();
}

class _FirmaCanvasDialogState extends State<_FirmaCanvasDialog> {
  late final SignatureController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SignatureController(
      penStrokeWidth: 2.4,
      penColor: const Color(0xFF0F172A),
      exportBackgroundColor: Colors.transparent,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = AdaptiveLayout.isDesktopContext(context);
    return AlertDialog(
      title: const Text('Dibujar firma'),
      content: SizedBox(
        width: isDesktop ? 680 : 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Signature(
                controller: _controller,
                backgroundColor: Colors.transparent,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Dibuja la firma con mouse o dedo. Luego presiona "Usar firma".',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => _controller.clear(),
          child: const Text('Limpiar'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () async {
            if (_controller.isEmpty) {
              return;
            }
            final bytes = await _controller.toPngBytes();
            if (!context.mounted) {
              return;
            }
            Navigator.of(context).pop(bytes);
          },
          child: const Text('Usar firma'),
        ),
      ],
    );
  }
}

DateTime? _parseFecha(String? raw) {
  if (raw == null || raw.trim().isEmpty) {
    return null;
  }

  return DateTime.tryParse(raw);
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

String _fallbackText(String? value, {required String fallback}) {
  final normalized = value?.trim() ?? '';
  return normalized.isEmpty ? fallback : normalized;
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

String _formatCantidadPreview(String raw) {
  final value = PriceFormatter.parse(raw);
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }

  return value.toStringAsFixed(2);
}

String _trimObservacionesForLayout(String raw, {required int maxWords}) {
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

double _editableItemWidth(bool isDesktop) => isDesktop ? 72 : 52;
double _editableDescripcionWidth(bool isDesktop) => isDesktop ? 398 : 240;
double _editableUnidadWidth(bool isDesktop) => isDesktop ? 118 : 88;
double _editableCantidadWidth(bool isDesktop) => isDesktop ? 118 : 84;
double _editableValorWidth(bool isDesktop) => isDesktop ? 164 : 124;
double _editableTotalWidth(bool isDesktop) => isDesktop ? 164 : 124;
double _editableAccionWidth(bool isDesktop) => isDesktop ? 78 : 60;
double _editableTableMinWidth(bool isDesktop) =>
    _editableItemWidth(isDesktop) +
    _editableDescripcionWidth(isDesktop) +
    _editableUnidadWidth(isDesktop) +
    _editableCantidadWidth(isDesktop) +
    _editableValorWidth(isDesktop) +
    _editableTotalWidth(isDesktop) +
    _editableAccionWidth(isDesktop);
double _editableTotalLabelWidth(bool isDesktop) =>
    _editableItemWidth(isDesktop) +
    _editableDescripcionWidth(isDesktop) +
    _editableUnidadWidth(isDesktop) +
    _editableCantidadWidth(isDesktop) +
    _editableValorWidth(isDesktop);
double _editableTotalValueWidth(bool isDesktop) =>
    _editableTotalWidth(isDesktop) + _editableAccionWidth(isDesktop);

double _previewItemWidth(bool isDesktop) => isDesktop ? 72 : 52;
double _previewDescripcionWidth(bool isDesktop) => isDesktop ? 430 : 240;
double _previewUnidadWidth(bool isDesktop) => isDesktop ? 110 : 88;
double _previewCantidadWidth(bool isDesktop) => isDesktop ? 96 : 80;
double _previewValorWidth(bool isDesktop) => isDesktop ? 160 : 124;
double _previewTotalWidth(bool isDesktop) => isDesktop ? 172 : 124;
double _previewTableMinWidth(bool isDesktop) =>
    _previewItemWidth(isDesktop) +
    _previewDescripcionWidth(isDesktop) +
    _previewUnidadWidth(isDesktop) +
    _previewCantidadWidth(isDesktop) +
    _previewValorWidth(isDesktop) +
    _previewTotalWidth(isDesktop);
double _previewTotalLabelWidth(bool isDesktop) =>
    _previewItemWidth(isDesktop) +
    _previewDescripcionWidth(isDesktop) +
    _previewUnidadWidth(isDesktop) +
    _previewCantidadWidth(isDesktop) +
    _previewValorWidth(isDesktop);

class _DocumentInput extends StatelessWidget {
  const _DocumentInput({
    required this.label,
    required this.controller,
    required this.hintText,
    this.onChanged,
    this.textCapitalization = TextCapitalization.sentences,
  });

  final String label;
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide:
              const BorderSide(color: _CotizacionFormScreenState._paperLine),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide:
              const BorderSide(color: _CotizacionFormScreenState._paperLine),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide:
              const BorderSide(color: _CotizacionFormScreenState._ink900),
        ),
      ),
      onChanged: onChanged,
    );
  }
}

class _DateInput extends StatelessWidget {
  const _DateInput({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide:
                const BorderSide(color: _CotizacionFormScreenState._paperLine),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide:
                const BorderSide(color: _CotizacionFormScreenState._paperLine),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  color: _CotizacionFormScreenState._ink900,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.calendar_today_outlined, size: 18),
          ],
        ),
      ),
    );
  }
}

class _TableHeaderCell extends StatelessWidget {
  const _TableHeaderCell({
    required this.width,
    required this.label,
  });

  final double width;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _CotizacionFormScreenState._ink900,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _TableValueCell extends StatelessWidget {
  const _TableValueCell({
    required this.width,
    required this.child,
    this.alignment = Alignment.centerLeft,
  });

  final double width;
  final Widget child;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: child,
    );
  }
}

class _ServicioPickerField extends StatelessWidget {
  const _ServicioPickerField({
    required this.selectedLabel,
    required this.servicios,
    required this.onSelected,
    required this.enabled,
    required this.catalogoError,
  });

  final String selectedLabel;
  final List<Servicio> servicios;
  final ValueChanged<Servicio> onSelected;
  final bool enabled;
  final String? catalogoError;

  @override
  Widget build(BuildContext context) {
    final hasValue = selectedLabel.trim().isNotEmpty;

    return InkWell(
      onTap: !enabled
          ? null
          : () async {
              final selected = await showDialog<Servicio>(
                context: context,
                builder: (_) => _ServicioPickerDialog(
                  servicios: servicios,
                ),
              );

              if (selected != null) {
                onSelected(selected);
              }
            },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFFF8FAFC) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasValue
                ? _CotizacionFormScreenState._paperLine
                : const Color(0xFFCBD5E1),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                hasValue
                    ? selectedLabel
                    : (catalogoError != null
                        ? 'Catálogo no disponible'
                        : 'Seleccionar servicio'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: hasValue
                      ? _CotizacionFormScreenState._ink900
                      : _CotizacionFormScreenState._ink500,
                  fontWeight: hasValue ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.search_rounded,
              size: 18,
              color: enabled
                  ? _CotizacionFormScreenState._ink700
                  : _CotizacionFormScreenState._ink500,
            ),
          ],
        ),
      ),
    );
  }
}

class _ServicioPickerDialog extends StatefulWidget {
  const _ServicioPickerDialog({
    required this.servicios,
  });

  final List<Servicio> servicios;

  @override
  State<_ServicioPickerDialog> createState() => _ServicioPickerDialogState();
}

class _ServicioPickerDialogState extends State<_ServicioPickerDialog> {
  static const _allCategoriesValue = '__all__';
  static const _noCategoryValue = '__no_category__';
  late final TextEditingController _searchController;
  String _query = '';
  String _selectedCategory = _allCategoriesValue;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final availableCategories = widget.servicios
        .map((servicio) => normalizeServiceCategory(servicio.categoria))
        .where((categoria) => categoria.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => formatServiceCategoryLabel(a)
          .compareTo(formatServiceCategoryLabel(b)));

    final filtered = widget.servicios.where((servicio) {
      final query = _query.trim().toLowerCase();
      final servicioCategoria = normalizeServiceCategory(servicio.categoria);

      if (_selectedCategory != _allCategoriesValue &&
          servicioCategoria != _selectedCategory) {
        return false;
      }

      if (query.isEmpty) {
        return true;
      }

      return servicio.descripcion.toLowerCase().contains(query) ||
          servicio.codigo.toLowerCase().contains(query) ||
          servicio.unidad.toLowerCase().contains(query) ||
          servicioCategoria.contains(query);
    }).toList()
      ..sort((a, b) {
        final categoryComparison = formatServiceCategoryLabel(a.categoria)
            .compareTo(formatServiceCategoryLabel(b.categoria));
        if (categoryComparison != 0) {
          return categoryComparison;
        }

        return a.descripcion
            .toLowerCase()
            .compareTo(b.descripcion.toLowerCase());
      });

    final grouped = <String, List<Servicio>>{};
    for (final servicio in filtered) {
      final normalizedCategory = normalizeServiceCategory(servicio.categoria);
      final categoryKey =
          normalizedCategory.isEmpty ? _noCategoryValue : normalizedCategory;
      grouped.putIfAbsent(categoryKey, () => <Servicio>[]).add(servicio);
    }

    final groupedCategories = grouped.keys.toList()
      ..sort((a, b) {
        if (a == _noCategoryValue) {
          return 1;
        }
        if (b == _noCategoryValue) {
          return -1;
        }
        return formatServiceCategoryLabel(a)
            .compareTo(formatServiceCategoryLabel(b));
      });

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 620),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Seleccionar servicio',
                style: TextStyle(
                  color: _CotizacionFormScreenState._ink900,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Busca por descripción, código o unidad y selecciona el servicio para autollenar la fila.',
                style: TextStyle(
                  color: _CotizacionFormScreenState._ink500,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Buscar servicio',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: _CotizacionFormScreenState._paperLine,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: _CotizacionFormScreenState._paperLine,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: _CotizacionFormScreenState._ink900,
                    ),
                  ),
                ),
                onChanged: (value) {
                  if (!mounted) {
                    return;
                  }
                  setState(() {
                    _query = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                items: [
                  const DropdownMenuItem<String>(
                    value: _allCategoriesValue,
                    child: Text('Todas las categorias'),
                  ),
                  for (final categoria in availableCategories)
                    DropdownMenuItem<String>(
                      value: categoria,
                      child: Text(formatServiceCategoryLabel(categoria)),
                    ),
                ],
                onChanged: (value) {
                  if (value == null || !mounted) {
                    return;
                  }
                  setState(() {
                    _selectedCategory = value;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Categoria',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: _CotizacionFormScreenState._paperLine,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: _CotizacionFormScreenState._paperLine,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: _CotizacionFormScreenState._ink900,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: _CotizacionFormScreenState._paperLine,
                    ),
                  ),
                  child: filtered.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'No hay servicios que coincidan con la búsqueda.',
                              style: TextStyle(
                                color: _CotizacionFormScreenState._ink500,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                          children: [
                            for (final category in groupedCategories) ...[
                              Padding(
                                padding: const EdgeInsets.fromLTRB(6, 10, 6, 6),
                                child: Text(
                                  category == _noCategoryValue
                                      ? 'Sin categoria'
                                      : formatServiceCategoryLabel(category),
                                  style: const TextStyle(
                                    color: _CotizacionFormScreenState._ink700,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                              ...grouped[category]!.map(
                                (servicio) => ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                  title: Text(
                                    servicio.descripcion,
                                    style: const TextStyle(
                                      color: _CotizacionFormScreenState._ink900,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${servicio.codigo} · ${servicio.unidad} · ${PriceFormatter.formatCopLatino(servicio.precioUnitario)}',
                                    style: const TextStyle(
                                      color: _CotizacionFormScreenState._ink500,
                                    ),
                                  ),
                                  onTap: () =>
                                      Navigator.of(context).pop(servicio),
                                ),
                              ),
                              const Divider(height: 14),
                            ],
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cerrar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LineaCotizacionDraft {
  _LineaCotizacionDraft({
    required this.item,
    required this.servicioId,
    required this.descripcion,
    required this.unidad,
    required this.precioUnitario,
    required String cantidad,
  }) : cantidadController = TextEditingController(text: cantidad);

  factory _LineaCotizacionDraft.empty({required int item}) {
    return _LineaCotizacionDraft(
      item: item,
      servicioId: null,
      descripcion: '',
      unidad: '',
      precioUnitario: 0,
      cantidad: '',
    );
  }

  factory _LineaCotizacionDraft.fromDetalle(CotizacionDetalle detalle) {
    return _LineaCotizacionDraft(
      item: detalle.item,
      servicioId: detalle.servicioId,
      descripcion: detalle.descripcion,
      unidad: detalle.unidad,
      precioUnitario: PriceFormatter.parse(detalle.precioUnitario),
      cantidad: _formatCantidad(detalle.cantidad),
    );
  }

  int item;
  int? servicioId;
  String descripcion;
  String unidad;
  double precioUnitario;
  final TextEditingController cantidadController;

  double get cantidad => PriceFormatter.parse(cantidadController.text);
  double get total => cantidad * precioUnitario;

  void applyServicio(Servicio servicio, {bool preserveCantidad = false}) {
    servicioId = servicio.id;
    descripcion = servicio.descripcion;
    unidad = servicio.unidad;
    precioUnitario = PriceFormatter.parse(servicio.precioUnitario);
    if (!preserveCantidad && cantidadController.text.trim().isEmpty) {
      cantidadController.text = '';
    }
  }

  void reset() {
    servicioId = null;
    descripcion = '';
    unidad = '';
    precioUnitario = 0;
    cantidadController.clear();
  }

  Map<String, dynamic> toPayload() {
    final cantidadValue = cantidad;
    final totalValue = total;

    return {
      'item': item,
      'servicio_id': servicioId,
      'descripcion': descripcion.trim(),
      'unidad': unidad.trim(),
      'cantidad': PriceFormatter.normalize(cantidadValue.toString()),
      'precio_unitario': PriceFormatter.normalize(precioUnitario.toString()),
      'subtotal': PriceFormatter.normalize(totalValue.toString()),
      'total': PriceFormatter.normalize(totalValue.toString()),
    };
  }

  void dispose() {
    cantidadController.dispose();
  }

  static String _formatCantidad(String raw) {
    final value = PriceFormatter.parse(raw);
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toString();
  }
}
