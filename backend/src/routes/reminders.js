import express from 'express';
import { seedEventReminders } from '../services/reminderService.js';

const router = express.Router();

// POST /api/reminders/seed
router.post('/seed', async (req, res) => {
  try {
    const { uid, eventId, eventTitle, eventDate, intervalDays, testEveryMinutes } = req.body || {};
    if (!uid || !eventId || !eventTitle || !eventDate) {
      return res.status(400).json({ error: 'uid, eventId, eventTitle y eventDate son requeridos' });
    }
    const out = await seedEventReminders({ uid, eventId, eventTitle, eventDate, intervalDays, testEveryMinutes });
    res.json(out);
  } catch (err) {
    res.status(500).json({ error: err?.message || String(err) });
  }
});

export default router;
