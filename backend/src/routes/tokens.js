import { Router } from 'express';
import { asyncHandler } from '../middlewares/asyncHandler.js';
import { db } from '../firebase.js';

const router = Router();

// POST /api/tokens  body: { uid: string, token: string }
router.post('/', asyncHandler(async (req, res) => {
  const { uid, token } = req.body || {};
  if (!uid || !token) return res.status(400).json({ error: 'uid y token son requeridos' });

  await db.collection('usuarios').doc(uid).set({
    fcm_token: token,
    token_updated_at: new Date(),
  }, { merge: true });

  res.status(204).end();
}));

export default router;
