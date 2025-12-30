import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _searchCtrl = TextEditingController();
  String _filtroRol = 'Todos';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<bool> _soyAdmin() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    final doc = await FirebaseFirestore.instance.collection('usuarios').doc(uid).get();
    final rol = (doc.data()?['rol'] ?? 'estudiante').toString();
    return rol == 'admin';
  }

  Future<void> _cambiarRol({
    required String userId,
    required String nuevoRol,
    required String rolActual,
  }) async {
    // Protección: no permitir bajarte a ti mismo si eres admin (evita quedarte sin admin)
    final miUid = FirebaseAuth.instance.currentUser?.uid;
    if (miUid != null && miUid == userId && rolActual == 'admin' && nuevoRol != 'admin') {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No puedes quitarte el rol de admin a ti mismo.")),
      );
      return;
    }

    // Seguridad extra en cliente (igual debes poner reglas)
    final admin = await _soyAdmin();
    if (!admin) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Acceso denegado. Solo admin puede cambiar roles.")),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('usuarios').doc(userId).update({
      'rol': nuevoRol,
      'rol_updated_at': FieldValue.serverTimestamp(),
      'rol_updated_by': miUid,
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Rol actualizado a: $nuevoRol ✅"), backgroundColor: Colors.green),
    );
  }

  bool _matchSearch(Map<String, dynamic> data) {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return true;

    final nombre = (data['nombre'] ?? '').toString().toLowerCase();
    final correo = (data['correo'] ?? data['email'] ?? '').toString().toLowerCase(); // compat
    return nombre.contains(q) || correo.contains(q);
  }

  bool _matchRol(Map<String, dynamic> data) {
    if (_filtroRol == 'Todos') return true;
    final rol = (data['rol'] ?? 'estudiante').toString();
    return rol == _filtroRol;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Admin - Usuarios")),
      body: Column(
        children: [
          // Barra de búsqueda + filtro
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    hintText: "Buscar por nombre o correo",
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.filter_alt_outlined),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _filtroRol,
                        items: const [
                          DropdownMenuItem(value: 'Todos', child: Text("Todos")),
                          DropdownMenuItem(value: 'estudiante', child: Text("estudiante")),
                          DropdownMenuItem(value: 'organizador', child: Text("organizador")),
                          DropdownMenuItem(value: 'admin', child: Text("admin")),
                        ],
                        onChanged: (v) => setState(() => _filtroRol = v ?? 'Todos'),
                        decoration: const InputDecoration(
                          labelText: "Filtrar por rol",
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Lista
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('usuarios')
                  .orderBy('nombre')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: cs.primary));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No hay usuarios."));
                }

                final docs = snapshot.data!.docs;

                // Filtrado local (simple y suficiente para demo)
                final filtrados = docs.where((d) {
                  final data = d.data() as Map<String, dynamic>? ?? {};
                  return _matchSearch(data) && _matchRol(data);
                }).toList();

                if (filtrados.isEmpty) {
                  return const Center(child: Text("No hay coincidencias."));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtrados.length,
                  itemBuilder: (context, i) {
                    final doc = filtrados[i];
                    final data = doc.data() as Map<String, dynamic>? ?? {};

                    final nombre = (data['nombre'] ?? 'Usuario').toString();
                    final correo = (data['correo'] ?? data['email'] ?? '').toString();
                    final rolActual = (data['rol'] ?? 'estudiante').toString();

                    return Card(
                      elevation: 4,
                      shadowColor: Colors.black12,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: cs.primary.withOpacity(0.12),
                          child: Icon(Icons.person, color: cs.primary),
                        ),
                        title: Text(nombre, style: const TextStyle(fontWeight: FontWeight.w800)),
                        subtitle: Text(
                          correo.isEmpty ? "Sin correo" : correo,
                          style: TextStyle(color: cs.onSurface.withOpacity(0.65)),
                        ),
                        trailing: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: rolActual,
                            items: const [
                              DropdownMenuItem(value: 'estudiante', child: Text("estudiante")),
                              DropdownMenuItem(value: 'organizador', child: Text("organizador")),
                              DropdownMenuItem(value: 'admin', child: Text("admin")),
                            ],
                            onChanged: (nuevo) async {
                              if (nuevo == null || nuevo == rolActual) return;

                              // Confirmación
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text("Cambiar rol"),
                                  content: Text("¿Cambiar a \"$nuevo\"?"),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text("Cancelar"),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: const Text("Confirmar"),
                                    ),
                                  ],
                                ),
                              );

                              if (ok != true) return;

                              await _cambiarRol(
                                userId: doc.id,
                                nuevoRol: nuevo,
                                rolActual: rolActual,
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
