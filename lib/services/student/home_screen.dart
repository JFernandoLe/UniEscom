import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uni_escom/services/auth/login_screen.dart';
import 'package:uni_escom/services/auth_service.dart';
import 'package:uni_escom/services/organizer/create_event_screen.dart';
import 'package:uni_escom/services/student/event_detail_screen.dart';
import 'package:uni_escom/services/student/profile_screen.dart';
import 'package:uni_escom/services/admin/admin_dashboard_screen.dart';
import '../../models/event_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userRol = 'estudiante';

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  Future<void> _checkRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).get();
      if (!mounted) return;
      setState(() {
        userRol = doc.data()?['rol'] ?? 'estudiante';
      });
    }
  }

  String categoriaSeleccionada = 'Todo';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Query query = FirebaseFirestore.instance.collection('eventos');
    if (categoriaSeleccionada != 'Todo') {
      query = query.where('categoria', isEqualTo: categoriaSeleccionada);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("UniEscom - Eventos"), // ya no forzamos color
        actions: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('usuarios')
                .doc(FirebaseAuth.instance.currentUser?.uid)
                .snapshots(),
            builder: (context, snap) {
              String? fotoUrl;

              if (snap.hasData && snap.data!.exists) {
                final data = snap.data!.data() as Map<String, dynamic>?;
                fotoUrl = (data?['fotoUrl'] ?? '').toString();
                if (fotoUrl != null && fotoUrl.trim().isEmpty) fotoUrl = null;
              }

              return IconButton(
                tooltip: 'Mi perfil',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                ),
                icon: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.white.withOpacity(0.15),
                  backgroundImage: (fotoUrl != null) ? NetworkImage(fotoUrl) : null,
                  child: (fotoUrl == null)
                      ? const Icon(Icons.person_outline, color: Colors.white)
                      : null,
                ),
              );
            },
          ),

          // 2) Aquí va el IF (solo admin)
          if (userRol == 'admin')
            IconButton(
              icon: const Icon(Icons.admin_panel_settings_outlined),
              tooltip: 'Admin dashboard',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
              ),
            ),

          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () async {
              final authService = AuthService();
              await authService.cerrarSesion();

              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],

      ),

      floatingActionButton: userRol == 'organizador'
          ? FloatingActionButton(
              // usa el color del theme
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
              child: const Icon(Icons.add),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreateEventScreen()),
                );
              },
            )
          : null,

      body: Column(
        children: [
          // FILTROS
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.06),
              border: Border(
                bottom: BorderSide(color: Colors.black.withOpacity(0.06)),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['Todo', 'Académico', 'Cultural', 'Deportivo'].map((cat) {
                  final selected = categoriaSeleccionada == cat;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(cat),
                      selected: selected,
                      onSelected: (_) => setState(() => categoriaSeleccionada = cat),
                      // Material 3 + theme
                      selectedColor: cs.primary.withOpacity(0.18),
                      checkmarkColor: cs.primary,
                      side: BorderSide(color: Colors.black.withOpacity(0.10)),
                      labelStyle: TextStyle(
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected ? cs.primary : cs.onSurface.withOpacity(0.75),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // LISTA
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: cs.primary),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.event_busy, size: 44, color: cs.onSurface.withOpacity(0.40)),
                          const SizedBox(height: 10),
                          Text(
                            "No hay eventos",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: cs.onSurface),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Categoría: $categoriaSeleccionada",
                            style: TextStyle(color: cs.onSurface.withOpacity(0.65)),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final evento = EventModel.fromFirestore(snapshot.data!.docs[index]);

                    return Card(
                      elevation: 6,
                      shadowColor: Colors.black12,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: cs.primary.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.calendar_today, color: cs.primary, size: 20),
                        ),
                        title: Text(
                          evento.titulo,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            "${evento.lugar}\n${evento.hora}",
                            style: TextStyle(color: cs.onSurface.withOpacity(0.70)),
                          ),
                        ),
                        isThreeLine: true,
                        trailing: Icon(Icons.chevron_right, color: cs.onSurface.withOpacity(0.45)),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => EventDetailScreen(evento: evento)),
                          );
                        },
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
