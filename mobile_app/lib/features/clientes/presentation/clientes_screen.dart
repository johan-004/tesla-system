import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/auth/auth_controller.dart';
import '../data/clientes_repository.dart';
import '../domain/cliente.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key, required this.authController});

  final AuthController authController;

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  late final ClientesRepository _repository;
  late Future<List<Cliente>> _future;

  @override
  void initState() {
    super.initState();
    _repository = ClientesRepository(ApiClient(token: widget.authController.token));
    _future = _repository.fetchClientes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clientes')),
      body: FutureBuilder<List<Cliente>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error cargando clientes: ${snapshot.error}'));
          }

          final clientes = snapshot.data ?? [];

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: clientes.length,
            itemBuilder: (context, index) {
              final cliente = clientes[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(cliente.nombre),
                  subtitle: Text(
                    'Documento: ${cliente.documento.isEmpty ? '-' : cliente.documento}\nTelefono: ${cliente.telefono.isEmpty ? '-' : cliente.telefono}',
                  ),
                  trailing: Text(cliente.activo ? 'Activo' : 'Inactivo'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
