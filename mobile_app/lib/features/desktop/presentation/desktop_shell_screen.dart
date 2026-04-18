import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../cotizaciones/presentation/cotizaciones_screen.dart';
import '../../facturas/presentation/facturas_screen.dart';
import '../../productos/presentation/productos_screen.dart';
import '../../servicios/presentation/servicios_screen.dart';

enum DesktopModule {
  dashboard,
  productos,
  servicios,
  cotizaciones,
  facturas,
}

class DesktopShellScreen extends StatefulWidget {
  const DesktopShellScreen({
    super.key,
    required this.authController,
    this.initialModule = DesktopModule.dashboard,
  });

  final AuthController authController;
  final DesktopModule initialModule;

  @override
  State<DesktopShellScreen> createState() => _DesktopShellScreenState();
}

class _DesktopShellScreenState extends State<DesktopShellScreen> {
  static const _sidebarWidth = 264.0;
  static const _topBarHeight = 92.0;
  static const _navy = Color(0xFF0F172A);
  static const _navySoft = Color(0xFF1E293B);
  static const _slate700 = Color(0xFF334155);
  static const _slate500 = Color(0xFF64748B);
  static const _slate200 = Color(0xFFE2E8F0);
  static const _slate100 = Color(0xFFF1F5F9);

  late DesktopModule _selectedModule;
  bool _isSidebarOpen = false;

  @override
  void initState() {
    super.initState();
    _selectedModule = widget.initialModule;
  }

  @override
  Widget build(BuildContext context) {
    final config = _moduleConfig(_selectedModule);

    return Scaffold(
      backgroundColor: _slate100,
      body: Stack(
        children: [
          Column(
            children: [
              _buildTopBar(config),
              Expanded(
                child: ColoredBox(
                  color: _slate100,
                  child: KeyedSubtree(
                    key: ValueKey(_selectedModule),
                    child: config.content,
                  ),
                ),
              ),
            ],
          ),
          if (_isSidebarOpen)
            Positioned.fill(
              top: _topBarHeight,
              child: GestureDetector(
                onTap: _toggleSidebar,
                child: Container(
                  color: const Color(0x660F172A),
                ),
              ),
            ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            top: 0,
            bottom: 0,
            left: _isSidebarOpen ? 0 : -_sidebarWidth,
            child: _buildSidebar(),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    final items = [
      _DesktopNavItem(
        module: DesktopModule.dashboard,
        label: 'Dashboard',
        icon: Icons.dashboard_outlined,
      ),
      _DesktopNavItem(
        module: DesktopModule.productos,
        label: 'Productos',
        icon: Icons.inventory_2_outlined,
      ),
      _DesktopNavItem(
        module: DesktopModule.servicios,
        label: 'Servicios',
        icon: Icons.design_services_outlined,
      ),
      _DesktopNavItem(
        module: DesktopModule.cotizaciones,
        label: 'Cotizaciones',
        icon: Icons.request_quote_outlined,
      ),
      _DesktopNavItem(
        module: DesktopModule.facturas,
        label: 'Facturas',
        icon: Icons.receipt_long_outlined,
      ),
    ];

    return Container(
      width: _sidebarWidth,
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_navy, _navySoft],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.bolt_rounded,
                        color: Color(0xFF6EE7B7), size: 28),
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
                return _buildSidebarButton(
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
              onPressed: () async => widget.authController.logout(),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Cerrar sesion'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarButton({
    required _DesktopNavItem item,
    required bool selected,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => setState(() {
        _selectedModule = item.module;
        _isSidebarOpen = false;
      }),
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

  Widget _buildTopBar(_DesktopModuleConfig config) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 22, 28, 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _slate200)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _toggleSidebar,
            style: IconButton.styleFrom(
              backgroundColor: _slate100,
              foregroundColor: _navy,
              minimumSize: const Size(48, 48),
            ),
            icon: Icon(
              _isSidebarOpen ? Icons.close_rounded : Icons.menu_rounded,
            ),
            tooltip: _isSidebarOpen ? 'Cerrar menu' : 'Abrir menu',
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  config.title,
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  config.subtitle,
                  style: const TextStyle(
                    color: _slate500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _slate100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Sesion: ${widget.authController.userName ?? 'Usuario'}',
              style: const TextStyle(
                color: _slate700,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  _DesktopModuleConfig _moduleConfig(DesktopModule module) {
    switch (module) {
      case DesktopModule.dashboard:
        return _DesktopModuleConfig(
          title: 'Dashboard',
          subtitle:
              'Resumen general para escritorio con acceso rapido a los modulos principales.',
          content: _DesktopDashboardOverview(
            authController: widget.authController,
            onSelectModule: (nextModule) {
              setState(() => _selectedModule = nextModule);
            },
          ),
        );
      case DesktopModule.productos:
        return _DesktopModuleConfig(
          title: 'Productos',
          subtitle:
              'Catalogo principal con filtros, acciones rapidas y tabla de escritorio.',
          content: ProductosScreen(
            authController: widget.authController,
            embedded: true,
          ),
        );
      case DesktopModule.servicios:
        return _DesktopModuleConfig(
          title: 'Servicios',
          subtitle:
              'Consulta operativa de servicios desde la misma shell de escritorio.',
          content: ServiciosScreen(
            authController: widget.authController,
            embedded: true,
          ),
        );
      case DesktopModule.cotizaciones:
        return _DesktopModuleConfig(
          title: 'Cotizaciones',
          subtitle:
              'Consulta comercial base con filtros, tabla y acciones minimas seguras.',
          content: CotizacionesScreen(
            authController: widget.authController,
            embedded: true,
          ),
        );
      case DesktopModule.facturas:
        return _DesktopModuleConfig(
          title: 'Facturas',
          subtitle:
              'Facturación interna con estado y control de stock al emitir.',
          content: FacturasScreen(
            authController: widget.authController,
            embedded: true,
          ),
        );
    }
  }

  void _toggleSidebar() {
    setState(() => _isSidebarOpen = !_isSidebarOpen);
  }
}

class _DesktopDashboardOverview extends StatelessWidget {
  const _DesktopDashboardOverview({
    required this.authController,
    required this.onSelectModule,
  });

  final AuthController authController;
  final ValueChanged<DesktopModule> onSelectModule;

  @override
  Widget build(BuildContext context) {
    final cards = [
      (
        title: 'Productos',
        subtitle: 'Administrar catalogo, filtros y estados.',
        icon: Icons.inventory_2_outlined,
        module: DesktopModule.productos,
      ),
      (
        title: 'Servicios',
        subtitle: 'Consultar el modulo operativo de servicios.',
        icon: Icons.design_services_outlined,
        module: DesktopModule.servicios,
      ),
      (
        title: 'Cotizaciones',
        subtitle: 'Consultar y mantener la base inicial del modulo.',
        icon: Icons.request_quote_outlined,
        module: DesktopModule.cotizaciones,
      ),
      (
        title: 'Facturas',
        subtitle: 'Facturación interna con estados y emisión.',
        icon: Icons.receipt_long_outlined,
        module: DesktopModule.facturas,
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF0F172A),
                  Color(0xFF134E4A),
                  Color(0xFF0F766E)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Escritorio Tesla',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Usa la barra lateral para moverte entre modulos. El acceso inicial abre el dashboard con entrada visible a Productos y Servicios.',
                        style: TextStyle(
                          color: Color(0xFFE2E8F0),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Text(
                    authController.userRole ?? 'Sin rol',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cards.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 18,
              mainAxisSpacing: 18,
              childAspectRatio: 1.8,
            ),
            itemBuilder: (context, index) {
              final card = cards[index];
              return InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => onSelectModule(card.module),
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(card.icon, color: const Color(0xFF0F766E), size: 30),
                      const Spacer(),
                      Text(
                        card.title,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        card.subtitle,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DesktopModuleConfig {
  const _DesktopModuleConfig({
    required this.title,
    required this.subtitle,
    required this.content,
  });

  final String title;
  final String subtitle;
  final Widget content;
}

class _DesktopNavItem {
  const _DesktopNavItem({
    required this.module,
    required this.label,
    required this.icon,
  });

  final DesktopModule module;
  final String label;
  final IconData icon;
}
