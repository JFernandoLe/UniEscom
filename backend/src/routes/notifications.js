import { Router } from 'express';
import { asyncHandler } from '../middlewares/asyncHandler.js';
import { saveNotification, listNotificationsByUser, sendNotificationToUids } from '../services/notificationService.js';

const router = Router();

// POST /api/notifications/send
// body: { uids: string[], title: string, body: string, data?: Record<string,string|number|boolean>, save?: boolean }
router.post('/send', asyncHandler(async (req, res) => {
  const { uids, title, body, data = {}, save = true } = req.body || {};
  if (!Array.isArray(uids) || uids.length === 0) {
    return res.status(400).json({ error: 'uids es requerido y debe ser array no vacío' });
  }
  if (!title || !body) return res.status(400).json({ error: 'title y body son requeridos' });

  const result = await sendNotificationToUids({ uids, title, body, data, save });
  res.json(result);
}));

// POST /api/notifications
// body: { uid: string, title: string, body: string, data?: Record<string, any> }
router.post('/', asyncHandler(async (req, res) => {
  const { uid, title, body, data = {} } = req.body || {};
  if (!uid || !title || !body) return res.status(400).json({ error: 'uid, title y body son requeridos' });
  const n = await saveNotification({ uid, title, body, data });
  res.status(201).json(n);
}));

// GET /api/notifications/:uid?limit=20&before={docId}
router.get('/:uid', asyncHandler(async (req, res) => {
  const { uid } = req.params;
  const { limit, before } = req.query;
  const list = await listNotificationsByUser({ uid, limit: limit || 20, before });
  res.json(list);
}));

export default router;
