import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String titulo;
  final String descripcion;
  final DateTime fecha;
  final String hora;
  final String lugar;
  final String organizador;
  final String categoria;

  EventModel({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.fecha,
    required this.hora,
    required this.lugar,
    required this.organizador,
    required this.categoria,
  });

  // Mapeo de datos desde Firestore
  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return EventModel(
      id: doc.id,
      titulo: data['titulo'] ?? '',
      descripcion: data['descripcion'] ?? '',
      fecha: (data['fecha'] as Timestamp).toDate(),
      hora: data['hora'] ?? '',
      lugar: data['lugar'] ?? '',
      organizador: data['organizador'] ?? '',
      categoria: data['categoria'] ?? 'General',
    );
  }
}