import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/layout/adaptive_layout.dart';
import '../../../shared/utils/price_formatter.dart';
import '../../productos/domain/producto.dart';
import '../domain/factura.dart';
import '../domain/factura_item.dart';
import '../facturas_controller.dart';

const _logoTeslaAsset = 'assets/images/logo_tesla.png';
const _marcaAguaTeslaAsset = 'assets/images/marca_agua_tesla.png';

class FacturaFormScreen extends StatefulWidget {
  const FacturaFormScreen({
    super.key,
    required this.controller,
    required this.canEditFacturacion,
    this.initialFactura,
    this.readOnly = false,
  });

  final FacturasController controller;
  final Factura? initialFactura;
  final bool canEditFacturacion;
  final bool readOnly;

  @override
  State<FacturaFormScreen> createState() => _FacturaFormScreenState();
}

class _FacturaFormScreenState extends State<FacturaFormScreen> {
  static const _slate900 = Color(0xFF0F172A);
  static const _slate700 = Color(0xFF334155);
  static const _slate500 = Color(0xFF64748B);
  static const _slate300 = Color(0xFFCBD5E1);
  static const _slate200 = Color(0xFFE2E8F0);
  static const _slate100 = Color(0xFFF1F5F9);
  static const _rose600 = Color(0xFFE11D48);

  late final TextEditingController _clienteNombreController;
  late final TextEditingController _clienteNitController;
  late final TextEditingController _clienteContactoController;
  late final TextEditingController _clienteDireccionController;
  late final TextEditingController _observacionesController;

  final List<_FacturaItemDraft> _items = [];

  DateTime _fecha = DateTime.now();
  bool _isSaving = false;
  bool _isLoadingInitial = false;
  bool _isLoadingCatalogo = false;
  String? _error;
  String? _catalogoError;

  bool get _isEditing => widget.initialFactura != null;
  String get _title {
    if (widget.readOnly) {
      return 'Detalle de factura';
    }

    return _isEditing ? 'Editar factura' : 'Nueva factura';
  }

  bool get _isReadonlyByState {
    final factura = widget.initialFactura;
    if (factura == null) {
      return false;
    }

    return !factura.isBorrador;
  }

  bool get _canEdit =>
      widget.canEditFacturacion && !_isReadonlyByState && !widget.readOnly;

  List<Producto> get _productos => widget.controller.state.catalogoProductos;

  double get _subtotal =>
      _items.fold(0.0, (value, item) => value + item.subtotalLinea);
  double get _ivaTotal =>
      _items.fold(0.0, (value, item) => value + item.ivaValor);
  double get _total =>
      _items.fold(0.0, (value, item) => value + item.totalLinea);

  @override
  void initState() {
    super.initState();
    final factura = widget.initialFactura;

    _fecha = _parseDate(factura?.fecha) ?? DateTime.now();
    _clienteNombreController =
        TextEditingController(text: factura?.clienteNombre ?? '');
    _clienteNitController =
        TextEditingController(text: factura?.clienteNit ?? '');
    _clienteContactoController =
        TextEditingController(text: factura?.clienteContacto ?? '');
    _clienteDireccionController =
        TextEditingController(text: factura?.clienteDireccion ?? '');
    _observacionesController =
        TextEditingController(text: factura?.observaciones ?? '');

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
    _clienteNombreController.dispose();
    _clienteNitController.dispose();
    _clienteContactoController.dispose();
    _clienteDireccionController.dispose();
    _observacionesController.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _initializeData() async {
    if (!mounted) {
      return;
    }

    await _loadProductos();

    final initial = widget.initialFactura;
    if (initial == null) {
      return;
    }

    setState(() => _isLoadingInitial = true);
    try {
      final detalle = await widget.controller.fetchFactura(initial.id);
      if (!mounted) {
        return;
      }

      _hydrateFromFactura(detalle);
    } catch (_) {
      if (!mounted) {
        return;
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingInitial = false);
      }
    }
  }

  Future<void> _loadProductos() async {
    if (!mounted || _isLoadingCatalogo) {
      return;
    }

    setState(() {
      _isLoadingCatalogo = true;
      _catalogoError = null;
    });

    try {
      await widget.controller.ensureCatalogoProductosLoaded(
        notifyListeners: false,
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingCatalogo = false;
        _syncItemsWithCatalogo();
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingCatalogo = false;
        _catalogoError =
            'No fue posible cargar productos. Cierra y abre la pantalla para reintentar.';
      });
    }
  }

  void _hydrateFromFactura(Factura factura) {
    _fecha = _parseDate(factura.fecha) ?? _fecha;
    _clienteNombreController.text = factura.clienteNombre;
    _clienteNitController.text = factura.clienteNit ?? '';
    _clienteContactoController.text = factura.clienteContacto ?? '';
    _clienteDireccionController.text = factura.clienteDireccion ?? '';
    _observacionesController.text = factura.observaciones ?? '';

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

    _syncItemsWithCatalogo();
    setState(() {});
  }

  void _syncItemsWithCatalogo() {
    if (_productos.isEmpty) {
      return;
    }

    for (final item in _items) {
      final match = _findProductoById(item.productoId);
      if (match != null) {
        item.applyProducto(match, preserveCantidad: true);
      }
    }
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
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            title: Text(
              _title,
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
                              opacity: 0.07,
                              child: FractionallySizedBox(
                                widthFactor: isDesktop ? 0.34 : 0.55,
                                heightFactor: 0.48,
                                child: Image.asset(
                                  _marcaAguaTeslaAsset,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          isDesktop ? 28 : 16,
                          8,
                          isDesktop ? 28 : 16,
                          160,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1120),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildHero(isDesktop),
                                const SizedBox(height: 16),
                                _buildClienteCard(isDesktop),
                                const SizedBox(height: 16),
                                _buildItemsCard(isDesktop),
                                const SizedBox(height: 16),
                                _buildTotalsCard(isDesktop),
                                if (_catalogoError != null) ...[
                                  const SizedBox(height: 16),
                                  _buildErrorBanner(_catalogoError!),
                                ],
                                if (_error != null) ...[
                                  const SizedBox(height: 16),
                                  _buildErrorBanner(_error!),
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
                isDesktop ? 28 : 16,
                12,
                isDesktop ? 28 : 16,
                16,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                border: const Border(top: BorderSide(color: _slate200)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x120F172A),
                    blurRadius: 18,
                    offset: Offset(0, -6),
                  ),
                ],
              ),
              child: _buildBottomActions(isDesktop),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHero(bool isDesktop) {
    final factura = widget.initialFactura;
    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _slate200),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                _logoTeslaAsset,
                height: isDesktop ? 52 : 44,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _slate100,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: _slate200),
                  ),
                  child: Text(
                    widget.readOnly
                        ? 'Detalle solo lectura'
                        : (_isEditing
                            ? 'Edicion de factura'
                            : 'Nueva facturacion'),
                    style: const TextStyle(
                      color: _slate700,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            factura == null ? 'Factura comercial' : 'Factura ${factura.codigo}',
            style: TextStyle(
              color: _slate900,
              fontSize: isDesktop ? 30 : 25,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _canEdit
                ? 'Selecciona productos del catalogo, ingresa cantidades y el sistema calcula IVA y totales automaticamente.'
                : 'Esta factura esta en estado ${factura?.estado ?? ''} y solo permite consulta.',
            style: const TextStyle(
              color: _slate700,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClienteCard(bool isDesktop) {
    return _Card(
      title: 'Datos del cliente',
      subtitle: 'Nombre, identificación, contacto y fecha de factura.',
      child: Column(
        children: [
          isDesktop
              ? Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _clienteNombreController,
                        label: 'Cliente',
                        hintText: 'Nombre o razón social',
                        enabled: _canEdit,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: _clienteNitController,
                        label: 'NIT / Documento',
                        hintText: '901234567-1',
                        enabled: _canEdit,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: _buildFechaField()),
                  ],
                )
              : Column(
                  children: [
                    _buildTextField(
                      controller: _clienteNombreController,
                      label: 'Cliente',
                      hintText: 'Nombre o razón social',
                      enabled: _canEdit,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _clienteNitController,
                      label: 'NIT / Documento',
                      hintText: '901234567-1',
                      enabled: _canEdit,
                    ),
                    const SizedBox(height: 12),
                    _buildFechaField(),
                  ],
                ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _clienteContactoController,
            label: 'Contacto',
            hintText: 'Nombre o teléfono de contacto',
            enabled: _canEdit,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _clienteDireccionController,
            label: 'Dirección',
            hintText: 'Dirección del cliente',
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
        ],
      ),
    );
  }

  Widget _buildItemsCard(bool isDesktop) {
    return _Card(
      title: 'Detalle de productos',
      subtitle:
          'El usuario solo define cantidad. Precio e IVA se autocompletan.',
      child: Column(
        children: [
          if (_isLoadingCatalogo)
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: LinearProgressIndicator(minHeight: 3),
            ),
          for (var i = 0; i < _items.length; i++) ...[
            _buildItemRow(_items[i], i, isDesktop),
            if (i < _items.length - 1) const SizedBox(height: 10),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: _canEdit ? _addItemRow : null,
              style: FilledButton.styleFrom(
                backgroundColor: _slate900,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Agregar fila',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(_FacturaItemDraft item, int index, bool isDesktop) {
    final stock = _findProductoById(item.productoId)?.stock;
    final stockText = stock == null ? '' : 'Stock: $stock';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Item ${index + 1}',
                style: const TextStyle(
                  color: _slate700,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (stockText.isNotEmpty) ...[
                const SizedBox(width: 10),
                Text(stockText, style: const TextStyle(color: _slate500)),
              ],
              const Spacer(),
              IconButton(
                onPressed: _canEdit ? () => _removeItemRow(index) : null,
                icon: const Icon(Icons.delete_outline_rounded),
                tooltip: 'Eliminar fila',
              ),
            ],
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _canEdit ? () => _selectProducto(item) : null,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _slate300),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.displayLabel,
                      style: TextStyle(
                        color: item.productoId == null ? _slate500 : _slate900,
                        fontWeight: item.productoId == null
                            ? FontWeight.w500
                            : FontWeight.w700,
                      ),
                    ),
                  ),
                  const Icon(Icons.search_rounded, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (isDesktop)
            Row(
              children: [
                Expanded(
                  child: _buildReadOnlyMetric(
                    label: 'Precio unitario',
                    value: PriceFormatter.formatCopLatino(item.precioUnitario),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildReadOnlyMetric(
                    label: 'IVA %',
                    value: '${item.ivaPorcentaje.toStringAsFixed(2)}%',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildCantidadField(item),
                ),
              ],
            )
          else ...[
            _buildReadOnlyMetric(
              label: 'Precio unitario',
              value: PriceFormatter.formatCopLatino(item.precioUnitario),
            ),
            const SizedBox(height: 8),
            _buildReadOnlyMetric(
              label: 'IVA %',
              value: '${item.ivaPorcentaje.toStringAsFixed(2)}%',
            ),
            const SizedBox(height: 8),
            _buildCantidadField(item),
          ],
          const SizedBox(height: 10),
          if (isDesktop)
            Row(
              children: [
                Expanded(
                  child: _buildReadOnlyMetric(
                    label: 'Subtotal línea',
                    value: PriceFormatter.formatCopLatino(item.subtotalLinea),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildReadOnlyMetric(
                    label: 'IVA línea',
                    value: PriceFormatter.formatCopLatino(item.ivaValor),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildReadOnlyMetric(
                    label: 'Total línea',
                    value: PriceFormatter.formatCopLatino(item.totalLinea),
                  ),
                ),
              ],
            )
          else ...[
            _buildReadOnlyMetric(
              label: 'Subtotal línea',
              value: PriceFormatter.formatCopLatino(item.subtotalLinea),
            ),
            const SizedBox(height: 8),
            _buildReadOnlyMetric(
              label: 'IVA línea',
              value: PriceFormatter.formatCopLatino(item.ivaValor),
            ),
            const SizedBox(height: 8),
            _buildReadOnlyMetric(
              label: 'Total línea',
              value: PriceFormatter.formatCopLatino(item.totalLinea),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCantidadField(_FacturaItemDraft item) {
    return TextField(
      controller: item.cantidadController,
      enabled: _canEdit,
      keyboardType: const TextInputType.numberWithOptions(decimal: false),
      decoration: InputDecoration(
        labelText: 'Cantidad',
        hintText: '0',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _slate300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _slate300),
        ),
      ),
      onChanged: (_) {
        setState(() {});
      },
    );
  }

  Widget _buildTotalsCard(bool isDesktop) {
    return _Card(
      title: 'Resumen de factura',
      subtitle: 'Cálculo automático desde backend y vista previa local.',
      child: isDesktop
          ? Row(
              children: [
                Expanded(
                  child: _buildReadOnlyMetric(
                    label: 'Subtotal',
                    value: PriceFormatter.formatCopLatino(_subtotal),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildReadOnlyMetric(
                    label: 'IVA total',
                    value: PriceFormatter.formatCopLatino(_ivaTotal),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildReadOnlyMetric(
                    label: 'Total',
                    value: PriceFormatter.formatCopLatino(_total),
                  ),
                ),
              ],
            )
          : Column(
              children: [
                _buildReadOnlyMetric(
                  label: 'Subtotal',
                  value: PriceFormatter.formatCopLatino(_subtotal),
                ),
                const SizedBox(height: 10),
                _buildReadOnlyMetric(
                  label: 'IVA total',
                  value: PriceFormatter.formatCopLatino(_ivaTotal),
                ),
                const SizedBox(height: 10),
                _buildReadOnlyMetric(
                  label: 'Total',
                  value: PriceFormatter.formatCopLatino(_total),
                ),
              ],
            ),
    );
  }

  Widget _buildBottomActions(bool isDesktop) {
    final children = [
      Expanded(
        child: OutlinedButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).maybePop(),
          style: OutlinedButton.styleFrom(
            foregroundColor: _slate700,
            side: const BorderSide(color: _slate300),
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: Text(
            _canEdit ? 'Cancelar' : 'Cerrar',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
      if (_canEdit) ...[
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: _isSaving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: _slate900,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    _isEditing ? 'Guardar factura' : 'Crear factura',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
          ),
        ),
      ],
    ];

    if (isDesktop) {
      return Row(children: children);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [Row(children: children)],
    );
  }

  Widget _buildFechaField() {
    final value = _formatDate(_fecha);
    return InkWell(
      onTap: _canEdit ? _pickFecha : null,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Fecha',
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _slate300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _slate300),
          ),
        ),
        child: Text(value),
      ),
    );
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
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _slate300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _slate300),
        ),
      ),
    );
  }

  Widget _buildReadOnlyMetric({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _slate500,
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

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE4E6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFDA4AF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: _rose600),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: _rose600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
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

  void _addItemRow() {
    setState(() {
      _items.add(_FacturaItemDraft.empty(orden: _items.length + 1));
    });
  }

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

  Future<void> _selectProducto(_FacturaItemDraft item) async {
    if (_productos.isEmpty) {
      setState(() {
        _error =
            'No hay productos disponibles para facturar. Verifica el catálogo.';
      });
      return;
    }

    final selected = await showDialog<Producto>(
      context: context,
      builder: (_) => _ProductoPickerDialog(productos: _productos),
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _error = null;
      item.applyProducto(selected);
    });
  }

  Future<void> _save() async {
    if (_isSaving) {
      return;
    }

    setState(() {
      _error = null;
    });

    final validationError = _validateForm();
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }

    final payload = _buildPayload();

    setState(() => _isSaving = true);
    try {
      Factura factura;
      if (_isEditing) {
        factura = await widget.controller
            .updateFactura(widget.initialFactura!.id, payload);
      } else {
        factura = await widget.controller.createFactura(payload);
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(factura);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error.message;
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
        setState(() => _isSaving = false);
      }
    }
  }

  String? _validateForm() {
    if (_clienteNombreController.text.trim().isEmpty) {
      return 'El nombre del cliente es obligatorio.';
    }

    if (_items.isEmpty) {
      return 'La factura debe tener al menos un item.';
    }

    for (var i = 0; i < _items.length; i++) {
      final item = _items[i];
      final cantidad = item.cantidad;
      if (item.productoId == null) {
        return 'Selecciona un producto para la fila ${i + 1}.';
      }
      if (cantidad <= 0) {
        return 'La cantidad debe ser mayor que cero en la fila ${i + 1}.';
      }
      if (cantidad != cantidad.roundToDouble()) {
        return 'La cantidad debe ser un número entero en la fila ${i + 1}.';
      }
    }

    return null;
  }

  Producto? _findProductoById(int? id) {
    if (id == null) {
      return null;
    }

    for (final producto in _productos) {
      if (producto.id == id) {
        return producto;
      }
    }

    return null;
  }

  Map<String, dynamic> _buildPayload() {
    return {
      'fecha': _formatDate(_fecha),
      'cliente_nombre': _clienteNombreController.text.trim(),
      'cliente_nit': _clienteNitController.text.trim(),
      'cliente_contacto': _clienteContactoController.text.trim(),
      'cliente_direccion': _clienteDireccionController.text.trim(),
      'observaciones': _observacionesController.text.trim(),
      'items': _items.map((item) => item.toPayload()).toList(),
    };
  }

  String _formatDate(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  DateTime? _parseDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    return DateTime.tryParse(raw);
  }
}

class _Card extends StatelessWidget {
  const _Card({
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _ProductoPickerDialog extends StatefulWidget {
  const _ProductoPickerDialog({
    required this.productos,
  });

  final List<Producto> productos;

  @override
  State<_ProductoPickerDialog> createState() => _ProductoPickerDialogState();
}

class _ProductoPickerDialogState extends State<_ProductoPickerDialog> {
  late final TextEditingController _searchController;
  String _query = '';

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
    final filtered = widget.productos.where((producto) {
      final term = _query.trim().toLowerCase();
      if (term.isEmpty) {
        return true;
      }

      return producto.codigo.toLowerCase().contains(term) ||
          producto.nombre.toLowerCase().contains(term);
    }).toList();

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
                'Seleccionar producto',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Busca por código o nombre para cargar la fila automáticamente.',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Buscar producto',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF0F172A)),
                  ),
                ),
                onChanged: (value) {
                  if (!mounted) {
                    return;
                  }
                  setState(() => _query = value);
                },
              ),
              const SizedBox(height: 14),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: filtered.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'No hay productos que coincidan con la búsqueda.',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final producto = filtered[index];
                            return ListTile(
                              title: Text(
                                producto.nombre,
                                style: const TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                '${producto.codigo} · ${producto.unidadMedida} · Stock ${producto.stock} · ${PriceFormatter.formatCopLatino(producto.precioVenta)} · IVA ${PriceFormatter.parse(producto.ivaPorcentaje).toStringAsFixed(2)}%',
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              onTap: () => Navigator.of(context).pop(producto),
                            );
                          },
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

class _FacturaItemDraft {
  _FacturaItemDraft({
    required this.orden,
    required this.productoId,
    required this.productoCodigo,
    required this.productoNombre,
    required this.descripcion,
    required this.unidad,
    required this.precioUnitario,
    required this.ivaPorcentaje,
    required String cantidad,
  }) : cantidadController = TextEditingController(text: cantidad);

  factory _FacturaItemDraft.empty({required int orden}) {
    return _FacturaItemDraft(
      orden: orden,
      productoId: null,
      productoCodigo: '',
      productoNombre: '',
      descripcion: '',
      unidad: '',
      precioUnitario: 0,
      ivaPorcentaje: 0,
      cantidad: '',
    );
  }

  factory _FacturaItemDraft.fromFacturaItem(FacturaItem item) {
    return _FacturaItemDraft(
      orden: item.orden,
      productoId: item.productoId,
      productoCodigo: '',
      productoNombre: item.descripcion,
      descripcion: item.descripcion,
      unidad: item.unidad,
      precioUnitario: PriceFormatter.parse(item.precioUnitario),
      ivaPorcentaje: PriceFormatter.parse(item.ivaPorcentaje),
      cantidad: _formatCantidad(item.cantidad),
    );
  }

  int orden;
  int? productoId;
  String productoCodigo;
  String productoNombre;
  String descripcion;
  String unidad;
  double precioUnitario;
  double ivaPorcentaje;
  final TextEditingController cantidadController;

  String get displayLabel {
    if (productoId == null) {
      return 'Seleccionar producto';
    }

    final code = productoCodigo.trim().isEmpty ? '' : '$productoCodigo · ';
    return '$code${productoNombre.trim().isEmpty ? descripcion : productoNombre}';
  }

  double get cantidad => PriceFormatter.parse(cantidadController.text);

  double get subtotalLinea => cantidad * precioUnitario;

  double get ivaValor => subtotalLinea * (ivaPorcentaje / 100);

  double get totalLinea => subtotalLinea + ivaValor;

  void applyProducto(Producto producto, {bool preserveCantidad = false}) {
    productoId = producto.id;
    productoCodigo = producto.codigo;
    productoNombre = producto.nombre;
    descripcion = producto.nombre;
    unidad = producto.unidadMedida;
    precioUnitario = PriceFormatter.parse(producto.precioVenta);
    ivaPorcentaje = PriceFormatter.parse(producto.ivaPorcentaje);
    if (!preserveCantidad && cantidadController.text.trim().isEmpty) {
      cantidadController.text = '';
    }
  }

  void reset() {
    productoId = null;
    productoCodigo = '';
    productoNombre = '';
    descripcion = '';
    unidad = '';
    precioUnitario = 0;
    ivaPorcentaje = 0;
    cantidadController.clear();
  }

  Map<String, dynamic> toPayload() {
    final cantidadValue = cantidad.round();
    return {
      'producto_id': productoId,
      'cantidad': cantidadValue,
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
