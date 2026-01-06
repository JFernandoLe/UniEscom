class UserModel {
  final String uid;
  final String nombre;
  final String correo;
  final String rol; // estudiante, organizador, admin
  final List<String> intereses;
  final String? fotoUrl;

  UserModel({
    required this.uid,
    required this.nombre,
    required this.correo,
    required this.rol,
    this.intereses = const [],
    this.fotoUrl,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String id) {
    return UserModel(
      uid: id,
      nombre: data['nombre'] ?? '',
      correo: data['correo'] ?? '',
      rol: data['rol'] ?? 'estudiante',
      intereses: List<String>.from(data['intereses'] ?? []),
      fotoUrl: data['fotoUrl'],
    );
  }
}