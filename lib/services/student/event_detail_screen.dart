import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uni_escom/services/organizer/attendees_screen.dart';
import 'package:uni_escom/services/organizer/edit_event_screen.dart';
import '../../models/event_model.dart';

class EventDetailScreen extends StatelessWidget {
  final EventModel evento;

  const EventDetailScreen({super.key, required this.evento});

  void _registrarAsistencia(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Guardar registro en la colección 'asistencias'
        await FirebaseFirestore.instance.collection('asistencias').add({
        'id_evento': evento.id,
        'id_usuario': user.uid,
        'fecha_registro': FieldValue.serverTimestamp(),
        'nombre_evento': evento.titulo,
        'fechaHora_evento': Timestamp.fromDate(evento.fechaHora),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("¡Te has registrado con éxito!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dt = evento.fechaHora;
    return Scaffold(
      appBar: AppBar(title: Text(evento.titulo)),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(evento.titulo, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.red),
                Text(" ${evento.lugar}"),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.access_time, color: Colors.blue),
                Text(
                  " ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}",
                ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.purple),
                Text(
                  " ${dt.day}/${dt.month}/${dt.year}",
                ),
              ],
            ),

            const Divider(height: 40),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('eventos')
                  .doc(evento.id)
                  .collection('avisos')
                  .orderBy('fecha', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("⚠️ AVISOS RECIENTES", 
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    ...snapshot.data!.docs.map((doc) => Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber),
                      ),
                      child: Text(doc['mensaje'], style: const TextStyle(fontSize: 14)),
                    )).toList(),
                    const Divider(),
                  ],
                );
              },
            ),
            const Text("Descripción", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(evento.descripcion),
            const Spacer(),
            if (FirebaseAuth.instance.currentUser?.uid == evento.organizador)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                      icon: const Icon(Icons.edit),
                      label: const Text("EDITAR"),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => EditEventScreen(evento: evento)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                      icon: const Icon(Icons.delete),
                      label: const Text("CANCELAR"),
                      onPressed: () {
                        // Confirmación de seguridad
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("¿Cancelar evento?"),
                            content: const Text("Esta acción eliminará el evento permanentemente."),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context), child: const Text("No")),
                              TextButton(
                                onPressed: () async {
                                  await FirebaseFirestore.instance.collection('eventos').doc(evento.id).delete();
                                  if (context.mounted) {
                                    Navigator.pop(context); // Cierra el dialogo
                                    Navigator.pop(context); // Regresa al Home
                                  }
                                }, 
                                child: const Text("Sí, eliminar", style: TextStyle(color: Colors.red))
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            if (FirebaseAuth.instance.currentUser?.uid == evento.organizador)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.people),
                    label: const Text("VER LISTA DE ASISTENTES"),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AttendeesScreen(
                            eventoId: evento.id,
                            eventoNombre: evento.titulo,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                onPressed: () => _registrarAsistencia(context),
                child: const Text("REGISTRARME AL EVENTO"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}