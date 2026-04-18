import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../cotizaciones/presentation/cotizaciones_screen.dart';
import '../../facturas/presentation/facturas_screen.dart';
import '../../productos/presentation/productos_screen.dart';
import '../../servicios/presentation/servicios_screen.dart';

enum MobileModule {
  dashboard,
  productos,
  servicios,
  cotizaciones,
  facturas,
}

class MobileShellScreen extends StatefulWidget {
  const MobileShellScreen({
    super.key,
    required this.authController,
    this.initialModule = MobileModule.dashboard,
  });

  final AuthController authController;
  final MobileModule initialModule;

  @override
  State<MobileShellScreen> createState() => _MobileShellScreenState();
}

class _MobileShellScreenState extends State<MobileShellScreen> {
  static const _navy = Color(0xFF0F172A);
  static const _navySoft = Color(0xFF1E293B);
  static const _slate500 = Color(0xFF64748B);
  static const _slate100 = Color(0xFFF1F5F9);

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late MobileModule _selectedModule;

  @override
  void initState() {
    super.initState();
    _selectedModule = widget.initialModule;
  }

  @override
  Widget build(BuildContext context) {
    final config = _moduleConfig(_selectedModule);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _slate100,
      drawer: _buildDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _navy,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          icon: const Icon(Icons.menu_rounded),
          tooltip: 'Abrir menu',
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              config.title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            Text(
              config.subtitle,
              style: const TextStyle(
                color: _slate500,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: KeyedSubtree(
        key: ValueKey(_selectedModule),
        child: config.content,
      ),
    );
  }

  Widget _buildDrawer() {
    final items = [
      _MobileNavItem(
        module: MobileModule.dashboard,
        label: 'Dashboard',
        icon: Icons.dashboard_outlined,
      ),
      _MobileNavItem(
        module: MobileModule.productos,
        label: 'Productos',
        icon: Icons.inventory_2_outlined,
      ),
      _MobileNavItem(
        module: MobileModule.servicios,
        label: 'Servicios',
        icon: Icons.design_services_outlined,
      ),
      _MobileNavItem(
        module: MobileModule.cotizaciones,
        label: 'Cotizaciones',
        icon: Icons.request_quote_outlined,
      ),
      _MobileNavItem(
        module: MobileModule.facturas,
        label: 'Facturas',
        icon: Icons.receipt_long_outlined,
      ),
    ];

    return Drawer(
      width: 304,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_navy, _navySoft],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(24),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.bolt_rounded,
                            color: Color(0xFF6EE7B7),
                            size: 28,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Tesla System',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        widget.authController.userName ?? 'Usuario',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.authController.userRole ?? 'Sin rol',
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'NAVEGACION',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _buildDrawerButton(
                        item: item,
                        selected: item.module == _selectedModule,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await widget.authController.logout();
                    },
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Cerrar sesion'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.18)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerButton({
    required _MobileNavItem item,
    required bool selected,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.of(context).pop();
        setState(() => _selectedModule = item.module);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              item.icon,
              size: 20,
              color: selected ? const Color(0xFF6EE7B7) : Colors.white,
            ),
            const SizedBox(width: 12),
            Text(
              item.label,
              style: TextStyle(
                color: Colors.white,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  _MobileModuleConfig _moduleConfig(MobileModule module) {
    switch (module) {
      case MobileModule.dashboard:
        return _MobileModuleConfig(
          title: 'Dashboard',
          subtitle: 'Resumen general',
          content: _MobileDashboardOverview(
            onSelectModule: (nextModule) {
              setState(() => _selectedModule = nextModule);
            },
          ),
        );
      case MobileModule.productos:
        return _MobileModuleConfig(
          title: 'Productos',
          subtitle: 'Catalogo principal',
          content: ProductosScreen(
            authController: widget.authController,
            embedded: true,
          ),
        );
      case MobileModule.servicios:
        return _MobileModuleConfig(
          title: 'Servicios',
          subtitle: 'Modulo operativo',
          content: ServiciosScreen(
            authController: widget.authController,
            embedded: true,
          ),
        );
      case MobileModule.cotizaciones:
        return _MobileModuleConfig(
          title: 'Cotizaciones',
          subtitle: 'Base comercial',
          content: CotizacionesScreen(
            authController: widget.authController,
            embedded: true,
          ),
        );
      case MobileModule.facturas:
        return _MobileModuleConfig(
          title: 'Facturas',
          subtitle: 'Facturación interna',
          content: FacturasScreen(
            authController: widget.authController,
            embedded: true,
          ),
        );
    }
  }
}

class _MobileDashboardOverview extends StatelessWidget {
  const _MobileDashboardOverview({
    required this.onSelectModule,
  });

  final ValueChanged<MobileModule> onSelectModule;

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        title: 'Productos',
        subtitle: 'Administrar catalogo y estados.',
        icon: Icons.inventory_2_outlined,
        module: MobileModule.productos,
      ),
      (
        title: 'Servicios',
        subtitle: 'Consultar servicios.',
        icon: Icons.design_services_outlined,
        module: MobileModule.servicios,
      ),
      (
        title: 'Cotizaciones',
        subtitle: 'Consultar listado, estados y acciones base.',
        icon: Icons.request_quote_outlined,
        module: MobileModule.cotizaciones,
      ),
      (
        title: 'Facturas',
        subtitle: 'Crear, emitir y anular facturas.',
        icon: Icons.receipt_long_outlined,
        module: MobileModule.facturas,
      ),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF134E4A), Color(0xFF0F766E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Inicio movil',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Usa el menu lateral para navegar entre modulos. El inicio muestra accesos visibles a Productos y Servicios.',
                style: TextStyle(
                  color: Color(0xFFE2E8F0),
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        for (final item in items) ...[
          InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => onSelectModule(item.module),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(item.icon, color: const Color(0xFF0F766E)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.subtitle,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF64748B),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _MobileModuleConfig {
  const _MobileModuleConfig({
    required this.title,
    required this.subtitle,
    required this.content,
  });

  final String title;
  final String subtitle;
  final Widget content;
}

class _MobileNavItem {
  const _MobileNavItem({
    required this.module,
    required this.label,
    required this.icon,
  });

  final MobileModule module;
  final String label;
  final IconData icon;
}
