import { Request, Response, NextFunction } from 'express';
import { IncomingMessage } from 'http';
import { sessionManager } from '../services/sessionManager.js';
import { logger } from '../utils/logger.js';

export interface AuthenticatedRequest extends Request {
  deviceId?: string;
  sessionId?: string;
}

/**
 * Express REST API authentication middleware
 */
export const authenticateHttp = (req: AuthenticatedRequest, res: Response, next: NextFunction): void => {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    res.status(401).json({ error: 'Unauthorized: Missing or invalid token format' });
    return;
  }

  const token = authHeader.split(' ')[1];
  const payload = sessionManager.verifyToken(token);

  if (!payload) {
    res.status(401).json({ error: 'Unauthorized: Invalid or expired token' });
    return;
  }

  req.deviceId = payload.deviceId;
  req.sessionId = payload.sessionId;
  next();
};

/**
 * Extract token from WebSocket connection request query string or protocol header
 */
export const authenticateWsConnection = (req: IncomingMessage): { deviceId?: string; sessionId?: string } | null => {
  try {
    const urlParams = new URLSearchParams(req.url?.split('?')[1] || '');
    const token = urlParams.get('token');

    if (!token) {
      // Try subprotocol or fallback for direct registration
      return null;
    }

    const payload = sessionManager.verifyToken(token);
    if (!payload) return null;

    return { deviceId: payload.deviceId, sessionId: payload.sessionId };
  } catch (err: any) {
    logger.warn(`WS Auth extraction error: ${err.message}`);
    return null;
  }
};
