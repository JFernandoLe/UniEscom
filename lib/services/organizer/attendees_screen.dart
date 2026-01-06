import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AttendeesScreen extends StatelessWidget {
  final String eventoId;
  final String eventoNombre;

  const AttendeesScreen({
    super.key,
    required this.eventoId,
    required this.eventoNombre,
  });

  void _mostrarDialogoAviso(BuildContext context) {
    final avisoController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text("Enviar aviso a asistentes"),
        content: TextField(
          controller: avisoController,
          decoration: const InputDecoration(
            hintText: "Ej: El evento se movió al salón 4.",
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () {
              avisoController.dispose();
              Navigator.pop(dialogCtx);
            },
            child: const Text("CANCELAR"),
          ),
          ElevatedButton(
            onPressed: () async {
              final texto = avisoController.text.trim();
              if (texto.isEmpty) return;

              await FirebaseFirestore.instance
                  .collection('eventos')
                  .doc(eventoId)
                  .collection('avisos')
                  .add({
                'mensaje': texto,
                'fecha': FieldValue.serverTimestamp(),
                'eventoId': eventoId,
                'eventoNombre': eventoNombre,
              });

              if (dialogCtx.mounted) {
                avisoController.dispose();
                Navigator.pop(dialogCtx);
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Aviso enviado a todos los asistentes")),
                );
              }
            },
            child: const Text("ENVIAR"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Asistentes: $eventoNombre"),
        actions: [
          IconButton(
            icon: const Icon(Icons.campaign),
            onPressed: () => _mostrarDialogoAviso(context),
          ),
        ],
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
          .collection('asistencias')
          .where('id_evento', isEqualTo: eventoId)
          .orderBy('fecha_registro', descending: true)
          .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  "Error cargando asistentes:\n${snapshot.error}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          // 2) Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 3) Empty
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Aún no hay alumnos registrados."));
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final asistencia = docs[index].data() as Map<String, dynamic>;

              final nombre = (asistencia['nombre_usuario'] ?? 'Usuario').toString();
              final email = (asistencia['email_usuario'] ?? '').toString();

              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(nombre),
                subtitle: Text(email.isEmpty ? "Registrado" : email),
              );
            },
          );
        }, //builder
      ),
    );
  }
}
