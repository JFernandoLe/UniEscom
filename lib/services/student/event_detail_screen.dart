import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uni_escom/services/organizer/attendees_screen.dart';
import 'package:uni_escom/services/organizer/edit_event_screen.dart';
import 'package:uni_escom/services/notifications/notification_hooks.dart';
import 'package:uni_escom/services/api/backend_client.dart';
import '../../models/event_model.dart';

class EventDetailScreen extends StatelessWidget {
  final EventModel evento;

  const EventDetailScreen({super.key, required this.evento});

  Future<String> _getNombreCreador(String idUsuario) async {
    if (idUsuario.isEmpty) return "Organizador desconocido";
    try {
      final doc = await FirebaseFirestore.instance.collection('usuarios').doc(idUsuario).get();
      if (doc.exists) return doc.data()?['nombre'] ?? "Sin nombre";
    } catch (e) { debugPrint("Error: $e"); }
    return "Organizador ESCOM";
  }

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
      final userDoc = await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).get();
      final userData = userDoc.data() ?? {};
      final nombreUsuario = (userData['nombre'] ?? user.displayName ?? 'Usuario').toString();
      final emailUsuario = (userData['correo'] ?? user.email ?? '').toString();
      final asistenciaId = '${evento.id}_${user.uid}';

      await FirebaseFirestore.instance.collection('asistencias').doc(asistenciaId).set({
        'id_evento': evento.id,
        'id_usuario': user.uid,
        'fecha_registro': FieldValue.serverTimestamp(),
        'nombre_evento': evento.titulo,
        'fechaHora_evento': Timestamp.fromDate(evento.fechaHora),
        'nombre_usuario': nombreUsuario,
        'email_usuario': emailUsuario,
      }, SetOptions(merge: true));

      // Disparar notificación inmediata y programar recordatorios desde el clic
      await NotificationHooks.onEventRegistration(
        eventId: evento.id,
        eventTitle: evento.titulo,
        eventDate: evento.fechaHora,
      );

      // Enviar push remoto vía backend (FCM)
      try {
        await BackendClient().sendRegistrationNotification(
          uid: user.uid,
          eventId: evento.id,
          eventTitle: evento.titulo,
        );

        // Notificar al organizador
        await BackendClient().notifyOrganizerRegistration(
          eventId: evento.id,
          actorUid: user.uid,
          actorName: nombreUsuario,
          eventTitle: evento.titulo,
        );

        // Programar recordatorios en el backend (cada 3 días + 2h antes)
        await BackendClient().scheduleServerReminders(
          uid: user.uid,
          eventId: evento.id,
          eventTitle: evento.titulo,
          eventDate: evento.fechaHora,
          intervalDays: 3,
          // testEveryMinutes: 2, // Descomenta para pruebas rápidas
        );
      } catch (e) {
        debugPrint('Backend push error: $e');
      }

      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡Registrado con éxito!"), backgroundColor: Colors.green));
    } catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red)); }
  }

  Future<void> _cancelarAsistencia(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final asistenciaId = '${evento.id}_${user.uid}';
      await FirebaseFirestore.instance.collection('asistencias').doc(asistenciaId).delete();
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Registro cancelado ✅"), backgroundColor: Colors.orange));
    } catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red)); }
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> _miAsistenciaStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();
    return FirebaseFirestore.instance.collection('asistencias').doc('${evento.id}_${user.uid}').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final dt = evento.fechaHora;
    final bool esPasado = evento.fechaHora.isBefore(DateTime.now());

    return Scaffold(
      appBar: AppBar(title: Text(evento.titulo)),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(evento.titulo, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            FutureBuilder<String>(
              future: _getNombreCreador(evento.organizador),
              builder: (context, snapshot) => Row(children: [
                const Icon(Icons.person_outline, size: 18, color: Colors.blueGrey),
                const SizedBox(width: 5),
                Text("Organizado por: ${snapshot.data ?? '...'}", style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.blueGrey)),
              ]),
            ),
            const SizedBox(height: 12),
            _infoRow(Icons.location_on, evento.lugar, Colors.red),
            _infoRow(Icons.access_time, evento.hora, Colors.blue),
            _infoRow(Icons.calendar_today, "${dt.day}/${dt.month}/${dt.year}", Colors.purple),
            const Divider(height: 30),
            
            // Sección Avisos...
            _buildAvisos(),

            const Text("Descripción", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(evento.descripcion),
            const Spacer(),

            // Gestión Admin...
            _buildAdminControls(uid),

            // BOTÓN DE REGISTRO DINÁMICO
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _miAsistenciaStream(),
              builder: (context, snap) {
                final yaRegistrado = (snap.data?.exists ?? false);
                
                // Si el evento ya pasó y NO estaba registrado, botón gris y deshabilitado
                final bool bloquearBoton = esPasado && !yaRegistrado;

                return SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: bloquearBoton 
                          ? Colors.grey 
                          : (yaRegistrado ? Colors.red.shade400 : Colors.green.shade600),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: bloquearBoton ? null : () => yaRegistrado ? _cancelarAsistencia(context) : _registrarAsistencia(context),
                    child: Text(bloquearBoton ? "EVENTO FINALIZADO" : (yaRegistrado ? "CANCELAR REGISTRO" : "REGISTRARME AL EVENTO")),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, Color color) => Padding(
    padding: const EdgeInsets.only(bottom: 8.0),
    child: Row(children: [Icon(icon, color: color, size: 20), const SizedBox(width: 8), Text(text, style: const TextStyle(fontSize: 16))]),
  );

  Widget _buildAvisos() => StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance.collection('eventos').doc(evento.id).collection('avisos').orderBy('fecha', descending: true).snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox();
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("⚠️ AVISOS RECIENTES", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        ...snapshot.data!.docs.map((doc) => Container(
          width: double.infinity, margin: const EdgeInsets.only(top: 8), padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.amber.withOpacity(0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.amber.withOpacity(0.5))),
          child: Text(doc['mensaje'], style: const TextStyle(fontSize: 14)),
        )),
        const Divider(height: 30),
      ]);
    },
  );

  Widget _buildAdminControls(String? uid) => StreamBuilder<DocumentSnapshot>(
    stream: FirebaseFirestore.instance.collection('usuarios').doc(uid).snapshots(),
    builder: (context, snapUser) {
      if (!snapUser.hasData) return const SizedBox();
      final data = snapUser.data?.data() as Map<String, dynamic>? ?? {};
      final canManage = (data['rol'] == 'admin') || (data['rol'] == 'organizador' && _seccionPermiteCategoria(data['seccion_org'] ?? '', evento.categoria));
      if (!canManage) return const SizedBox();
      return Padding(padding: const EdgeInsets.only(bottom: 10), child: Column(children: [
        Row(children: [
          Expanded(child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white), icon: const Icon(Icons.edit), label: const Text("EDITAR"), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditEventScreen(evento: evento))))),
          const SizedBox(width: 10),
          Expanded(child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), icon: const Icon(Icons.delete), label: const Text("ELIMINAR"), onPressed: () => _mostrarDialogoEliminar(context))),
        ]),
        const SizedBox(height: 8),
        SizedBox(width: double.infinity, child: OutlinedButton.icon(icon: const Icon(Icons.people), label: const Text("VER ASISTENTES"), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AttendeesScreen(eventoId: evento.id, eventoNombre: evento.titulo))))),
      ]));
    },
  );

  void _mostrarDialogoEliminar(BuildContext context) {
    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text("¿Eliminar evento?"), content: const Text("Esta acción es permanente."),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("No")), TextButton(onPressed: () async { await FirebaseFirestore.instance.collection('eventos').doc(evento.id).delete(); if (context.mounted) { Navigator.pop(context); Navigator.pop(context); } }, child: const Text("Sí, eliminar", style: TextStyle(color: Colors.red)))],
    ));
  }
}