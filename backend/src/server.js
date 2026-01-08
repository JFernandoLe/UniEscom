import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import './firebase.js'; // asegura inicialización
import notificationsRouter from './routes/notifications.js';
import tokensRouter from './routes/tokens.js';
import eventsRouter from './routes/events.js';
import remindersRouter from './routes/reminders.js';
import cron from 'node-cron';
import { processDueReminders } from './services/reminderService.js';

const app = express();
app.use(cors());
app.use(express.json());

app.get('/health', (_req, res) => res.json({ ok: true }));

app.use('/api/notifications', notificationsRouter);
app.use('/api/tokens', tokensRouter);
app.use('/api/events', eventsRouter);
app.use('/api/reminders', remindersRouter);

// Error handler
// eslint-disable-next-line no-unused-vars
app.use((err, _req, res, _next) => {
  console.error(err);
  res.status(500).json({ error: 'internal_error', message: err.message });
});

const port = process.env.PORT || 3001;
app.listen(port, () => {
  console.log(`[uniescom-backend] listening on http://localhost:${port}`);
  // Ejecuta cada minuto: procesa recordatorios vencidos
  cron.schedule('* * * * *', async () => {
    try {
      const { processed } = await processDueReminders();
      if (processed) {
        console.log(`[reminders] Enviados ${processed} recordatorios pendientes`);
      }
    } catch (e) {
      console.error('[reminders] Error procesando recordatorios:', e);
    }
  });
});
