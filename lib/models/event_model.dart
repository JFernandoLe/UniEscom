import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String titulo;
  final String descripcion;
  final DateTime fechaHora;
  final DateTime fecha;
  final String hora;
  final String lugar;
  final String organizador;
  final String categoria;

  EventModel({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.fechaHora,
    required this.fecha,
    required this.hora,
    required this.lugar,
    required this.organizador,
    required this.categoria,
  });


  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    final tsFechaHora = data['fechaHora'] as Timestamp?;
    final tsFecha = data['fecha'] as Timestamp?;

    final fechaHora = (tsFechaHora ?? tsFecha ?? Timestamp.now()).toDate();
    return EventModel(
      id: doc.id,
      titulo: data['titulo'] ?? '',
      descripcion: data['descripcion'] ?? '',
      
      fechaHora: fechaHora,

      fecha: (tsFecha ?? Timestamp.fromDate(DateTime(fechaHora.year, fechaHora.month, fechaHora.day))).toDate(),
      hora: (data['hora'] ?? '${fechaHora.hour.toString().padLeft(2,'0')}:${fechaHora.minute.toString().padLeft(2,'0')}').toString(),

      lugar: data['lugar'] ?? '',
      organizador: data['organizador'] ?? '',
      categoria: data['categoria'] ?? 'General',
    );
  }
}