import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class BackendClient {
  BackendClient();

  String get _baseUrl {
    if (kIsWeb) return 'http://localhost:3001';
    if (Platform.isAndroid) return 'http://10.0.2.2:3001'; // host de la PC desde emulador
    return 'http://localhost:3001';
  }

  /// Envía una notificación push vía backend al usuario actual
  Future<void> sendRegistrationNotification({
    required String uid,
    required String eventId,
    required String eventTitle,
  }) async {
    final url = Uri.parse('$_baseUrl/api/notifications/send');
    final body = jsonEncode({
      'uids': [uid],
      'title': 'Registro confirmado',
      'body': 'Te registraste a "$eventTitle"',
      'data': {
        'eventoId': eventId,
        'tipo': 'registro_evento',
      },
      'save': true,
    });

    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (res.statusCode >= 300) {
      throw Exception('Backend error ${res.statusCode}: ${res.body}');
    }
  }

  /// Notifica al organizador que un usuario se registró
  Future<void> notifyOrganizerRegistration({
    required String eventId,
    required String actorUid,
    required String actorName,
    required String eventTitle,
  }) async {
    final url = Uri.parse('$_baseUrl/api/events/$eventId/notify-organizer-register');
    final body = jsonEncode({
      'actorUid': actorUid,
      'actorName': actorName,
      'eventTitle': eventTitle,
    });

    final res = await http.post(url, headers: {'Content-Type': 'application/json'}, body: body);
    if (res.statusCode >= 300) {
      throw Exception('Backend error ${res.statusCode}: ${res.body}');
    }
  }

  /// Notifica a asistentes que hubo cambios en el evento
  Future<void> notifyEventChange({
    required String eventId,
    required String eventTitle,
    String? message,
    DateTime? newDate,
  }) async {
    final url = Uri.parse('$_baseUrl/api/events/$eventId/notify-change');
    final body = jsonEncode({
      'eventTitle': eventTitle,
      'message': message,
      'newDate': newDate?.toIso8601String(),
    });
    final res = await http.post(url, headers: {'Content-Type': 'application/json'}, body: body);
    if (res.statusCode >= 300) {
      throw Exception('Backend error ${res.statusCode}: ${res.body}');
    }
  }

  /// Programa recordatorios en el backend para este usuario/evento
  Future<void> scheduleServerReminders({
    required String uid,
    required String eventId,
    required String eventTitle,
    required DateTime eventDate,
    int? intervalDays,
    int? testEveryMinutes,
  }) async {
    final url = Uri.parse('$_baseUrl/api/reminders/seed');
    final body = jsonEncode({
      'uid': uid,
      'eventId': eventId,
      'eventTitle': eventTitle,
      'eventDate': eventDate.toIso8601String(),
      if (intervalDays != null) 'intervalDays': intervalDays,
      if (testEveryMinutes != null) 'testEveryMinutes': testEveryMinutes,
    });
    final res = await http.post(url, headers: {'Content-Type': 'application/json'}, body: body);
    if (res.statusCode >= 300) {
      throw Exception('Backend error ${res.statusCode}: ${res.body}');
    }
  }
}
