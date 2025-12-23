import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("UniEscom - Eventos"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.cerrarSesion();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Próximos Eventos",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text("Bienvenido a la gestión de eventos de ESCOM."),
            const SizedBox(height: 20),
            // Aquí irá la lista de evenyos
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.event_available, size: 80, color: Colors.grey),
                    const SizedBox(height: 10),
                    const Text("No hay eventos registrados aún."),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        // Acción para filttrar
                      },
                      child: const Text("Filtrar por categoría"),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}