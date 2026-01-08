import { db } from '../firebase.js';
import { sendNotificationToUids } from './notificationService.js';

const REMINDERS = 'recordatorios';

export async function seedEventReminders({
  uid,
  eventId,
  eventTitle,
  eventDate, // ISO string o Date
  intervalDays = 3,
  testEveryMinutes, // opcional: modo prueba
}) {
  const sendAtDates = [];
  const now = new Date();
  const evt = eventDate instanceof Date ? eventDate : new Date(eventDate);

  if (testEveryMinutes && testEveryMinutes > 0) {
    for (let i = 1; i <= 6; i++) {
      sendAtDates.push(new Date(now.getTime() + i * testEveryMinutes * 60000));
    }
  } else {
    // 9:00 AM locales cada N días hasta 1 día antes
    let cursor = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 9, 0, 0, 0);
    if (cursor <= now) cursor = new Date(cursor.getTime() + 24 * 3600000);
    const before = new Date(evt.getTime() - 24 * 3600000);
    while (cursor < before) {
      sendAtDates.push(new Date(cursor));
      cursor = new Date(cursor.getTime() + intervalDays * 24 * 3600000);
    }
    // Dos horas antes del evento
    const twoHoursBefore = new Date(evt.getTime() - 2 * 3600000);
    if (twoHoursBefore > now) sendAtDates.push(twoHoursBefore);
  }

  const batch = db.batch();
  sendAtDates.forEach((dt) => {
    const ref = db.collection(REMINDERS).doc();
    batch.set(ref, {
      uid,
      eventId,
      eventTitle,
      sendAt: dt,
      status: 'pending', // pending | sent | failed
      createdAt: new Date(),
      type: 'event_reminder',
    });
  });
  await batch.commit();

  return { created: sendAtDates.length };
}

export async function processDueReminders(limit = 50) {
  const now = new Date();
  const snap = await db
    .collection(REMINDERS)
    .where('status', '==', 'pending')
    .where('sendAt', '<=', now)
    .limit(limit)
    .get();

  if (snap.empty) return { processed: 0 };

  let processed = 0;
  for (const doc of snap.docs) {
    const r = doc.data();
    try {
      await sendNotificationToUids({
        uids: [r.uid],
        title: 'Recordatorio de evento',
        body: `"${r.eventTitle}" está próximo`,
        data: { tipo: 'recordatorio_evento', eventoId: r.eventId },
        save: true,
      });
      await doc.ref.update({ status: 'sent', sentAt: new Date() });
      processed++;
    } catch (e) {
      await doc.ref.update({ status: 'failed', error: String(e), updatedAt: new Date() });
    }
  }
  return { processed };
}
