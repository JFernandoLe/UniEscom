import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:uni_escom/services/notifications/bloc/notification_local_service.dart';


part 'notifications_event.dart';
part 'notifications_state.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<String>? _onTokenRefreshSub;

  NotificationsBloc() : super(const NotificationsInitial()) {
    on<NotificationsInitRequested>(_onInit);
    on<NotificationsRequestPermission>(_onRequestPermission);
    on<NotificationsSyncToken>(_onSyncToken);
    on<NotificationsUpdatePrefs>(_onUpdatePrefs);
    on<NotificationsForegroundReceived>(_onForegroundReceived);
  }

  Future<void> _onInit(
    NotificationsInitRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    // Foreground messages (cuando la app está abierta)
    await _onMessageSub?.cancel();
    await _onTokenRefreshSub?.cancel();
    _onMessageSub = FirebaseMessaging.onMessage.listen((message) {
      add(NotificationsForegroundReceived(message));
    });




    // Token refresh (FCM puede cambiar token)
    _onTokenRefreshSub?.cancel();
    _onTokenRefreshSub = _messaging.onTokenRefresh.listen((token) async {
      await _saveToken(token);
    });
  }

  Future<void> _onForegroundReceived(
      NotificationsForegroundReceived event,
      Emitter<NotificationsState> emit,
    ) async {
      // 1. Emitimos estado para UI (BlocListener opcional)
      emit(NotificationsForegroundMessage(event.message));

      // 2. Validar usuario
      final user = _auth.currentUser;
      if (user == null) return;

      // 3. Leer preferencias (RF-017)
      final doc = await _firestore.collection('usuarios').doc(user.uid).get();
      final notifs = Map<String, dynamic>.from(doc.data()?['notificaciones'] ?? {});
      final enabled = (notifs['enabled'] ?? true) == true;

      if (!enabled) return;

      // 4. Extraer título y cuerpo
      final title =
          event.message.notification?.title ??
          event.message.data['title'] ??
          'UniEscom';

      final body =
          event.message.notification?.body ??
          event.message.data['body'] ??
          'Tienes una notificación';

      // 5. Mostrar notificación LOCAL (foreground)
      await LocalNotificationService.instance.show(
        title: title,
        body: body,
      );
  }

  Future<void> _onRequestPermission(
    NotificationsRequestPermission event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      emit(const NotificationsLoading());

      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        emit(const NotificationsPermissionGranted());
        add(const NotificationsSyncToken());
      } else {
        emit(const NotificationsPermissionDenied());
      }
    } catch (e) {
      emit(NotificationsError(e.toString()));
    }
  }

  Future<void> _onSyncToken(
    NotificationsSyncToken event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        emit(const NotificationsError('Usuario no autenticado'));
        return;
      }

      final token = await _messaging.getToken();
      if (token == null) {
        emit(const NotificationsError('No se pudo obtener el token FCM'));
        return;
      }

      await _saveToken(token);
      emit(NotificationsTokenReceived(token));
    } catch (e) {
      emit(NotificationsError(e.toString()));
    }
  }

  Future<void> _saveToken(String token) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('usuarios').doc(user.uid).set({
      'fcm_token': token,
      'token_updated_at': FieldValue.serverTimestamp(),
      // RF-017: preferencias por defecto (solo si no existen, merge no pisa lo demás)
      'notificaciones': {
        'enabled': true,
        'recordatorios_eventos': true,     // RF-015
        'avisar_organizador': true,        // RF-016
        'cambios_evento': true,            // RF-014 (si la implementas)
      },
    }, SetOptions(merge: true));
  }

  Future<void> _onUpdatePrefs(
    NotificationsUpdatePrefs event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        emit(const NotificationsError('Usuario no autenticado'));
        return;
      }

      await _firestore.collection('usuarios').doc(user.uid).set({
        'notificaciones': event.prefs,
      }, SetOptions(merge: true));

      emit(NotificationsPrefsUpdated(event.prefs));
    } catch (e) {
      emit(NotificationsError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _onMessageSub?.cancel();
    _onTokenRefreshSub?.cancel();
    return super.close();
  }
}
