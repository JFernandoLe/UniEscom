import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
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
  
  // ESTADOS DE FILTRADO
  String categoriaSeleccionada = 'Todo';
  String ubicacionSeleccionada = 'Todas';
  DateTime? fechaSeleccionada;

  // Lista dinámica de ubicaciones
  List<String> listaUbicaciones = ['Todas'];

  @override
  void initState() {
    super.initState();
    _checkRole();
    _cargarUbicaciones(); // Carga las ubicaciones desde Firebase
  }

  Future<void> _checkRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).get();
      if (!mounted) return;
      setState(() {
        final data = doc.data() ?? {};
        userRol = (data['rol'] ?? 'estudiante').toString();
      });
    }
  }

  // OBTIENE UBICACIONES ÚNICAS DE LA COLECCIÓN DE EVENTOS
  Future<void> _cargarUbicaciones() async {
    final snapshot = await FirebaseFirestore.instance.collection('eventos').get();
    final sedes = snapshot.docs
        .map((doc) => doc['lugar'].toString())
        .toSet() // Elimina duplicados
        .toList();
    
    if (mounted) {
      setState(() {
        listaUbicaciones = ['Todas', ...sedes];
      });
    }
  }

  void _limpiarFiltros() {
    setState(() {
      categoriaSeleccionada = 'Todo';
      ubicacionSeleccionada = 'Todas';
      fechaSeleccionada = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // CONSTRUCCIÓN DE LA QUERY CORREGIDA
    Query query = FirebaseFirestore.instance.collection('eventos');

    if (categoriaSeleccionada != 'Todo') {
      query = query.where('categoria', isEqualTo: categoriaSeleccionada);
    }

    if (ubicacionSeleccionada != 'Todas') {
      query = query.where('lugar', isEqualTo: ubicacionSeleccionada);
    }

    if (fechaSeleccionada != null) {
      // Ajuste al nombre del campo 'fechaHora' según tu captura
      DateTime inicio = DateTime(fechaSeleccionada!.year, fechaSeleccionada!.month, fechaSeleccionada!.day);
      DateTime fin = inicio.add(const Duration(days: 1));
      
      query = query
          .where('fechaHora', isGreaterThanOrEqualTo: Timestamp.fromDate(inicio))
          .where('fechaHora', isLessThan: Timestamp.fromDate(fin));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("UniEscom - Eventos"),
        actions: [
          _buildProfileButton(),
          if (userRol == 'admin') _buildAdminButton(),
          _buildLogoutButton(),
        ],
      ),
      floatingActionButton: (userRol == 'organizador' || userRol == 'admin')
          ? FloatingActionButton(
              backgroundColor: cs.primary,
              child: const Icon(Icons.add),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateEventScreen())),
            )
          : null,
      body: Column(
        children: [
          // PANEL DE FILTROS
          Container(
            padding: const EdgeInsets.all(12),
            color: cs.primary.withOpacity(0.05),
            child: Column(
              children: [
                _buildCategoryFilter(cs),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Filtro Ubicación Dinámico
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: ubicacionSeleccionada,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Ubicación', border: OutlineInputBorder(), isDense: true),
                        items: listaUbicaciones.map((u) => DropdownMenuItem(value: u, child: Text(u, style: const TextStyle(fontSize: 12)))).toList(),
                        onChanged: (val) => setState(() => ubicacionSeleccionada = val!),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Filtro Fecha
                    Expanded(
                      flex: 2,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(
                          fechaSeleccionada == null ? 'Fecha' : DateFormat('dd/MM/yy').format(fechaSeleccionada!),
                          style: const TextStyle(fontSize: 12),
                        ),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2024),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) setState(() => fechaSeleccionada = picked);
                        },
                      ),
                    ),
                    if (categoriaSeleccionada != 'Todo' || ubicacionSeleccionada != 'Todas' || fechaSeleccionada != null)
                      IconButton(icon: const Icon(Icons.filter_list_off, color: Colors.red), onPressed: _limpiarFiltros),
                  ],
                ),
              ],
            ),
          ),

          // LISTADO
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}. Revisa si falta un índice en la consola de Firebase."));
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No hay eventos con estos filtros."));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final evento = EventModel.fromFirestore(snapshot.data!.docs[index]);
                    return _buildEventCard(evento, cs);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---

  Widget _buildCategoryFilter(ColorScheme cs) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ['Todo', 'Académico', 'Cultural', 'Deportivo'].map((cat) {
          final selected = categoriaSeleccionada == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(cat),
              selected: selected,
              onSelected: (_) => setState(() => categoriaSeleccionada = cat),
              selectedColor: cs.primary.withOpacity(0.2),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEventCard(EventModel evento, ColorScheme cs) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(evento.titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("${evento.lugar}\n${evento.hora}"),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailScreen(evento: evento))),
      ),
    );
  }

  Widget _buildProfileButton() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('usuarios').doc(FirebaseAuth.instance.currentUser?.uid).snapshots(),
      builder: (context, snap) {
        String? fotoUrl;
        if (snap.hasData && snap.data!.exists) {
          fotoUrl = (snap.data!.data() as Map<String, dynamic>?)?['fotoUrl'];
        }
        return IconButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
          icon: CircleAvatar(
            radius: 14,
            backgroundImage: (fotoUrl != null && fotoUrl.isNotEmpty) ? NetworkImage(fotoUrl) : null,
            child: (fotoUrl == null || fotoUrl.isEmpty) ? const Icon(Icons.person, size: 18) : null,
          ),
        );
      },
    );
  }

  Widget _buildAdminButton() => IconButton(
    icon: const Icon(Icons.admin_panel_settings),
    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen())),
  );

  Widget _buildLogoutButton() => IconButton(
    icon: const Icon(Icons.logout),
    onPressed: () async {
      await AuthService().cerrarSesion();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
    },
  );
}