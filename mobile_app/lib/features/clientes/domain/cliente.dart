class Cliente {
  Cliente({
    required this.id,
    required this.nombre,
    required this.documento,
    required this.telefono,
    required this.email,
    required this.activo,
  });

  final int id;
  final String nombre;
  final String documento;
  final String telefono;
  final String email;
  final bool activo;

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      id: json['id'] as int,
      nombre: json['nombre']?.toString() ?? '',
      documento: json['documento']?.toString() ?? '',
      telefono: json['telefono']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      activo: json['activo'] as bool? ?? false,
    );
  }
}
