part of 'notifications_bloc.dart';

abstract class NotificationsEvent extends Equatable {
  const NotificationsEvent();
  @override
  List<Object?> get props => [];
}

class NotificationsInitRequested extends NotificationsEvent {
  const NotificationsInitRequested();
}

class NotificationsRequestPermission extends NotificationsEvent {
  const NotificationsRequestPermission();
}

class NotificationsSyncToken extends NotificationsEvent {
  const NotificationsSyncToken();
}



/// RF-017 preferencias
class NotificationsUpdatePrefs extends NotificationsEvent {
  final Map<String, dynamic> prefs;
  const NotificationsUpdatePrefs(this.prefs);

  @override
  List<Object?> get props => [prefs];
}

class NotificationsForegroundReceived extends NotificationsEvent {
  final RemoteMessage message;
  const NotificationsForegroundReceived(this.message);

  @override
  List<Object?> get props => [message.messageId];
}
