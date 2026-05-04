import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../core/notifications/in_app_notification.dart';
import '../../../core/notifications/notifications_repository.dart';
import '../../dashboard/presentation/dashboard_overview.dart';
import '../../cotizaciones/presentation/cotizaciones_screen.dart';
import '../../facturas/presentation/facturas_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../productos/presentation/productos_screen.dart';
import '../../servicios/presentation/servicios_screen.dart';

enum DesktopModule {
  dashboard,
  productos,
  servicios,
  cotizaciones,
  facturas,
  perfil,
}

enum _NotificationCategory { all, facturas, cotizaciones, stock }

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
  int _contentVersion = 0;
  List<InAppNotification> _notifications = const [];
  int _unreadNotifications = 0;
  bool _loadingNotifications = false;
  String? _pendingCotizacionSearch;
  String? _pendingFacturaSearch;
  late final NotificationsRepository _notificationsRepository;

  @override
  void initState() {
    super.initState();
    _selectedModule = widget.initialModule;
    _notificationsRepository = NotificationsRepository(
      ApiClient(token: widget.authController.token),
    );
    unawaited(_loadNotifications());
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
                    key: ValueKey('${_selectedModule.name}-$_contentVersion'),
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
      _DesktopNavItem(
        module: DesktopModule.perfil,
        label: 'Perfil',
        icon: Icons.person_outline_rounded,
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
          Row(
            children: [
              IconButton(
                onPressed: _loadingNotifications ? null : _openNotificationsSheet,
                tooltip: 'Notificaciones',
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications_none_rounded,
                        color: _slate700, size: 26),
                    if (_unreadNotifications > 0)
                      Positioned(
                        right: -3,
                        top: -5,
                        child: Container(
                          constraints: const BoxConstraints(minWidth: 16),
                          height: 16,
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            borderRadius: BorderRadius.all(Radius.circular(999)),
                          ),
                          child: Center(
                            child: Text(
                              _unreadNotifications > 99
                                  ? '99+'
                                  : '$_unreadNotifications',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    widget.authController.userName ?? 'Admin Tesla',
                    style: const TextStyle(
                      color: _navy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Text(
                    'Administrador',
                    style: TextStyle(
                      color: _slate500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: Color(0xFF16A34A),
                  shape: BoxShape.circle,
                ),
              ),
            ],
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
          subtitle: 'Resumen general de tu negocio en tiempo real.',
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
        final initialSearch = _pendingCotizacionSearch;
        _pendingCotizacionSearch = null;
        return _DesktopModuleConfig(
          title: 'Cotizaciones',
          subtitle:
              'Consulta comercial base con filtros, tabla y acciones minimas seguras.',
          content: CotizacionesScreen(
            authController: widget.authController,
            embedded: true,
            initialSearch: initialSearch,
          ),
        );
      case DesktopModule.facturas:
        final initialSearch = _pendingFacturaSearch;
        _pendingFacturaSearch = null;
        return _DesktopModuleConfig(
          title: 'Facturas',
          subtitle:
              'Facturación interna con estado y control de stock al emitir.',
          content: FacturasScreen(
            authController: widget.authController,
            embedded: true,
            initialSearch: initialSearch,
          ),
        );
      case DesktopModule.perfil:
        return _DesktopModuleConfig(
          title: 'Perfil',
          subtitle: 'Actualiza correo y contraseña de tu cuenta.',
          content: ProfileScreen(
            authController: widget.authController,
            embedded: true,
          ),
        );
    }
  }

  void _toggleSidebar() {
    setState(() => _isSidebarOpen = !_isSidebarOpen);
  }

  Future<void> _loadNotifications() async {
    setState(() => _loadingNotifications = true);
    try {
      final feed = await _notificationsRepository.fetchNotifications(limit: 30);
      if (!mounted) return;
      setState(() {
        _notifications = feed.items;
        _unreadNotifications = feed.unreadCount;
      });
    } finally {
      if (mounted) {
        setState(() => _loadingNotifications = false);
      }
    }
  }

  Future<void> _openNotificationsSheet() async {
    await _loadNotifications();
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        var selectedCategory = _NotificationCategory.all;
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = _notifications
                .where((n) => _matchesNotificationCategory(n, selectedCategory))
                .toList();
            final allCount =
                _countForCategory(_NotificationCategory.all, unreadOnly: true);
            final facturasCount =
                _countForCategory(_NotificationCategory.facturas, unreadOnly: true);
            final cotizacionesCount =
                _countForCategory(_NotificationCategory.cotizaciones, unreadOnly: true);
            final stockCount =
                _countForCategory(_NotificationCategory.stock, unreadOnly: true);

            return SizedBox(
              height: 500,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Notificaciones',
                          style: TextStyle(
                            color: _navy,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '$_unreadNotifications sin leer',
                          style: const TextStyle(color: _slate500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _categoryChip(
                          label: 'Todas ($allCount)',
                          selected: selectedCategory == _NotificationCategory.all,
                          onTap: () => setModalState(
                            () => selectedCategory = _NotificationCategory.all,
                          ),
                        ),
                        _categoryChip(
                          label: 'Facturas ($facturasCount)',
                          selected: selectedCategory ==
                              _NotificationCategory.facturas,
                          onTap: () => setModalState(
                            () =>
                                selectedCategory = _NotificationCategory.facturas,
                          ),
                        ),
                        _categoryChip(
                          label: 'Cotizaciones ($cotizacionesCount)',
                          selected: selectedCategory ==
                              _NotificationCategory.cotizaciones,
                          onTap: () => setModalState(
                            () => selectedCategory =
                                _NotificationCategory.cotizaciones,
                          ),
                        ),
                        _categoryChip(
                          label: 'Stock ($stockCount)',
                          selected: selectedCategory == _NotificationCategory.stock,
                          onTap: () => setModalState(
                            () => selectedCategory = _NotificationCategory.stock,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(
                              child: Text(
                                'No hay notificaciones en esta sección.',
                                style: TextStyle(color: _slate500),
                              ),
                            )
                          : ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1, color: _slate200),
                              itemBuilder: (context, index) {
                                final notification = filtered[index];
                                return ListTile(
                                  contentPadding:
                                      const EdgeInsets.symmetric(vertical: 6),
                                  leading: Icon(
                                    _iconForNotification(notification),
                                    color: _navySoft,
                                  ),
                                  title: Text(
                                    notification.title,
                                    style: TextStyle(
                                      color: _navy,
                                      fontWeight: notification.isRead
                                          ? FontWeight.w600
                                          : FontWeight.w800,
                                    ),
                                  ),
                                  subtitle: Text(
                                    notification.body,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: TextButton(
                                    onPressed: () async {
                                      Navigator.of(context).pop();
                                      await _openNotification(notification);
                                    },
                                    child: const Text('Ver'),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _categoryChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }

  bool _isStockNotification(InAppNotification notification) {
    final event = notification.event.trim().toLowerCase();
    final resourceType = notification.resourceType.trim().toLowerCase();
    return event == 'producto.stock_zero' || resourceType == 'producto';
  }

  bool _matchesNotificationCategory(
    InAppNotification notification,
    _NotificationCategory category,
  ) {
    final resourceType = notification.resourceType.trim().toLowerCase();
    return switch (category) {
      _NotificationCategory.all => true,
      _NotificationCategory.facturas => resourceType == 'factura',
      _NotificationCategory.cotizaciones => resourceType == 'cotizacion',
      _NotificationCategory.stock => _isStockNotification(notification),
    };
  }

  IconData _iconForNotification(InAppNotification notification) {
    final resourceType = notification.resourceType.trim().toLowerCase();
    if (_isStockNotification(notification)) {
      return Icons.inventory_2_outlined;
    }
    if (resourceType == 'factura') {
      return Icons.receipt_long_outlined;
    }
    return Icons.request_quote_outlined;
  }

  int _countForCategory(
    _NotificationCategory category, {
    bool unreadOnly = false,
  }) {
    return _notifications
        .where((n) {
          if (!_matchesNotificationCategory(n, category)) {
            return false;
          }
          if (unreadOnly && n.isRead) {
            return false;
          }
          return true;
        })
        .length;
  }

  Future<void> _openNotification(InAppNotification notification) async {
    final wasUnread = !notification.isRead;
    try {
      if (wasUnread) {
        await _notificationsRepository.markRead(notification.id);
      }
    } catch (_) {
      // El fallo de marcado no debe bloquear la navegación.
    }

    final resourceType = notification.resourceType.trim().toLowerCase();
    final codigo = notification.codigo.trim();
    final fallback = notification.resourceId?.toString() ?? '';
    final search = codigo.isNotEmpty ? codigo : fallback;

    if (resourceType == 'cotizacion') {
      setState(() {
        _pendingCotizacionSearch = search;
        _selectedModule = DesktopModule.cotizaciones;
        _contentVersion += 1;
        if (wasUnread) {
          _unreadNotifications = (_unreadNotifications - 1).clamp(0, 9999);
        }
      });
      return;
    }

    if (resourceType == 'factura') {
      setState(() {
        _pendingFacturaSearch = search;
        _selectedModule = DesktopModule.facturas;
        _contentVersion += 1;
        if (wasUnread) {
          _unreadNotifications = (_unreadNotifications - 1).clamp(0, 9999);
        }
      });
      return;
    }

    if (_isStockNotification(notification)) {
      setState(() {
        _selectedModule = DesktopModule.productos;
        _contentVersion += 1;
        if (wasUnread) {
          _unreadNotifications = (_unreadNotifications - 1).clamp(0, 9999);
        }
      });
    }
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
    return DashboardOverview(
      authController: authController,
      showHeader: false,
      onOpenProductos: () => onSelectModule(DesktopModule.productos),
      onOpenServicios: () => onSelectModule(DesktopModule.servicios),
      onOpenCotizaciones: () => onSelectModule(DesktopModule.cotizaciones),
      onOpenFacturas: () => onSelectModule(DesktopModule.facturas),
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
