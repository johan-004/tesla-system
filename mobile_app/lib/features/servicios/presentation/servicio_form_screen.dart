import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../shared/utils/price_formatter.dart';
import '../data/servicios_repository.dart';
import '../domain/servicio.dart';

class ServicioFormScreen extends StatefulWidget {
  const ServicioFormScreen({
    super.key,
    required this.repository,
    this.servicio,
  });

  final ServiciosRepository repository;
  final Servicio? servicio;

  @override
  State<ServicioFormScreen> createState() => _ServicioFormScreenState();
}

class _ServicioFormScreenState extends State<ServicioFormScreen> {
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
  late final TextEditingController _descripcionController;
  late final TextEditingController _categoriaController;
  late final TextEditingController _unidadController;
  late final TextEditingController _precioUnitarioController;
  late final TextEditingController _ivaController;
  late final TextEditingController _precioConIvaController;
  late final TextEditingController _observacionesController;
  bool _activo = true;
  bool _saving = false;
  String? _error;

  bool get _isEditing => widget.servicio != null;

  String get _screenTitle => _isEditing ? 'Editar servicio' : 'Crear servicio';
  String get _ctaLabel => _isEditing ? 'Guardar cambios' : 'Crear servicio';

  @override
  void initState() {
    super.initState();
    final servicio = widget.servicio;
    _codigoController = TextEditingController(text: servicio?.codigo ?? '');
    _descripcionController =
        TextEditingController(text: servicio?.descripcion ?? '');
    _categoriaController =
        TextEditingController(text: servicio?.categoria ?? 'residencial');
    _unidadController =
        TextEditingController(text: servicio?.unidad ?? 'servicio');
    _precioUnitarioController = TextEditingController(
      text: servicio == null
          ? ''
          : PriceFormatter.format(servicio.precioUnitario),
    );
    _ivaController = TextEditingController(
      text: servicio == null ? '' : PriceFormatter.format(servicio.iva),
    );
    _precioConIvaController = TextEditingController(
      text:
          servicio == null ? '' : PriceFormatter.format(servicio.precioConIva),
    );
    _observacionesController =
        TextEditingController(text: servicio?.observaciones ?? '');
    _activo = servicio?.activo ?? true;
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _descripcionController.dispose();
    _categoriaController.dispose();
    _unidadController.dispose();
    _precioUnitarioController.dispose();
    _ivaController.dispose();
    _precioConIvaController.dispose();
    _observacionesController.dispose();
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
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
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
          colors: [_slate900, _slate800, Color(0xFF14532D)],
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
          const Text(
            'Administra el catalogo de servicios sin logica de cotizaciones: datos claros, secciones definidas y precios gestionados manualmente.',
            style: TextStyle(
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
            'Informacion del servicio',
            style: TextStyle(
              color: _slate900,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Guarda codigo, descripcion, categoria, unidad y precios como valores definidos por la empresa.',
            style: TextStyle(color: _slate500, height: 1.4),
          ),
          const SizedBox(height: 18),
          _buildLabeledField(
            label: 'Codigo',
            child: _buildTextField(
              controller: _codigoController,
              hintText: 'Ejemplo: SER-010',
            ),
          ),
          const SizedBox(height: 16),
          _buildLabeledField(
            label: 'Descripcion',
            child: _buildTextField(
              controller: _descripcionController,
              hintText: 'Describe el servicio ofrecido',
              maxLines: 3,
            ),
          ),
          const SizedBox(height: 16),
          _buildLabeledField(
            label: 'Categoria o seccion',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField(
                  controller: _categoriaController,
                  hintText: 'residencial, comercial...',
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final categoria in suggestedServiceCategories)
                      ActionChip(
                        label: Text(categoria),
                        onPressed: () {
                          setState(() {
                            _categoriaController.text = categoria;
                          });
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildLabeledField(
            label: 'Unidad',
            child: _buildTextField(
              controller: _unidadController,
              hintText: 'servicio, visita, hora...',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildLabeledField(
                  label: 'Precio unitario',
                  child: _buildTextField(
                    controller: _precioUnitarioController,
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
                  label: 'IVA',
                  child: _buildTextField(
                    controller: _ivaController,
                    hintText: '0.00',
                    prefixText: '\$ ',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildLabeledField(
            label: 'Precio con IVA',
            child: _buildTextField(
              controller: _precioConIvaController,
              hintText: '0.00',
              prefixText: '\$ ',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildLabeledField(
            label: 'Observaciones',
            child: _buildTextField(
              controller: _observacionesController,
              hintText: 'Notas internas u observaciones visibles del servicio',
              maxLines: 4,
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
                  'Estado del servicio',
                  style: TextStyle(
                    color: _slate900,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _activo
                      ? 'El servicio aparecera como activo en el catalogo.'
                      : 'El servicio quedara guardado como inactivo.',
                  style: const TextStyle(color: _slate500, height: 1.4),
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
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
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

  Future<void> _save() async {
    final errors = <String>[];
    final rawPrecioUnitario = _precioUnitarioController.text.trim();
    final rawIva = _ivaController.text.trim();
    final rawPrecioConIva = _precioConIvaController.text.trim();

    if (_codigoController.text.trim().isEmpty) {
      errors.add('El codigo es obligatorio.');
    }
    if (_descripcionController.text.trim().isEmpty) {
      errors.add('La descripcion es obligatoria.');
    }
    if (_categoriaController.text.trim().isEmpty) {
      errors.add('La categoria o seccion es obligatoria.');
    }
    if (_unidadController.text.trim().isEmpty) {
      errors.add('La unidad es obligatoria.');
    }
    if (!PriceFormatter.isValid(rawPrecioUnitario)) {
      errors.add('Ingresa un precio unitario valido.');
    }
    if (!PriceFormatter.isValid(rawIva)) {
      errors.add('Ingresa un IVA valido.');
    }
    if (!PriceFormatter.isValid(rawPrecioConIva)) {
      errors.add('Ingresa un precio con IVA valido.');
    }

    if (errors.isNotEmpty) {
      setState(() => _error = errors.join(' '));
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final payload = <String, dynamic>{
      'codigo': _codigoController.text.trim(),
      'descripcion': _descripcionController.text.trim(),
      'categoria': _categoriaController.text.trim(),
      'unidad': _unidadController.text.trim(),
      'precio_unitario': PriceFormatter.normalize(rawPrecioUnitario),
      'iva': PriceFormatter.normalize(rawIva),
      'precio_con_iva': PriceFormatter.normalize(rawPrecioConIva),
      'observaciones': _observacionesController.text.trim().isEmpty
          ? null
          : _observacionesController.text.trim(),
      'activo': _activo,
    };

    try {
      final servicio = _isEditing
          ? await widget.repository.updateServicio(widget.servicio!.id, payload)
          : await widget.repository.createServicio(payload);

      if (!mounted) return;
      Navigator.of(context).pop(servicio);
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = 'No fue posible guardar el servicio.');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}
