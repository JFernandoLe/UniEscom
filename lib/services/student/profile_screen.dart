import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nombreController = TextEditingController();
  List<String> misIntereses = [];
  final List<String> opcionesIntereses = ['Académico', 'Cultural', 'Deportivo']; // Basado en 1.3 [cite: 15]

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  void _cargarDatos() async {
    final user = FirebaseAuth.instance.currentUser;
    var doc = await FirebaseFirestore.instance.collection('usuarios').doc(user!.uid).get();
    if (doc.exists) {
      setState(() {
        _nombreController.text = doc['nombre'] ?? '';
        misIntereses = List<String>.from(doc['intereses'] ?? []);
      });
    }
  }

  void _actualizarPerfil() async {
    final user = FirebaseAuth.instance.currentUser;
    await FirebaseFirestore.instance.collection('usuarios').doc(user!.uid).update({
      'nombre': _nombreController.text,
      'intereses': misIntereses,
    });
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Perfil actualizado")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mi Perfil")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)), // Espacio para Foto (RF-005) 
            TextField(controller: _nombreController, decoration: const InputDecoration(labelText: "Nombre")),
            const SizedBox(height: 20),
            const Text("Mis Intereses", style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              children: opcionesIntereses.map((int) => FilterChip(
                label: Text(int),
                selected: misIntereses.contains(int),
                onSelected: (val) {
                  setState(() {
                    val ? misIntereses.add(int) : misIntereses.remove(int);
                  });
                },
              )).toList(),
            ),
            const Spacer(),
            ElevatedButton(onPressed: _actualizarPerfil, child: const Text("GUARDAR CAMBIOS")),
          ],
        ),
      ),
    );
  }
}