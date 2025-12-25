import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uni_escom/services/auth/login_screen.dart';
import 'package:uni_escom/services/auth_service.dart';
import 'package:uni_escom/services/organizer/create_event_screen.dart';
import 'package:uni_escom/services/student/event_detail_screen.dart';
import 'package:uni_escom/services/student/profile_screen.dart'; 
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
  // 2. Función para leer el rol desde Firestore
    void _checkRole() async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).get();
        if (mounted) {
          setState(() {
            userRol = doc.data()?['rol'] ?? 'estudiante';
          });
        }
      }
    }
  // Categoría seleccionada por defecto
  String categoriaSeleccionada = 'Todo';
  
  @override
  Widget build(BuildContext context) {
    // Definimos la consulta base a Firestore
    Query query = FirebaseFirestore.instance.collection('eventos');
    
    // Si no es 'Todo', filtramos por la categoría seleccionada (RF-007)
    if (categoriaSeleccionada != 'Todo') {
      query = query.where('categoria', isEqualTo: categoriaSeleccionada);
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("UniEscom - Eventos", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Cerrar Sesión',
            onPressed: () async {
              final authService = AuthService();
              await authService.cerrarSesion();
              
              if (mounted) {
                // Regresamos al Login y limpiamos el historial de navegación
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      floatingActionButton: userRol == 'organizador' 
      ? FloatingActionButton(
          backgroundColor: Colors.blue,
          child: const Icon(Icons.add, color: Colors.white),
          onPressed: () {
            // Navegar a la pantalla de creación
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CreateEventScreen()),
            );
          },
        )
      : null,
      body: Column(
        children: [
          // --- SECCIÓN DE FILTROS (RF-007) ---
          Container(
            color: Colors.blue.withOpacity(0.1),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              child: Row(
                children: ['Todo', 'Académico', 'Cultural', 'Deportivo'].map((cat) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(cat),
                      selected: categoriaSeleccionada == cat,
                      selectedColor: Colors.blue.withOpacity(0.3),
                      checkmarkColor: Colors.blue,
                      onSelected: (bool selected) {
                        setState(() {
                          categoriaSeleccionada = cat;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          
          // --- LISTA DE EVENTOS (RF-006) ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: query.snapshots(), // Escucha la consulta filtrada
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text("No hay eventos en la categoría: $categoriaSeleccionada"),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 10),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    EventModel evento = EventModel.fromFirestore(snapshot.data!.docs[index]);
                    
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.calendar_today, color: Colors.blue),
                        ),
                        title: Text(evento.titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("${evento.lugar}\n${evento.hora}"),
                        isThreeLine: true,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EventDetailScreen(evento: evento),
                            ),
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