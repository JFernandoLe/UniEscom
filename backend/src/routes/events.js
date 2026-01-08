import { Router } from 'express';
import { asyncHandler } from '../middlewares/asyncHandler.js';
import { notifyOrganizerRegistration, notifyEventChange } from '../services/notificationService.js';

const router = Router();

// Notificar al organizador cuando alguien se registra
// POST /api/events/:eventId/notify-organizer-register
// body: { actorUid: string, actorName: string, eventTitle: string }
router.post('/:eventId/notify-organizer-register', asyncHandler(async (req, res) => {
  const { eventId } = req.params;
  const { actorUid, actorName, eventTitle } = req.body || {};
  if (!actorUid || !actorName || !eventTitle) return res.status(400).json({ error: 'actorUid, actorName y eventTitle son requeridos' });
  const result = await notifyOrganizerRegistration({ eventId, actorUid, actorName, eventTitle });
  res.json(result);
}));

// Notificar a los asistentes cambios del evento
// POST /api/events/:eventId/notify-change
// body: { eventTitle: string, message?: string, newDate?: string }
router.post('/:eventId/notify-change', asyncHandler(async (req, res) => {
  const { eventId } = req.params;
  const { eventTitle, message, newDate } = req.body || {};
  if (!eventTitle) return res.status(400).json({ error: 'eventTitle es requerido' });
  const result = await notifyEventChange({ eventId, eventTitle, message, newDate });
  res.json(result);
}));

export default router;
