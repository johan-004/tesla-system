import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../shared/utils/price_formatter.dart';
import '../data/productos_repository.dart';
import '../domain/producto_categoria.dart';
import '../domain/producto.dart';

class ProductoFormScreen extends StatefulWidget {
  const ProductoFormScreen({
    super.key,
    required this.repository,
    this.producto,
  });

  final ProductosRepository repository;
  final Producto? producto;

  @override
  State<ProductoFormScreen> createState() => _ProductoFormScreenState();
}

class _ProductoFormScreenState extends State<ProductoFormScreen> {
  static const _slate900 = Color(0xFF0F172A);
  static const _slate800 = Color(0xFF1E293B);
  static const _slate700 = Color(0xFF334155);
  static const _slate500 = Color(0xFF64748B);
  static const _slate300 = Color(0xFFCBD5E1);
  static const _slate200 = Color(0xFFE2E8F0);
  static const _slate100 = Color(0xFFF1F5F9);
  static const _emerald600 = Color(0xFF059669);
  static const _emerald500 = Color(0xFF10B981);
  static const _emerald100 = Color(0xFFD1FAE5);
  static const _rose100 = Color(0xFFFFE4E6);
  static const _rose700 = Color(0xFFBE123C);

  late final TextEditingController _codigoController;
  late final TextEditingController _nombreController;
  late final TextEditingController _precioVentaController;
  late final TextEditingController _ivaPorcentajeController;
  late final TextEditingController _stockController;
  late final TextEditingController _unidadController;
  List<ProductoCategoria> _categorias = const [];
  int? _selectedCategoriaId;
  bool _loadingCategorias = true;
  bool _openingCategoriaDialog = false;
  bool _activo = true;
  bool _saving = false;
  String? _error;

  bool get _isEditing => widget.producto != null;

  String get _screenTitle => _isEditing ? 'Editar producto' : 'Crear producto';
  String get _ctaLabel => _isEditing ? 'Guardar cambios' : 'Crear producto';

  @override
  void initState() {
    super.initState();
    final producto = widget.producto;
    _codigoController = TextEditingController(text: producto?.codigo ?? '');
    _nombreController = TextEditingController(text: producto?.nombre ?? '');
    _precioVentaController = TextEditingController(
      text: producto == null ? '' : PriceFormatter.format(producto.precioVenta),
    );
    _ivaPorcentajeController = TextEditingController(
      text: producto == null
          ? '0'
          : PriceFormatter.format(producto.ivaPorcentaje),
    );
    _stockController =
        TextEditingController(text: producto?.stock.toString() ?? '0');
    _unidadController =
        TextEditingController(text: producto?.unidadMedida ?? 'unidad');
    _selectedCategoriaId = producto?.categoriaId;
    _activo = producto?.activo ?? true;
    _loadCategorias();
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _nombreController.dispose();
    _precioVentaController.dispose();
    _ivaPorcentajeController.dispose();
    _stockController.dispose();
    _unidadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _slate100,
      appBar: AppBar(
        backgroundColor: _slate100,
        foregroundColor: _slate900,
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
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 140),
          children: [
            _buildHeroCard(),
            const SizedBox(height: 16),
            _buildFormCard(),
            const SizedBox(height: 16),
            _buildStatusCard(),
            if (_error != null) ...[
              const SizedBox(height: 16),
              _buildErrorBanner(),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: _slate200)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x120F172A),
                blurRadius: 18,
                offset: Offset(0, -6),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed:
                      _saving ? null : () => Navigator.of(context).maybePop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _slate700,
                    side: BorderSide(color: _saving ? _slate200 : _slate300),
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: _slate900,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _slate300,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _ctaLabel,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [_slate900, _slate800, Color(0xFF065F46)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x260F172A),
            blurRadius: 24,
            offset: Offset(0, 14),
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
            child: Text(
              _isEditing ? 'Edicion movil' : 'Alta movil',
              style: const TextStyle(
                color: Color(0xFFE2E8F0),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.3,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _screenTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isEditing
                ? 'Actualiza la informacion del producto con la misma identidad visual del modulo web.'
                : 'Carga un nuevo producto con una presentacion mas clara, ordenada y coherente con el sistema.',
            style: const TextStyle(
              color: Color(0xFFE2E8F0),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informacion del producto',
            style: TextStyle(
              color: _slate900,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Completa los campos principales con una estructura mas limpia y consistente con productos.',
            style: TextStyle(
              color: _slate500,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          _buildLabeledField(
            label: 'Codigo',
            child: _buildTextField(
              controller: _codigoController,
              hintText: 'Ejemplo: MAT-010',
            ),
          ),
          const SizedBox(height: 16),
          _buildLabeledField(
            label: 'Nombre',
            child: _buildTextField(
              controller: _nombreController,
              hintText: 'Nombre del producto',
            ),
          ),
          const SizedBox(height: 16),
          _buildLabeledField(
            label: 'Categoría',
            child: _buildCategoriaSelector(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildLabeledField(
                  label: 'Precio de venta',
                  child: _buildTextField(
                    controller: _precioVentaController,
                    hintText: '0.00',
                    prefixText: '\$ ',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildLabeledField(
                  label: 'IVA (%)',
                  child: _buildTextField(
                    controller: _ivaPorcentajeController,
                    hintText: '0.00',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildLabeledField(
                  label: 'Stock',
                  child: _buildTextField(
                    controller: _stockController,
                    hintText: '0',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildLabeledField(
            label: 'Unidad de medida',
            child: _buildTextField(
              controller: _unidadController,
              hintText: 'unidad, caja, metro...',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Estado del producto',
                  style: TextStyle(
                    color: _slate900,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _activo
                      ? 'El producto se mostrara como activo dentro del modulo.'
                      : 'El producto quedara guardado como inactivo.',
                  style: const TextStyle(
                    color: _slate500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: _activo,
            activeThumbColor: _emerald600,
            activeTrackColor: _emerald100,
            inactiveThumbColor: _slate700,
            inactiveTrackColor: _slate300,
            onChanged: (value) => setState(() => _activo = value),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _rose100,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFDA4AF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: _rose700),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(
                color: _rose700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabeledField({
    required String label,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _slate700,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
    String? prefixText,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        prefixText: prefixText,
        filled: true,
        fillColor: _slate100,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: _slate300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: _slate300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: _emerald500, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildCategoriaSelector() {
    if (_loadingCategorias) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: _slate100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _slate300),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text('Cargando categorías...'),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: _slate100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _slate300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          isExpanded: true,
          value: _selectedCategoriaId,
          hint: const Text('Selecciona una categoría'),
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text('Sin categoría'),
            ),
            ..._categorias.map(
              (categoria) => DropdownMenuItem<int?>(
                value: categoria.id,
                child: Text(categoria.nombre),
              ),
            ),
            const DropdownMenuItem<int?>(
              value: -1,
              child: Text('+ Crear nueva categoría'),
            ),
          ],
          onChanged: (value) {
            if (value == -1) {
              _openCrearCategoriaModalDeferred();
              return;
            }
            setState(() => _selectedCategoriaId = value);
          },
        ),
      ),
    );
  }

  void _openCrearCategoriaModalDeferred() {
    if (_openingCategoriaDialog) return;
    _openingCategoriaDialog = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 180));
      if (!mounted) {
        _openingCategoriaDialog = false;
        return;
      }
      FocusManager.instance.primaryFocus?.unfocus();
      await _openCrearCategoriaModal();
      _openingCategoriaDialog = false;
    });
  }

  Future<void> _loadCategorias() async {
    setState(() => _loadingCategorias = true);
    try {
      final categorias = await widget.repository.fetchCategorias();
      if (!mounted) return;
      setState(() {
        _categorias = categorias;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'No fue posible cargar las categorías.');
    } finally {
      if (mounted) {
        setState(() => _loadingCategorias = false);
      }
    }
  }

  Future<void> _openCrearCategoriaModal() async {
    final created = await showDialog<ProductoCategoria>(
      context: context,
      builder: (_) => _CreateProductoCategoriaDialog(
        repository: widget.repository,
      ),
    );
    if (!mounted || created == null) return;

    await _loadCategorias();
    if (!mounted) return;
    setState(() => _selectedCategoriaId = created.id);
  }

  Future<void> _save() async {
    final rawPrecio = _precioVentaController.text.trim();
    final rawIva = _ivaPorcentajeController.text.trim();
    if (!PriceFormatter.isValid(rawPrecio)) {
      setState(() {
        _error =
            'Ingresa un precio valido con hasta 2 decimales. Ejemplo: 18,500.00';
      });
      return;
    }
    if (!PriceFormatter.isValid(rawIva)) {
      setState(() {
        _error = 'Ingresa un IVA válido. Ejemplo: 19 o 19.00';
      });
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final precioNormalizado = PriceFormatter.normalize(rawPrecio);
    final ivaNormalizado = PriceFormatter.normalize(rawIva);

    final payload = <String, dynamic>{
      'codigo': _codigoController.text.trim(),
      'nombre': _nombreController.text.trim(),
      'precio_compra': precioNormalizado,
      'precio_venta': precioNormalizado,
      'iva_porcentaje': ivaNormalizado,
      'stock': int.tryParse(_stockController.text.trim()) ?? 0,
      'unidad_medida': _unidadController.text.trim().isEmpty
          ? 'unidad'
          : _unidadController.text.trim(),
      'categoria_id': _selectedCategoriaId,
      'activo': _activo,
    };

    try {
      final producto = _isEditing
          ? await widget.repository.updateProducto(widget.producto!.id, payload)
          : await widget.repository.createProducto(payload);

      if (!mounted) return;
      Navigator.of(context).pop(producto);
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = 'No fue posible guardar el producto.');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}

class _CreateProductoCategoriaDialog extends StatefulWidget {
  const _CreateProductoCategoriaDialog({
    required this.repository,
  });

  final ProductosRepository repository;

  @override
  State<_CreateProductoCategoriaDialog> createState() =>
      _CreateProductoCategoriaDialogState();
}

class _CreateProductoCategoriaDialogState
    extends State<_CreateProductoCategoriaDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _saving = false;
  String? _localError;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final nombre = _controller.text.trim();
    if (nombre.isEmpty) {
      setState(() => _localError = 'El nombre es obligatorio.');
      return;
    }

    setState(() {
      _saving = true;
      _localError = null;
    });

    try {
      final categoria = await widget.repository.createCategoria(nombre);
      if (!mounted) return;
      FocusManager.instance.primaryFocus?.unfocus();
      Navigator.of(context).pop(categoria);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _localError = error.message;
        _saving = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _localError = 'No fue posible crear la categoría.';
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Nueva categoría',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      content: TextField(
        controller: _controller,
        autofocus: false,
        decoration: InputDecoration(
          hintText: 'Nombre de la categoría',
          errorText: _localError,
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving
              ? null
              : () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  Navigator.of(context).pop();
                },
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }
}
