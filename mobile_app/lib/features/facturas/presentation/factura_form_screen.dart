import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:signature/signature.dart';

import '../../../core/api/api_client.dart';
import '../../../core/config/app_config.dart';
import '../../../core/layout/adaptive_layout.dart';
import '../../../shared/utils/price_formatter.dart';
import '../../productos/domain/producto.dart';
import '../../servicios/domain/servicio.dart';
import '../domain/factura.dart';
import '../domain/factura_item.dart';
import '../facturas_controller.dart';

const _logoTeslaAsset = 'assets/images/logo_tesla.png';

class FacturaFormScreen extends StatefulWidget {
  const FacturaFormScreen({
    super.key,
    required this.controller,
    required this.canEditFacturacion,
    this.canEditFirma = false,
    this.initialFactura,
    this.readOnly = false,
    this.defaultFirmaPath,
    this.defaultFirmaNombre,
    this.defaultFirmaCargo,
    this.defaultFirmaEmpresa,
    this.onFirmaPredeterminadaActualizada,
  });

  final FacturasController controller;
  final Factura? initialFactura;
  final bool canEditFacturacion;
  final bool canEditFirma;
  final bool readOnly;
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
  State<FacturaFormScreen> createState() => _FacturaFormScreenState();
}

class _FacturaFormScreenState extends State<FacturaFormScreen> {
  static const _slate900 = Color(0xFF0F172A);
  static const _slate500 = Color(0xFF64748B);
  static const _slate200 = Color(0xFFE2E8F0);
  static const _slate100 = Color(0xFFF1F5F9);
  static const _rose600 = Color(0xFFE11D48);

  late final TextEditingController _ciudadExpedicionController;
  late final TextEditingController _clienteNombreController;
  late final TextEditingController _clienteNitController;
  late final TextEditingController _clienteCiudadController;
  late final TextEditingController _clienteContactoController;
  late final TextEditingController _clienteDireccionController;
  late final TextEditingController _observacionesController;
  late final TextEditingController _firmaPathController;
  late final TextEditingController _firmaNombreController;
  late final TextEditingController _firmaCargoController;
  late final TextEditingController _firmaEmpresaController;

  final List<_FacturaItemDraft> _items = [];
  List<Servicio> _servicios = const [];
  List<Producto> _productos = const [];
  bool _isLoadingServicios = false;
  bool _isUploadingFirma = false;
  bool _usarFirmaPredeterminada = false;

  DateTime _fecha = DateTime.now();
  bool _isSaving = false;
  bool _isLoadingInitial = false;
  String? _error;

  bool get _isEditing => widget.initialFactura != null;
  bool get _isReadonlyByState {
    final factura = widget.initialFactura;
    if (factura == null) {
      return false;
    }

    return !factura.isBorrador;
  }

  bool get _canEdit =>
      widget.canEditFacturacion && !_isReadonlyByState && !widget.readOnly;

  double get _subtotal =>
      _items.fold(0.0, (value, item) => value + item.totalLinea);

  @override
  void initState() {
    super.initState();
    final factura = widget.initialFactura;

    _fecha = _parseDate(factura?.fecha) ?? DateTime.now();
    _ciudadExpedicionController = TextEditingController(
      text: factura?.ciudadExpedicion?.trim().isNotEmpty == true
          ? factura!.ciudadExpedicion
          : 'Villavicencio, Meta',
    );
    _clienteNombreController =
        TextEditingController(text: factura?.clienteNombre ?? '');
    _clienteNitController =
        TextEditingController(text: factura?.clienteNit ?? '');
    _clienteCiudadController = TextEditingController(
      text: factura?.clienteCiudad?.trim().isNotEmpty == true
          ? factura!.clienteCiudad
          : 'Villavicencio.',
    );
    _clienteContactoController =
        TextEditingController(text: factura?.clienteContacto ?? '');
    _clienteDireccionController =
        TextEditingController(text: factura?.clienteDireccion ?? '');
    _observacionesController =
        TextEditingController(text: factura?.observaciones ?? '');
    _firmaPathController = TextEditingController(
      text: factura?.firmaPath ?? widget.defaultFirmaPath ?? '',
    );
    _firmaNombreController = TextEditingController(
      text: factura?.firmaNombre ??
          widget.defaultFirmaNombre ??
          'María Alejandra Flórez Ocampo.',
    );
    _firmaCargoController = TextEditingController(
      text: factura?.firmaCargo ??
          widget.defaultFirmaCargo ??
          'Representante Legal',
    );
    _firmaEmpresaController = TextEditingController(
      text: factura?.firmaEmpresa ??
          widget.defaultFirmaEmpresa ??
          'Proyecciones eléctricas Tesla.',
    );

    if (factura != null && factura.items.isNotEmpty) {
      for (final item in factura.items) {
        _items.add(_FacturaItemDraft.fromFacturaItem(item));
      }
    } else {
      _items.add(_FacturaItemDraft.empty(orden: 1));
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_initializeData());
    });
  }

  @override
  void dispose() {
    _ciudadExpedicionController.dispose();
    _clienteNombreController.dispose();
    _clienteNitController.dispose();
    _clienteCiudadController.dispose();
    _clienteContactoController.dispose();
    _clienteDireccionController.dispose();
    _observacionesController.dispose();
    _firmaPathController.dispose();
    _firmaNombreController.dispose();
    _firmaCargoController.dispose();
    _firmaEmpresaController.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _initializeData() async {
    if (!mounted) return;

    await _loadServicios();

    final initial = widget.initialFactura;
    if (initial == null) return;

    setState(() => _isLoadingInitial = true);
    try {
      final detalle = await widget.controller.fetchFactura(initial.id);
      if (!mounted) return;
      _hydrateFromFactura(detalle);
    } finally {
      if (mounted) {
        setState(() => _isLoadingInitial = false);
      }
    }
  }

  Future<void> _loadServicios() async {
    if (_isLoadingServicios || !mounted) return;
    setState(() => _isLoadingServicios = true);
    try {
      final servicios =
          await widget.controller.repository.fetchServiciosDisponibles();
      final productos =
          await widget.controller.repository.fetchProductosDisponibles();
      if (!mounted) return;
      setState(() {
        _servicios = servicios;
        _productos = productos;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No fue posible cargar la lista de servicios.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingServicios = false);
      }
    }
  }

  void _hydrateFromFactura(Factura factura) {
    _fecha = _parseDate(factura.fecha) ?? _fecha;
    _ciudadExpedicionController.text =
        (factura.ciudadExpedicion ?? '').trim().isEmpty
            ? _ciudadExpedicionController.text
            : factura.ciudadExpedicion!;
    _clienteNombreController.text = factura.clienteNombre;
    _clienteNitController.text = factura.clienteNit ?? '';
    _clienteCiudadController.text = (factura.clienteCiudad ?? '').trim().isEmpty
        ? 'Villavicencio.'
        : factura.clienteCiudad!;
    _clienteContactoController.text = factura.clienteContacto ?? '';
    _clienteDireccionController.text = factura.clienteDireccion ?? '';
    _observacionesController.text = factura.observaciones ?? '';
    _firmaPathController.text = factura.firmaPath ?? _firmaPathController.text;
    _firmaNombreController.text = (factura.firmaNombre ?? '').trim().isEmpty
        ? _firmaNombreController.text
        : factura.firmaNombre!;
    _firmaCargoController.text = (factura.firmaCargo ?? '').trim().isEmpty
        ? _firmaCargoController.text
        : factura.firmaCargo!;
    _firmaEmpresaController.text = (factura.firmaEmpresa ?? '').trim().isEmpty
        ? _firmaEmpresaController.text
        : factura.firmaEmpresa!;

    for (final item in _items) {
      item.dispose();
    }
    _items
      ..clear()
      ..addAll(
        factura.items.isEmpty
            ? [_FacturaItemDraft.empty(orden: 1)]
            : factura.items.map(_FacturaItemDraft.fromFacturaItem),
      );

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = AdaptiveLayout.isDesktopWidth(constraints.maxWidth);

        return Scaffold(
          backgroundColor: _slate100,
          appBar: AppBar(
            backgroundColor: _slate100,
            foregroundColor: _slate900,
            elevation: 0,
            title: Text(
              widget.readOnly
                  ? 'Detalle de factura'
                  : (_isEditing ? 'Editar factura' : 'Nueva factura'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          body: SafeArea(
            top: false,
            child: _isLoadingInitial
                ? const Center(child: CircularProgressIndicator())
                : Stack(
                    children: [
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Center(
                            child: Opacity(
                              opacity: 0.12,
                              child: FractionallySizedBox(
                                widthFactor: isDesktop ? 0.4 : 0.62,
                                child: Image.asset(_logoTeslaAsset,
                                    fit: BoxFit.contain),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                            isDesktop ? 28 : 16, 8, isDesktop ? 28 : 16, 160),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1140),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildCard(
                                  title: 'Cabecera de la cuenta de cobro',
                                  subtitle:
                                      'Ciudad editable y datos del destinatario.',
                                  child: Column(
                                    children: [
                                      isDesktop
                                          ? Row(children: [
                                              Expanded(
                                                child: _buildTextField(
                                                  controller:
                                                      _ciudadExpedicionController,
                                                  label: 'Ciudad de expedición',
                                                  hintText:
                                                      'Villavicencio, Meta',
                                                  enabled: _canEdit,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                  child: _buildFechaField()),
                                            ])
                                          : Column(children: [
                                              _buildTextField(
                                                controller:
                                                    _ciudadExpedicionController,
                                                label: 'Ciudad de expedición',
                                                hintText: 'Villavicencio, Meta',
                                                enabled: _canEdit,
                                              ),
                                              const SizedBox(height: 12),
                                              _buildFechaField(),
                                            ]),
                                      const SizedBox(height: 12),
                                      _buildTextField(
                                        controller: _clienteNombreController,
                                        label: 'Destinatario',
                                        hintText: 'Nombre persona o empresa',
                                        enabled: _canEdit,
                                      ),
                                      const SizedBox(height: 12),
                                      isDesktop
                                          ? Row(children: [
                                              Expanded(
                                                child: _buildTextField(
                                                  controller:
                                                      _clienteNitController,
                                                  label:
                                                      'NIT / CC destinatario',
                                                  hintText: '822007569-2',
                                                  enabled: _canEdit,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: _buildTextField(
                                                  controller:
                                                      _clienteCiudadController,
                                                  label: 'Ciudad destinatario',
                                                  hintText: 'Villavicencio.',
                                                  enabled: _canEdit,
                                                ),
                                              ),
                                            ])
                                          : Column(children: [
                                              _buildTextField(
                                                controller:
                                                    _clienteNitController,
                                                label: 'NIT / CC destinatario',
                                                hintText: '822007569-2',
                                                enabled: _canEdit,
                                              ),
                                              const SizedBox(height: 12),
                                              _buildTextField(
                                                controller:
                                                    _clienteCiudadController,
                                                label: 'Ciudad destinatario',
                                                hintText: 'Villavicencio.',
                                                enabled: _canEdit,
                                              ),
                                            ]),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 14),
                                _buildCard(
                                  title: 'Detalle de servicios',
                                  subtitle:
                                      'Selecciona servicios del módulo y ajusta cantidad/valor.',
                                  child: Column(
                                    children: [
                                      if (_isLoadingServicios)
                                        const Padding(
                                          padding: EdgeInsets.only(bottom: 10),
                                          child: LinearProgressIndicator(
                                              minHeight: 3),
                                        ),
                                      for (var i = 0;
                                          i < _items.length;
                                          i++) ...[
                                        _buildItemRow(_items[i], i, isDesktop),
                                        if (i < _items.length - 1)
                                          const SizedBox(height: 10),
                                      ],
                                      const SizedBox(height: 12),
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: FilledButton.icon(
                                          onPressed:
                                              _canEdit ? _addItemRow : null,
                                          icon: const Icon(Icons.add_rounded),
                                          label: const Text('Agregar fila'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 14),
                                if (widget.canEditFirma) ...[
                                  _buildCard(
                                    title: 'Firma y notas',
                                    subtitle:
                                        'Esta firma se mostrará en la cuenta de cobro.',
                                    child: _buildFirmaSection(isDesktop),
                                  ),
                                  const SizedBox(height: 14),
                                ],
                                _buildCard(
                                  title: 'Total',
                                  subtitle: 'Se calcula automáticamente.',
                                  child: _metric('Total',
                                      PriceFormatter.formatCopWhole(_subtotal)),
                                ),
                                if (_error != null) ...[
                                  const SizedBox(height: 14),
                                  _errorBanner(_error!),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                  isDesktop ? 28 : 16, 12, isDesktop ? 28 : 16, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: _slate200)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving
                          ? null
                          : () => Navigator.of(context).maybePop(),
                      child: Text(_canEdit ? 'Cancelar' : 'Cerrar'),
                    ),
                  ),
                  if (_canEdit) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _isSaving ? null : _save,
                        child: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : Text(_isEditing
                                ? 'Guardar factura'
                                : 'Crear factura'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildItemRow(_FacturaItemDraft item, int index, bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isDesktop
              ? Row(
                  children: [
                    Text('Item ${index + 1}',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _canEdit ? () => _pickServicio(item) : null,
                      icon: const Icon(Icons.search_rounded),
                      label: const Text('Servicio'),
                    ),
                    TextButton.icon(
                      onPressed: _canEdit ? () => _pickProducto(item) : null,
                      icon: const Icon(Icons.inventory_2_outlined),
                      label: const Text('Producto'),
                    ),
                    IconButton(
                      onPressed: _canEdit ? () => _removeItemRow(index) : null,
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  ],
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Text('Item ${index + 1}',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        onPressed: _canEdit ? () => _pickServicio(item) : null,
                        icon: const Icon(Icons.search_rounded, size: 18),
                        label: const Text('Servicio'),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        onPressed: _canEdit ? () => _pickProducto(item) : null,
                        icon: const Icon(Icons.inventory_2_outlined, size: 18),
                        label: const Text('Producto'),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: _canEdit ? () => _removeItemRow(index) : null,
                        icon: const Icon(Icons.delete_outline_rounded),
                      ),
                    ],
                  ),
                ),
          _buildTextField(
            controller: item.descripcionController,
            label: 'Descripción',
            hintText: 'Descripción del ítem',
            enabled: _canEdit,
            maxLines: 2,
          ),
          const SizedBox(height: 8),
          _buildTextField(
            controller: item.codigoController,
            label: 'Código',
            hintText: 'SER-001 / PRO-001',
            enabled: false,
          ),
          const SizedBox(height: 8),
          if (isDesktop)
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: item.unidadController,
                    label: 'Unid.',
                    hintText: 'Un.',
                    enabled: _canEdit,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _numberField(
                    item.cantidadController,
                    'Cant.',
                    _canEdit,
                    errorText: _stockErrorForItem(item),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                    child: _numberField(
                        item.precioUnitarioController, 'V. Unit', _canEdit)),
                const SizedBox(width: 8),
                Expanded(
                    child: _metric('Total línea',
                        PriceFormatter.formatCopWhole(item.totalLinea))),
              ],
            )
          else ...[
            _buildTextField(
              controller: item.unidadController,
              label: 'Unid.',
              hintText: 'Un.',
              enabled: _canEdit,
            ),
            const SizedBox(height: 8),
            _numberField(
              item.cantidadController,
              'Cant.',
              _canEdit,
              errorText: _stockErrorForItem(item),
            ),
            const SizedBox(height: 8),
            _numberField(item.precioUnitarioController, 'V. Unit', _canEdit),
            const SizedBox(height: 8),
            _metric(
                'Total línea', PriceFormatter.formatCopWhole(item.totalLinea)),
          ],
        ],
      ),
    );
  }

  Widget _numberField(
    TextEditingController c,
    String label,
    bool enabled, {
    String? errorText,
  }) {
    return TextField(
      controller: c,
      enabled: enabled,
      enableInteractiveSelection: true,
      contextMenuBuilder: (context, editableTextState) =>
          AdaptiveTextSelectionToolbar.editableText(
              editableTextState: editableTextState),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        errorText: errorText,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String? _stockErrorForItem(_FacturaItemDraft item) {
    if (item.tipoItem != 'producto' || item.productoId == null) {
      return null;
    }

    Producto? producto;
    for (final candidate in _productos) {
      if (candidate.id == item.productoId) {
        producto = candidate;
        break;
      }
    }
    if (producto == null) {
      return null;
    }

    final cantidad = item.cantidad;
    if (cantidad <= producto.stock) {
      return null;
    }

    return 'Límite de stock superado';
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    bool enabled = true,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      enableInteractiveSelection: true,
      contextMenuBuilder: (context, editableTextState) =>
          AdaptiveTextSelectionToolbar.editableText(
              editableTextState: editableTextState),
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildFechaField() {
    final value = _formatDate(_fecha);
    return InkWell(
      onTap: _canEdit ? _pickFecha : null,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Fecha',
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(value),
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: _slate500, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  color: _slate900, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildCard(
      {required String title,
      required String subtitle,
      required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: _slate500)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _errorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE4E6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDA4AF)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: _rose600),
          const SizedBox(width: 8),
          Expanded(
              child: Text(message, style: const TextStyle(color: _rose600))),
        ],
      ),
    );
  }

  Widget _buildFirmaSection(bool isDesktop) {
    final firmaPath = _firmaPathController.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_canEdit) ...[
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
                        width: 14,
                        height: 14,
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
        ],
        _buildTextField(
          controller: _firmaPathController,
          label: 'Firma digital (URL o ruta)',
          hintText: '/storage/.../firma.png o https://...',
          enabled: _canEdit,
        ),
        const SizedBox(height: 12),
        if (isDesktop)
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _firmaNombreController,
                  label: 'Nombre firma',
                  hintText: 'María Alejandra Flórez Ocampo.',
                  enabled: _canEdit,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _firmaCargoController,
                  label: 'Cargo firma',
                  hintText: 'Representante Legal',
                  enabled: _canEdit,
                ),
              ),
            ],
          )
        else ...[
          _buildTextField(
            controller: _firmaNombreController,
            label: 'Nombre firma',
            hintText: 'María Alejandra Flórez Ocampo.',
            enabled: _canEdit,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _firmaCargoController,
            label: 'Cargo firma',
            hintText: 'Representante Legal',
            enabled: _canEdit,
          ),
        ],
        const SizedBox(height: 12),
        _buildTextField(
          controller: _firmaEmpresaController,
          label: 'Empresa firma',
          hintText: 'Proyecciones eléctricas Tesla.',
          enabled: _canEdit,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _observacionesController,
          label: 'Observaciones',
          hintText: 'Notas opcionales',
          maxLines: 3,
          enabled: _canEdit,
        ),
        if (_canEdit) ...[
          const SizedBox(height: 8),
          CheckboxListTile(
            value: _usarFirmaPredeterminada,
            contentPadding: EdgeInsets.zero,
            dense: true,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text(
              'Colocar firma predeterminada para nuevas cotizaciones',
              style: TextStyle(
                color: _slate900,
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: const Text(
              'No modifica automáticamente cotizaciones viejas ya compartidas.',
              style: TextStyle(color: _slate500),
            ),
            onChanged: _isSaving
                ? null
                : (value) => setState(
                      () => _usarFirmaPredeterminada = value ?? false,
                    ),
          ),
        ],
        const SizedBox(height: 14),
        _buildFirmaGraphic(firmaPath),
      ],
    );
  }

  Widget _buildFirmaGraphic(String firmaPath) {
    final resolvedFirmaPath = _resolveFirmaPathForRender(firmaPath);
    final fallbackName = _firmaNombreController.text.trim().isEmpty
        ? 'María Alejandra Flórez Ocampo.'
        : _firmaNombreController.text.trim();

    if (firmaPath.isEmpty) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text(
          fallbackName,
          style: const TextStyle(
            color: _slate500,
            fontSize: 34,
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
            style: TextStyle(color: _rose600, fontWeight: FontWeight.w600),
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

    final file = File(resolvedFirmaPath);
    if (file.existsSync()) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Image.file(
          file,
          height: 76,
          alignment: Alignment.centerLeft,
          fit: BoxFit.fitHeight,
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        fallbackName,
        style: const TextStyle(
          color: _slate500,
          fontSize: 34,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
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
      final uploadedPath = await widget.controller.repository.uploadFirma(path);
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

  void _addItemRow() => setState(
      () => _items.add(_FacturaItemDraft.empty(orden: _items.length + 1)));

  void _removeItemRow(int index) {
    if (_items.length == 1) {
      _items.first.reset();
      setState(() {});
      return;
    }
    final removed = _items.removeAt(index);
    removed.dispose();
    setState(() {});
  }

  Future<void> _pickServicio(_FacturaItemDraft item) async {
    if (_servicios.isEmpty) {
      setState(() => _error = 'No hay servicios disponibles para seleccionar.');
      return;
    }
    FocusScope.of(context).unfocus();

    final selected = await showDialog<Servicio>(
      context: context,
      builder: (_) => _ServicioPickerDialog(servicios: _servicios),
    );

    if (selected == null || !mounted) return;

    setState(() {
      _error = null;
      item.applyServicio(selected);
    });
  }

  Future<void> _pickProducto(_FacturaItemDraft item) async {
    if (_productos.isEmpty) {
      setState(() => _error = 'No hay productos disponibles para seleccionar.');
      return;
    }
    FocusScope.of(context).unfocus();

    final selected = await showDialog<Producto>(
      context: context,
      builder: (_) => _ProductoPickerDialog(productos: _productos),
    );

    if (selected == null || !mounted) return;

    setState(() {
      _error = null;
      item.applyProducto(selected);
    });
  }

  Future<void> _save() async {
    if (_isSaving) return;

    setState(() => _error = null);
    final validationError = _validateForm();
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }

    final payload = {
      'fecha': _formatDate(_fecha),
      'ciudad_expedicion': _ciudadExpedicionController.text.trim(),
      'cliente_nombre': _clienteNombreController.text.trim(),
      'cliente_nit': _clienteNitController.text.trim(),
      'cliente_ciudad': _clienteCiudadController.text.trim(),
      'cliente_contacto': _clienteContactoController.text.trim(),
      'cliente_direccion': _clienteDireccionController.text.trim(),
      'observaciones': _observacionesController.text.trim(),
      'firma_path': _firmaPathController.text.trim(),
      'firma_nombre': _firmaNombreController.text.trim(),
      'firma_cargo': _firmaCargoController.text.trim(),
      'firma_empresa': _firmaEmpresaController.text.trim(),
      'items': _items.map((e) => e.toPayload()).toList(),
    };

    setState(() => _isSaving = true);
    try {
      final factura = _isEditing
          ? await widget.controller
              .updateFactura(widget.initialFactura!.id, payload)
          : await widget.controller.createFactura(payload);
      if (_canEdit && _usarFirmaPredeterminada) {
        final firmaPath = _firmaPathController.text.trim();
        final firmaNombre = _firmaNombreController.text.trim().isEmpty
            ? 'María Alejandra Flórez Ocampo.'
            : _firmaNombreController.text.trim();
        final firmaCargo = _firmaCargoController.text.trim().isEmpty
            ? 'Representante Legal'
            : _firmaCargoController.text.trim();
        final firmaEmpresa = _firmaEmpresaController.text.trim().isEmpty
            ? 'Proyecciones eléctricas Tesla.'
            : _firmaEmpresaController.text.trim();

        await widget.controller.repository.guardarFirmaPredeterminada(
          firmaPath: firmaPath.isEmpty ? null : firmaPath,
          firmaNombre: firmaNombre,
          firmaCargo: firmaCargo,
          firmaEmpresa: firmaEmpresa,
        );
        widget.onFirmaPredeterminadaActualizada?.call(
          firmaPath: firmaPath.isEmpty ? null : firmaPath,
          firmaNombre: firmaNombre,
          firmaCargo: firmaCargo,
          firmaEmpresa: firmaEmpresa,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(factura);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String? _validateForm() {
    if (_clienteNombreController.text.trim().isEmpty) {
      return 'El destinatario es obligatorio.';
    }
    if (_items.isEmpty) {
      return 'Debes agregar al menos un servicio.';
    }
    for (var i = 0; i < _items.length; i++) {
      final item = _items[i];
      if (item.descripcion.trim().isEmpty) {
        return 'Falta descripción en fila ${i + 1}.';
      }
      if (item.cantidad <= 0) {
        return 'Cantidad inválida en fila ${i + 1}.';
      }
      if (_stockErrorForItem(item) != null) {
        return 'Límite de stock superado en fila ${i + 1}.';
      }
      if (item.precioUnitario < 0) {
        return 'Valor unitario inválido en fila ${i + 1}.';
      }
    }
    return null;
  }

  Future<void> _pickFecha() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (selected == null || !mounted) return;
    setState(() => _fecha = selected);
  }

  String _formatDate(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  DateTime? _parseDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    return DateTime.tryParse(raw);
  }
}

class _FacturaItemDraft {
  _FacturaItemDraft({
    required this.orden,
    required String descripcion,
    required String codigo,
    required String unidad,
    required String cantidad,
    required String precioUnitario,
  })  : codigoController = TextEditingController(text: codigo),
        descripcionController = TextEditingController(text: descripcion),
        unidadController = TextEditingController(text: unidad),
        cantidadController = TextEditingController(text: cantidad),
        precioUnitarioController = TextEditingController(text: precioUnitario);

  factory _FacturaItemDraft.empty({required int orden}) => _FacturaItemDraft(
        orden: orden,
        descripcion: '',
        codigo: '',
        unidad: 'Un.',
        cantidad: '',
        precioUnitario: '',
      );

  factory _FacturaItemDraft.fromFacturaItem(FacturaItem item) =>
      _FacturaItemDraft(
        orden: item.orden,
        descripcion: item.descripcion,
        codigo: item.codigo,
        unidad: item.unidad,
        cantidad: item.cantidad,
        precioUnitario: item.precioUnitario,
      )
        ..tipoItem = item.tipoItem
        ..servicioId = item.servicioId
        ..productoId = item.productoId;

  int orden;
  String tipoItem = 'servicio';
  int? servicioId;
  int? productoId;
  final TextEditingController codigoController;
  final TextEditingController descripcionController;
  final TextEditingController unidadController;
  final TextEditingController cantidadController;
  final TextEditingController precioUnitarioController;

  String get descripcion => descripcionController.text.trim();
  String get codigo => codigoController.text.trim();
  String get unidad => unidadController.text.trim();
  double get cantidad => PriceFormatter.parse(cantidadController.text);
  double get precioUnitario =>
      PriceFormatter.parse(precioUnitarioController.text);
  double get totalLinea => cantidad * precioUnitario;

  void applyServicio(Servicio servicio) {
    tipoItem = 'servicio';
    servicioId = servicio.id;
    productoId = null;
    codigoController.text = servicio.codigo;
    descripcionController.text = servicio.descripcion;
    unidadController.text =
        servicio.unidad.trim().isEmpty ? 'Un.' : servicio.unidad;
    precioUnitarioController.text =
        PriceFormatter.parse(servicio.precioUnitario).toStringAsFixed(0);
    if (cantidadController.text.trim().isEmpty) {
      cantidadController.text = '1';
    }
  }

  void applyProducto(Producto producto) {
    tipoItem = 'producto';
    productoId = producto.id;
    servicioId = null;
    codigoController.text = producto.codigo;
    descripcionController.text = producto.nombre;
    unidadController.text =
        producto.unidadMedida.trim().isEmpty ? 'Un.' : producto.unidadMedida;
    precioUnitarioController.text =
        PriceFormatter.parse(producto.precioVenta).toStringAsFixed(0);
    if (cantidadController.text.trim().isEmpty) {
      cantidadController.text = '1';
    }
  }

  void reset() {
    descripcionController.clear();
    codigoController.clear();
    unidadController.text = 'Un.';
    cantidadController.clear();
    precioUnitarioController.clear();
  }

  Map<String, dynamic> toPayload() => {
        'descripcion': descripcion,
        'tipo_item': tipoItem,
        'servicio_id': servicioId,
        'producto_id': productoId,
        'codigo': codigo,
        'unidad': unidad.isEmpty ? 'Un.' : unidad,
        'cantidad': cantidad,
        'precio_unitario': precioUnitario,
        'iva_porcentaje': 0,
      };

  void dispose() {
    codigoController.dispose();
    descripcionController.dispose();
    unidadController.dispose();
    cantidadController.dispose();
    precioUnitarioController.dispose();
  }
}

class _ProductoPickerDialog extends StatefulWidget {
  const _ProductoPickerDialog({required this.productos});

  final List<Producto> productos;

  @override
  State<_ProductoPickerDialog> createState() => _ProductoPickerDialogState();
}

class _ProductoPickerDialogState extends State<_ProductoPickerDialog> {
  late final TextEditingController _searchController;
  String _query = '';
  String _categoriaSeleccionada = '__all__';

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
    final categorias = <String>{
      for (final producto in widget.productos)
        producto.categoriaNombre.trim().isEmpty
            ? 'Sin categoría'
            : producto.categoriaNombre.trim(),
    }.toList()
      ..sort();

    final filtered = widget.productos.where((producto) {
      final query = _query.trim().toLowerCase();
      final categoriaNombre = producto.categoriaNombre.trim().isEmpty
          ? 'Sin categoría'
          : producto.categoriaNombre.trim();
      final matchesCategoria = _categoriaSeleccionada == '__all__'
          ? true
          : categoriaNombre == _categoriaSeleccionada;
      if (query.isEmpty) return true;
      final matchesBusqueda = producto.nombre.toLowerCase().contains(query) ||
          producto.codigo.toLowerCase().contains(query);
      return matchesCategoria && matchesBusqueda;
    }).where((producto) {
      final categoriaNombre = producto.categoriaNombre.trim().isEmpty
          ? 'Sin categoría'
          : producto.categoriaNombre.trim();
      return _categoriaSeleccionada == '__all__'
          ? true
          : categoriaNombre == _categoriaSeleccionada;
    }).toList();

    return AlertDialog(
      title: const Text('Seleccionar producto'),
      content: SizedBox(
        width: 640,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(
                hintText: 'Buscar producto',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: 10),
            InputDecorator(
              decoration: InputDecoration(
                labelText: 'Categoría',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _categoriaSeleccionada,
                  items: [
                    const DropdownMenuItem(
                      value: '__all__',
                      child: Text('Todas'),
                    ),
                    for (final categoria in categorias)
                      DropdownMenuItem(
                        value: categoria,
                        child: Text(categoria),
                      ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _categoriaSeleccionada = value);
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 320,
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final producto = filtered[index];
                  return ListTile(
                    title: Text(producto.nombre),
                    subtitle: Text(
                      '${producto.codigo} · ${producto.categoriaNombre} · ${producto.unidadMedida} · Stock: ${producto.stock} · ${PriceFormatter.formatCopWhole(producto.precioVenta)}',
                    ),
                    onTap: () => Navigator.of(context).pop(producto),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}

class _ServicioPickerDialog extends StatefulWidget {
  const _ServicioPickerDialog({required this.servicios});

  final List<Servicio> servicios;

  @override
  State<_ServicioPickerDialog> createState() => _ServicioPickerDialogState();
}

class _ServicioPickerDialogState extends State<_ServicioPickerDialog> {
  late final TextEditingController _searchController;
  String _query = '';
  String _categoriaSeleccionada = '__all__';

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
    final categorias = <String>{
      for (final servicio in widget.servicios)
        normalizeServiceCategory(servicio.categoria),
    }.where((categoria) => categoria.isNotEmpty).toList()
      ..sort();

    final filtered = widget.servicios.where((servicio) {
      final term = _query.trim().toLowerCase();
      final categoriaServicio = normalizeServiceCategory(servicio.categoria);
      final matchesCategoria = _categoriaSeleccionada == '__all__'
          ? true
          : categoriaServicio == _categoriaSeleccionada;
      final matchesBusqueda = term.isEmpty
          ? true
          : servicio.descripcion.toLowerCase().contains(term) ||
              servicio.codigo.toLowerCase().contains(term);
      return matchesCategoria && matchesBusqueda;
    }).toList();

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 780, maxHeight: 620),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Seleccionar servicio',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Buscar por código o descripción',
                  prefixIcon: const Icon(Icons.search_rounded),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
              const SizedBox(height: 10),
              InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Categoría',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _categoriaSeleccionada,
                    items: [
                      const DropdownMenuItem(
                        value: '__all__',
                        child: Text('Todas las categorías'),
                      ),
                      for (final categoria in categorias)
                        DropdownMenuItem(
                          value: categoria,
                          child: Text(formatServiceCategoryLabel(categoria)),
                        ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _categoriaSeleccionada = value);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                        child: Text('No hay servicios que coincidan.'))
                    : ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final servicio = filtered[index];
                          return ListTile(
                            title: Text(servicio.descripcion),
                            subtitle: Text(
                              '${servicio.codigo} · ${servicio.unidad} · ${PriceFormatter.formatCopWhole(servicio.precioUnitario)}',
                            ),
                            onTap: () => Navigator.of(context).pop(servicio),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 8),
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
