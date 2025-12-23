import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uni_escom/services/student/event_detail_screen.dart';
import '../../models/event_model.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("UniEscom - Eventos",style:TextStyle(color: Colors.white),),
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Escucha la colección de eventos en tiempo real
        stream: FirebaseFirestore.instance.collection('eventos').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No hay eventos disponibles por ahora."));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              EventModel evento = EventModel.fromFirestore(snapshot.data!.docs[index]);
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.event, color: Colors.blue),
                  title: Text(evento.titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${evento.lugar}\n${evento.hora}"),
                  isThreeLine: true,
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
    );
  }
}