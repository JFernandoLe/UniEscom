import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/event_model.dart';

class EditEventScreen extends StatefulWidget {
  final EventModel evento;
  const EditEventScreen({super.key, required this.evento});

  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  late TextEditingController _tituloController;
  late TextEditingController _descController;
  late TextEditingController _lugarController;
  late String _categoria;

  DateTime? _fechaHora;

  @override
  void initState() {
    super.initState();
    _tituloController = TextEditingController(text: widget.evento.titulo);
    _descController = TextEditingController(text: widget.evento.descripcion);
    _lugarController = TextEditingController(text: widget.evento.lugar);
    _categoria = widget.evento.categoria;

    _fechaHora = widget.evento.fechaHora; // lo traes del model
  }

  Future<void> _pickFechaHora() async {
    final now = DateTime.now();
    final base = _fechaHora ?? now;

    final fecha = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );
    if (fecha == null) return;

    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: base.hour, minute: base.minute),
    );
    if (hora == null) return;

    setState(() {
      _fechaHora = DateTime(fecha.year, fecha.month, fecha.day, hora.hour, hora.minute);
    });
  }

  Future<void> _actualizarEvento() async {
    if (_tituloController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("El título es obligatorio")),
      );
      return;
    }
    if (_fechaHora == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecciona fecha y hora del evento")),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('eventos').doc(widget.evento.id).update({
      'titulo': _tituloController.text.trim(),
      'descripcion': _descController.text.trim(),
      'lugar': _lugarController.text.trim(),
      'categoria': _categoria,
      'fechaHora': Timestamp.fromDate(_fechaHora!),

      // compat opcional: si todavía tienes pantallas viejas que leen 'hora'
      'hora': '${_fechaHora!.hour.toString().padLeft(2,'0')}:${_fechaHora!.minute.toString().padLeft(2,'0')}',
    });

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Evento actualizado ✅")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fh = _fechaHora;
    final fhText = (fh == null)
        ? "SELECCIONAR FECHA Y HORA"
        : "Fecha/Hora: ${fh.day}/${fh.month}/${fh.year} "
          "${fh.hour.toString().padLeft(2, '0')}:${fh.minute.toString().padLeft(2, '0')}";

    return Scaffold(
      appBar: AppBar(title: const Text("Editar Evento")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: _tituloController, decoration: const InputDecoration(labelText: "Título")),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: "Descripción"),
              maxLines: 3,
            ),
            TextField(controller: _lugarController, decoration: const InputDecoration(labelText: "Lugar")),

            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: _pickFechaHora,
              icon: const Icon(Icons.event),
              label: Text(fhText),
            ),

            const SizedBox(height: 20),

            DropdownButton<String>(
              value: _categoria,
              isExpanded: true,
              items: ['Académico', 'Cultural', 'Deportivo'].map((val) {
                return DropdownMenuItem(value: val, child: Text(val));
              }).toList(),
              onChanged: (val) => setState(() => _categoria = val!),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
              onPressed: _actualizarEvento,
              child: const Text("GUARDAR CAMBIOS"),
            ),
          ],
        ),
      ),
    );
  }
}
