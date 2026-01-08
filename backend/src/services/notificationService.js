import { db, messaging } from '../firebase.js';

const USERS_COLLECTION = 'usuarios';
const NOTIFS_COLLECTION = 'notificaciones';

export async function saveNotification({ uid, title, body, data = {} }) {
  const now = new Date();
  const doc = await db.collection(NOTIFS_COLLECTION).add({
    uid,
    title,
    body,
    data,
    read: false,
    sentAt: now,
  });
  return { id: doc.id, uid, title, body, data, read: false, sentAt: now };
}

export async function listNotificationsByUser({ uid, limit = 20, before }) {
  let ref = db
    .collection(NOTIFS_COLLECTION)
    .where('uid', '==', uid)
    .orderBy('sentAt', 'desc')
    .limit(Number(limit));

  if (before) {
    const beforeDoc = await db.collection(NOTIFS_COLLECTION).doc(before).get();
    if (beforeDoc.exists) ref = ref.startAfter(beforeDoc);
  }

  const snap = await ref.get();
  return snap.docs.map((d) => ({ id: d.id, ...d.data() }));
}

async function getTokensForUids(uids) {
  if (!Array.isArray(uids) || uids.length === 0) return [];
  const refs = uids.map((uid) => db.collection(USERS_COLLECTION).doc(uid));
  const docs = await db.getAll(...refs);
  const tokens = [];
  docs.forEach((doc) => {
    const data = doc.data() || {};
    if (data.fcm_token) tokens.push(data.fcm_token);
  });
  return tokens;
}

export async function sendNotificationToUids({ uids, title, body, data = {} , save = true}) {
  // 1) opcionalmente persistimos una notificación por usuario
  const saved = [];
  if (save) {
    for (const uid of uids) {
      const n = await saveNotification({ uid, title, body, data });
      saved.push(n);
    }
  }

  // 2) Obtener tokens
  const tokens = await getTokensForUids(uids);
  if (tokens.length === 0) {
    return { saved, sent: { successCount: 0, failureCount: 0, responses: [] } };
  }

  // 3) Enviar multicast via FCM
  const message = {
    tokens,
    notification: { title, body },
    data: Object.fromEntries(Object.entries(data).map(([k, v]) => [k, String(v)])),
  };

  const response = await messaging.sendEachForMulticast(message);
  return { saved, sent: response };
}

export async function getOrganizerUidForEvent(eventId) {
  const doc = await db.collection('eventos').doc(eventId).get();
  if (!doc.exists) return null;
  const data = doc.data() || {};
  return data.organizador || null;
}

export async function getAttendeeUidsForEvent(eventId) {
  const snap = await db.collection('asistencias')
    .where('id_evento', '==', eventId)
    .select('id_usuario')
    .get();
  const uids = [];
  snap.forEach(d => {
    const v = d.data();
    if (v && v.id_usuario) uids.push(v.id_usuario);
  });
  return uids;
}

export async function notifyOrganizerRegistration({ eventId, actorUid, actorName, eventTitle }) {
  const organizerUid = await getOrganizerUidForEvent(eventId);
  if (!organizerUid) return { sent: null, reason: 'no_organizer' };

  const title = 'Nuevo registro al evento';
  const body = `${actorName} se registró a "${eventTitle}"`;
  const data = { tipo: 'registro_usuario', eventoId: eventId, actorUid };

  return await sendNotificationToUids({ uids: [organizerUid], title, body, data, save: true });
}

export async function notifyEventChange({ eventId, eventTitle, message, newDate }) {
  const uids = await getAttendeeUidsForEvent(eventId);
  if (uids.length === 0) return { sent: null, reason: 'no_attendees' };

  const title = 'Actualización de evento';
  const body = message || `El evento "${eventTitle}" fue actualizado`;
  const data = { tipo: 'cambio_evento', eventoId: eventId, newDate: newDate ? String(newDate) : '' };

  return await sendNotificationToUids({ uids, title, body, data, save: true });
}

