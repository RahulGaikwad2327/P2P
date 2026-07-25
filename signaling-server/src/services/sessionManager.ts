import jwt from 'jsonwebtoken';
import { v4 as uuidv4 } from 'uuid';
import { Session, JwtPayload } from '../types/index.js';
import { logger } from '../utils/logger.js';

const JWT_SECRET = process.env.JWT_SECRET || 'super_secret_p2p_signaling_key_2026_change_in_production';
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '7d';

class SessionManager {
  private sessions: Map<string, Session> = new Map(); // sessionId -> Session

  /**
   * Create a new authenticated session and generate a JWT token
   */
  public createSession(deviceId: string): { session: Session; token: string } {
    const sessionId = uuidv4();
    const payload: JwtPayload = {
      deviceId,
      sessionId,
      type: 'device_access',
    };

    const token = jwt.sign(payload, JWT_SECRET, { expiresIn: JWT_EXPIRES_IN as any });

    const session: Session = {
      sessionId,
      deviceId,
      token,
      connectedAt: new Date(),
      isActive: true,
    };

    this.sessions.set(sessionId, session);
    logger.info(`Session created: ${sessionId} for device: ${deviceId}`);

    return { session, token };
  }

  /**
   * Verify and decode a JWT token
   */
  public verifyToken(token: string): JwtPayload | null {
    try {
      const decoded = jwt.verify(token, JWT_SECRET) as JwtPayload;
      return decoded;
    } catch (err: any) {
      logger.warn(`JWT Verification failed: ${err.message}`);
      return null;
    }
  }

  /**
   * Get an active session by ID
   */
  public getSession(sessionId: string): Session | undefined {
    return this.sessions.get(sessionId);
  }

  /**
   * Terminate a session
   */
  public invalidateSession(sessionId: string): void {
    const session = this.sessions.get(sessionId);
    if (session) {
      session.isActive = false;
      this.sessions.delete(sessionId);
      logger.info(`Session invalidated: ${sessionId}`);
    }
  }

  /**
   * Clean up inactive sessions
   */
  public cleanup(): void {
    for (const [sessionId, session] of this.sessions.entries()) {
      if (!session.isActive) {
        this.sessions.delete(sessionId);
      }
    }
  }
}

export const sessionManager = new SessionManager();
