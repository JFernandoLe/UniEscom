import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AttendeesScreen extends StatelessWidget {
  final String eventoId;
  final String eventoNombre;

  const AttendeesScreen({super.key, required this.eventoId, required this.eventoNombre});
  void _mostrarDialogoAviso(BuildContext context) {
  final TextEditingController _avisoController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Enviar aviso a asistentes"),
      content: TextField(
        controller: _avisoController,
        decoration: const InputDecoration(
          hintText: "Ej: El evento se movió al salón 4.",
          border: OutlineInputBorder(),
        ),
        maxLines: 3,
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR")),
        ElevatedButton(
          onPressed: () async {
            if (_avisoController.text.isNotEmpty) {
              // Guardar el aviso en una sub-colección del evento
              await FirebaseFirestore.instance
                  .collection('eventos')
                  .doc(eventoId)
                  .collection('avisos')
                  .add({
                'mensaje': _avisoController.text,
                'fecha': FieldValue.serverTimestamp(),
              });
              
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Aviso enviado a todos los asistentes")),
                );
              }
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
            onPressed: () => _mostrarDialogoAviso(context)
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Filtramos las asistencias por el ID de este evento
        stream: FirebaseFirestore.instance
            .collection('asistencias')
            .where('id_evento', isEqualTo: eventoId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Aún no hay alumnos registrados."));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var asistencia = snapshot.data!.docs[index];
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text("ID Usuario: ${asistencia['id_usuario']}"),
                subtitle: const Text("Registrado institucionalmente"),
              );
            },
          );
        },
      ),
    );
  }
}