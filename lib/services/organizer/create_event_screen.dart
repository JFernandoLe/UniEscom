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
  String _categoria = 'Académico';
  DateTime? _fechaHora;

  Future<void> _pickFechaHora() async {
    final now = DateTime.now();

    final fecha = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );
    if (fecha == null) return;

    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(minutes: 10))),
    );
    if (hora == null) return;

    setState(() {
      _fechaHora = DateTime(fecha.year, fecha.month, fecha.day, hora.hour, hora.minute);
    });
  }


  void _guardarEvento() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_fechaHora == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Selecciona fecha y hora del evento")),
        );
        return;
    }

      if (_tituloController.text.trim().isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text("El título es obligatorio")),
       );
       return;
    }
    await FirebaseFirestore.instance.collection('eventos').add({
      'titulo': _tituloController.text.trim(),
      'descripcion': _descController.text.trim(),
      'lugar': _lugarController.text.trim(),
      'categoria': _categoria,
      'fechaHora': Timestamp.fromDate(_fechaHora!),
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
            OutlinedButton.icon(
              onPressed: _pickFechaHora,
              icon: const Icon(Icons.event),
              label: Text(
                _fechaHora == null
                    ? "SELECCIONAR FECHA Y HORA"
                    : "Fecha/Hora: "
                      "${_fechaHora!.day}/${_fechaHora!.month}/${_fechaHora!.year} "
                      "${_fechaHora!.hour.toString().padLeft(2, '0')}:"
                      "${_fechaHora!.minute.toString().padLeft(2, '0')}",
              ),
            ),
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