import { Router, Response } from 'express';
import { body, validationResult } from 'express-validator';
import { sessionManager } from '../services/sessionManager.js';
import { authenticateHttp, AuthenticatedRequest } from '../middleware/authMiddleware.js';

const router = Router();

/**
 * POST /api/auth/register-device
 * Issue JWT token for a device
 */
router.post(
  '/register-device',
  [
    body('deviceId').isString().notEmpty().withMessage('deviceId is required'),
    body('deviceName').isString().notEmpty().withMessage('deviceName is required'),
  ],
  (req: AuthenticatedRequest, res: Response): void => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      res.status(400).json({ errors: errors.array() });
      return;
    }

    const { deviceId } = req.body;
    const { session, token } = sessionManager.createSession(deviceId);

    res.status(200).json({
      success: true,
      sessionId: session.sessionId,
      deviceId,
      token,
      expiresIn: '7d',
    });
  }
);

/**
 * GET /api/auth/verify
 * Verify active JWT session
 */
router.get('/verify', authenticateHttp, (req: AuthenticatedRequest, res: Response): void => {
  res.status(200).json({
    valid: true,
    deviceId: req.deviceId,
    sessionId: req.sessionId,
  });
});

export default router;
