import 'package:uni_escom/services/notifications/reminder_scheduler.dart';

class NotificationHooks {
  NotificationHooks._();

  static Future<void> onEventRegistration({
    required String eventId,
    required String eventTitle,
    required DateTime eventDate,
  }) async {
    // Notificación inmediata de confirmación
    await ReminderScheduler.instance.onEventRegistered(eventTitle: eventTitle);

    // Programar recordatorios periódicos + recordatorio final
    await ReminderScheduler.instance.scheduleEventReminders(
      eventId: eventId,
      eventTitle: eventTitle,
      eventDate: eventDate,
      intervalDays: 3,
    );
  }
}
