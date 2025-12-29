part of 'notifications_bloc.dart';

abstract class NotificationsState extends Equatable {
  const NotificationsState();
  @override
  List<Object?> get props => [];
}

class NotificationsInitial extends NotificationsState {
  const NotificationsInitial();
}

class NotificationsLoading extends NotificationsState {
  const NotificationsLoading();
}

class NotificationsPermissionGranted extends NotificationsState {
  const NotificationsPermissionGranted();
}

class NotificationsPermissionDenied extends NotificationsState {
  const NotificationsPermissionDenied();
}

class NotificationsTokenReceived extends NotificationsState {
  final String token;
  const NotificationsTokenReceived(this.token);

  @override
  List<Object?> get props => [token];
}

class NotificationsPrefsUpdated extends NotificationsState {
  final Map<String, dynamic> prefs;
  const NotificationsPrefsUpdated(this.prefs);

  @override
  List<Object?> get props => [prefs];
}

/// Para cuando llega un mensaje en foreground
class NotificationsForegroundMessage extends NotificationsState {
  final RemoteMessage message;
  const NotificationsForegroundMessage(this.message);

  @override
  List<Object?> get props => [message.messageId];
}

class NotificationsError extends NotificationsState {
  final String message;
  const NotificationsError(this.message);

  @override
  List<Object?> get props => [message];
}
