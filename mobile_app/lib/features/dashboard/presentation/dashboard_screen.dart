import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../categorias_servicio/presentation/categorias_servicio_screen.dart';
import '../../cotizaciones/presentation/cotizaciones_screen.dart';
import '../../facturas/presentation/facturas_screen.dart';
import '../../productos/presentation/productos_screen.dart';
import '../../servicios/presentation/servicios_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.authController});

  final AuthController authController;

  @override
  Widget build(BuildContext context) {
    final modules = [
      _DashboardModule('Productos', Icons.inventory_2_outlined,
          ProductosScreen(authController: authController)),
      _DashboardModule('Categorías', Icons.insights_outlined,
          const CategoriasServicioScreen()),
      _DashboardModule('Servicios', Icons.design_services_outlined,
          ServiciosScreen(authController: authController)),
      _DashboardModule('Cotizaciones', Icons.request_quote_outlined,
          CotizacionesScreen(authController: authController)),
      _DashboardModule('Facturas', Icons.receipt_long_outlined,
          FacturasScreen(authController: authController)),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tesla System'),
        actions: [
          IconButton(
            onPressed: () async => authController.logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hola, ${authController.userName ?? 'Usuario'}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text('Rol: ${authController.userRole ?? '-'}'),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                itemCount: modules.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                ),
                itemBuilder: (context, index) {
                  final module = modules[index];
                  return InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => module.screen),
                      );
                    },
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(module.icon,
                                size: 40, color: const Color(0xFF0F766E)),
                            const Spacer(),
                            Text(module.label,
                                style: Theme.of(context).textTheme.titleMedium),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardModule {
  _DashboardModule(this.label, this.icon, this.screen);

  final String label;
  final IconData icon;
  final Widget screen;
}
