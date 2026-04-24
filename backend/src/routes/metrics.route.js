import express from 'express';
import { register } from '../lib/metrics.js';

const router = express.Router();

router.get('/', async (req, res) => {  // 👈 changed from '/metrics' to '/'
  try {
    res.set('Content-Type', register.contentType);
    const metrics = await register.metrics();
    res.send(metrics);
  } catch (err) {
    res.status(500).send(err.message);
  }
});

export default router;