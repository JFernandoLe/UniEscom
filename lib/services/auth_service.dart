import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  // Instancias de Firebase
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. OBTENER USUARIO ACTUAL 
  Stream<User?> get userStream => _auth.authStateChanges();

  // 2. REGISTRO DE ESTUDIANTES 
  Future<User?> registrarEstudiante({
    required String email,
    required String password,
    required String nombre,
  }) async {
    try {
      // Validación estricta de correo institucional
      if (!email.endsWith('@alumno.ipn.mx') && !email.endsWith('@ipn.mx')) {
        throw 'Por favor, usa un correo institucional válido de ESCOM/IPN.';
      }

      // Crear usuario en Firebase Auth
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Guardar datos adicionales en Firestore (Perfiles y Roles)
      if (credential.user != null) {
        await _db.collection('usuarios').doc(credential.user!.uid).set({
          'nombre': nombre,
          'correo': email,
          'rol': 'estudiante', // Rol por defecto según requerimiento
          'intereses': [],
          'foto_url': '',
          'fecha_creacion': FieldValue.serverTimestamp(),
        });
      }
      return credential.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') throw 'La contraseña es muy débil.';
      if (e.code == 'email-already-in-use') throw 'Este correo ya está registrado.';
      throw 'Error en el registro: ${e.message}';
    } catch (e) {
      throw e.toString();
    }
  }

  // 3. INICIO DE SESIÓN (RF-002)
  Future<User?> iniciarSesion(String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') throw 'No existe un usuario con este correo.';
      if (e.code == 'wrong-password') throw 'Contraseña incorrecta.';
      if (e.code == 'invalid-credential') throw 'Datos de acceso no válidos.';
      throw 'Error al entrar: ${e.message}';
    }
  }

  // 4. RECUPERAR CONTRASEÑA (RF-003)
  Future<void> recuperarContrasena(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw 'No se pudo enviar el correo de recuperación.';
    }
  }

  // 5. CERRAR SESIÓN
  Future<void> cerrarSesion() async {
    await _auth.signOut();
  }

  // 6. OBTENER DATOS DEL PERFIL (Para saber el Rol y mostrar opciones)
  Future<DocumentSnapshot> getPerfilUsuario(String uid) async {
    return await _db.collection('usuarios').doc(uid).get();
  }
}