import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AttendeesScreen extends StatelessWidget {
  final String eventoId;
  final String eventoNombre;

  const AttendeesScreen({super.key, required this.eventoId, required this.eventoNombre});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Asistentes: $eventoNombre")),
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