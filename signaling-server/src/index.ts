import http from 'http';
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import dotenv from 'dotenv';
import authRoutes from './routes/authRoutes.js';
import deviceRoutes from './routes/deviceRoutes.js';
import { SignalingWebSocketServer } from './services/websocketServer.js';
import { logger } from './utils/logger.js';

dotenv.config();

const PORT = parseInt(process.env.PORT || '3000', 10);
const HOST = process.env.HOST || '0.0.0.0';

const app = express();
const server = http.createServer(app);

// Middleware
app.use(helmet());
app.use(cors({ origin: process.env.ALLOWED_ORIGINS || '*' }));
app.use(express.json());

// Request logger
app.use((req, _res, next) => {
  logger.info(`HTTP ${req.method} ${req.url}`);
  next();
});

// REST Routes
app.use('/api/auth', authRoutes);
app.use('/api/devices', deviceRoutes);

// Health check endpoint
app.get('/api/health', (_req, res) => {
  res.status(200).json({
    status: 'ok',
    system: 'Secure Cross-Platform P2P Signaling Server',
    uptime: process.uptime(),
    timestamp: new Date().toISOString(),
  });
});

// Initialize WebSocket Signaling Engine
const signalingEngine = new SignalingWebSocketServer(server);

// Start HTTP + WS Server
server.listen(PORT, HOST, () => {
  logger.info('===============================================================');
  logger.info(`⚡ P2P SIGNALING SERVER ONLINE`);
  logger.info(`📡 HTTP API: http://${HOST}:${PORT}`);
  logger.info(`🔌 WebSocket Engine: ws://${HOST}:${PORT}`);
  logger.info(`🛡️ Environment: ${process.env.NODE_ENV || 'development'}`);
  logger.info('===============================================================');
});

// Graceful shutdown
const shutdown = () => {
  logger.info('Shutting down Signaling Server...');
  signalingEngine.close();
  server.close(() => {
    logger.info('HTTP & WebSocket servers closed cleanly.');
    process.exit(0);
  });
};

process.on('SIGTERM', shutdown);
process.on('SIGINT', shutdown);
