import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _tituloController = TextEditingController();
  final _descController = TextEditingController();
  final _lugarController = TextEditingController();
  final _horaController = TextEditingController();
  String _categoria = 'Académico';

  void _guardarEvento() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('eventos').add({
      'titulo': _tituloController.text,
      'descripcion': _descController.text,
      'lugar': _lugarController.text,
      'hora': _horaController.text,
      'categoria': _categoria,
      'fecha': Timestamp.now(), // Para fines prácticos, usamos ahora
      'organizador': user.uid,   // RF-012: ID del creador
      'nombre_organizador': user.displayName ?? 'Docente/Admin',
    });

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nuevo Evento")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: _tituloController, decoration: const InputDecoration(labelText: "Título del evento")),
            TextField(controller: _descController, decoration: const InputDecoration(labelText: "Descripción")),
            TextField(controller: _lugarController, decoration: const InputDecoration(labelText: "Lugar (ej. Auditorio)")),
            TextField(controller: _horaController, decoration: const InputDecoration(labelText: "Hora (ej. 14:00)")),
            DropdownButton<String>(
              value: _categoria,
              items: ['Académico', 'Cultural', 'Deportivo'].map((String val) {
                return DropdownMenuItem(value: val, child: Text(val));
              }).toList(),
              onChanged: (val) => setState(() => _categoria = val!),
            ),
            const SizedBox(height: 30),
            ElevatedButton(onPressed: _guardarEvento, child: const Text("PUBLICAR EVENTO")),
          ],
        ),
      ),
    );
  }
}