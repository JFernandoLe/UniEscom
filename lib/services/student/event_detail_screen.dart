import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uni_escom/services/organizer/attendees_screen.dart';
import 'package:uni_escom/services/organizer/edit_event_screen.dart';
import '../../models/event_model.dart';

class EventDetailScreen extends StatelessWidget {
  final EventModel evento;

  const EventDetailScreen({super.key, required this.evento});


  bool _seccionPermiteCategoria(String seccion, String categoria) {
    if (seccion == 'sec_administrativa') return true;
    if (seccion == 'sec_academica' && categoria == 'Académico') return true;
    if (seccion == 'sec_cultural' && categoria == 'Cultural') return true;
    if (seccion == 'sec_deportiva' && categoria == 'Deportivo') return true;
    return false;
  }

  void _registrarAsistencia(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // 1) Traer datos del usuario
      final userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();

      final userData = userDoc.data() ?? {};
      final nombreUsuario =
          (userData['nombre'] ?? user.displayName ?? 'Usuario').toString();
      final emailUsuario =
          (userData['correo'] ?? user.email ?? '').toString();

      // 2) ID único por evento+usuario
      final asistenciaId = '${evento.id}_${user.uid}';

      // 3) Crear/actualizar SIEMPRE el mismo doc (sin duplicados)
      await FirebaseFirestore.instance
          .collection('asistencias')
          .doc(asistenciaId)
          .set({
        'id_evento': evento.id,
        'id_usuario': user.uid,
        'fecha_registro': FieldValue.serverTimestamp(),
        'nombre_evento': evento.titulo,
        'fechaHora_evento': Timestamp.fromDate(evento.fechaHora),

        // Para AttendeesScreen
        'nombre_usuario': nombreUsuario,
        'email_usuario': emailUsuario,
      }, SetOptions(merge: true));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("¡Te has registrado con éxito!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }



  Future<void> _cancelarAsistencia(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final asistenciaId = '${evento.id}_${user.uid}';

      await FirebaseFirestore.instance
          .collection('asistencias')
          .doc(asistenciaId)
          .delete();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Registro cancelado ✅"),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> _miAsistenciaStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Stream vacío si no hay sesión
      return const Stream.empty();
    }
    final asistenciaId = '${evento.id}_${user.uid}';
    return FirebaseFirestore.instance
        .collection('asistencias')
        .doc(asistenciaId)
        .snapshots();
  }


  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
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
                if (snapshot.hasError) {
                  return Center(
                    child: Text("Error cargando asistentes: ${snapshot.error}"),
                  );
                }

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
            // PERMISOS (admin u organizador por sección)
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('usuarios')
                  .doc(uid)
                  .snapshots(),
              builder: (context, snapUser) {
                if (snapUser.connectionState == ConnectionState.waiting) {
                  return const SizedBox(); // no bloquees la UI
                }

                final data = (snapUser.data?.data() as Map<String, dynamic>?) ?? {};
                final rol = (data['rol'] ?? 'estudiante').toString();
                final seccion = (data['seccion_org'] ?? '').toString();

                final canManage = (rol == 'admin') ||
                    (rol == 'organizador' && _seccionPermiteCategoria(seccion, evento.categoria));

                if (!canManage) return const SizedBox();

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
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
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.delete),
                            label: const Text("CANCELAR"),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text("¿Cancelar evento?"),
                                  content: const Text("Esta acción eliminará el evento permanentemente."),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text("No"),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        await FirebaseFirestore.instance
                                            .collection('eventos')
                                            .doc(evento.id)
                                            .delete();
                                        if (context.mounted) {
                                          Navigator.pop(context);
                                          Navigator.pop(context);
                                        }
                                      },
                                      child: const Text("Sí, eliminar", style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    SizedBox(
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
                  ],
                );
              },
            ),

            // ✅ Botón registrarse (para todos)
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _miAsistenciaStream(),
              builder: (context, snap) {
                final yaRegistrado = (snap.data?.exists ?? false);

                return SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: yaRegistrado ? Colors.red : Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      if (yaRegistrado) {
                        _cancelarAsistencia(context);
                      } else {
                        _registrarAsistencia(context);
                      }
                    },
                    child: Text(yaRegistrado ? "CANCELAR REGISTRO" : "REGISTRARME AL EVENTO"),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}