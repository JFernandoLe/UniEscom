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
  late TextEditingController _horaController;
  late String _categoria;

  @override
  void initState() {
    super.initState();
    _tituloController = TextEditingController(text: widget.evento.titulo);
    _descController = TextEditingController(text: widget.evento.descripcion);
    _lugarController = TextEditingController(text: widget.evento.lugar);
    _horaController = TextEditingController(text: widget.evento.hora);
    _categoria = widget.evento.categoria;
  }

  void _actualizarEvento() async {
    await FirebaseFirestore.instance.collection('eventos').doc(widget.evento.id).update({
      'titulo': _tituloController.text,
      'descripcion': _descController.text,
      'lugar': _lugarController.text,
      'hora': _horaController.text,
      'categoria': _categoria,
    });
    if (mounted) {
      Navigator.pop(context); // Regresa al detalle
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Evento actualizado")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Editar Evento")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: _tituloController, decoration: const InputDecoration(labelText: "Título")),
            TextField(controller: _descController, decoration: const InputDecoration(labelText: "Descripción"), maxLines: 3),
            TextField(controller: _lugarController, decoration: const InputDecoration(labelText: "Lugar")),
            TextField(controller: _horaController, decoration: const InputDecoration(labelText: "Hora")),
            const SizedBox(height: 20),
            DropdownButton<String>(
              value: _categoria,
              isExpanded: true,
              items: ['Académico', 'Cultural', 'Deportivo'].map((String val) {
                return DropdownMenuItem(value: val, child: Text(val));
              }).toList(),
              onChanged: (val) => setState(() => _categoria = val!),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
              onPressed: _actualizarEvento, 
              child: const Text("GUARDAR CAMBIOS")
            ),
          ],
        ),
      ),
    );
  }
}