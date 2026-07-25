import { Server as HttpServer } from 'http';
import { WebSocketServer, WebSocket } from 'ws';
import { deviceRegistry } from './deviceRegistry.js';
import { sessionManager } from './sessionManager.js';
import {
  AuthenticatedWebSocket,
  SignalingMessage,
  SignalingMessageType,
  Device,
} from '../types/index.js';
import { logger } from '../utils/logger.js';

export class SignalingWebSocketServer {
  private wss: WebSocketServer;
  private pingInterval: NodeJS.Timeout | null = null;

  constructor(server: HttpServer) {
    this.wss = new WebSocketServer({ server });
    this.init();
  }

  private init(): void {
    logger.info('Initializing WebSocket Signaling Engine...');

    this.wss.on('connection', (ws: AuthenticatedWebSocket, req) => {
      const clientIp = req.socket.remoteAddress || 'unknown';
      ws.remoteIp = clientIp;
      ws.isAlive = true;

      logger.info(`New WebSocket client connected from ${clientIp}`);

      // Handle incoming messages
      ws.on('message', (data: Buffer) => {
        this.handleMessage(ws, data.toString());
      });

      // Handle heartbeat ping
      ws.on('pong', () => {
        ws.isAlive = true;
      });

      // Handle close
      ws.on('close', () => {
        if (ws.deviceId) {
          logger.info(`WebSocket closed for device: ${ws.deviceId}`);
          deviceRegistry.unregisterDevice(ws.deviceId);
          this.broadcastDeviceUpdate();
        }
      });

      // Handle error
      ws.on('error', (err) => {
        logger.error(`WebSocket error for device [${ws.deviceId || 'unregistered'}]: ${err.message}`);
      });
    });

    // Start periodic heartbeat checking (30s)
    this.pingInterval = setInterval(() => {
      this.wss.clients.forEach((ws: WebSocket) => {
        const client = ws as AuthenticatedWebSocket;
        if (client.isAlive === false) {
          if (client.deviceId) {
            logger.warn(`Device ${client.deviceId} failed heartbeat check — terminating connection`);
            deviceRegistry.unregisterDevice(client.deviceId);
            this.broadcastDeviceUpdate();
          }
          return client.terminate();
        }
        client.isAlive = false;
        client.ping();
      });
    }, 30000);
  }

  /**
   * Parse and route incoming signaling messages
   */
  private handleMessage(ws: AuthenticatedWebSocket, rawData: string): void {
    try {
      const msg: SignalingMessage = JSON.parse(rawData);

      switch (msg.type) {
        case 'REGISTER':
          this.handleRegister(ws, msg);
          break;

        case 'UNREGISTER':
        case 'LEAVE':
          this.handleUnregister(ws);
          break;

        case 'GET_DEVICES':
          this.handleGetDevices(ws);
          break;

        case 'KEEP_ALIVE':
          this.handleKeepAlive(ws);
          break;

        case 'SEND_OFFER':
        case 'SEND_ANSWER':
        case 'SEND_ICE_CANDIDATE':
        case 'TRANSFER_COMPLETE':
          this.relayMessage(ws, msg);
          break;

        default:
          logger.warn(`Unknown message type received: ${msg.type}`);
          this.sendError(ws, `Unsupported message type: ${msg.type}`);
      }
    } catch (err: any) {
      logger.error(`Failed to parse WebSocket message: ${err.message}`);
      this.sendError(ws, 'Invalid JSON message payload');
    }
  }

  /**
   * Handle REGISTER message from device
   */
  private handleRegister(ws: AuthenticatedWebSocket, msg: SignalingMessage): void {
    const payload: any = msg.payload;

    if (!payload.id || !payload.name) {
      return this.sendError(ws, 'Missing required device registration fields (id, name)');
    }

    // Auto-create session & token for device if token absent
    const { session, token } = sessionManager.createSession(payload.id);

    const device: Device = {
      id: payload.id,
      name: payload.name,
      type: payload.type || 'windows',
      platform: payload.platform || 'Windows',
      ipAddress: ws.remoteIp || payload.ipAddress || '127.0.0.1',
      localIp: payload.localIp || '',
      port: payload.port || 8443,
      publicKey: payload.publicKey || '',
      lastSeen: new Date(),
      isOnline: true,
      capabilities: payload.capabilities || {
        supportsFolder: true,
        supportsBatch: true,
        maxFileSize: 10 * 1024 * 1024 * 1024,
      },
    };

    deviceRegistry.registerDevice(device, ws);
    ws.sessionId = session.sessionId;

    // Send confirmation back to registered device
    this.send(ws, {
      type: 'REGISTER',
      payload: {
        registered: true,
        deviceId: device.id,
        sessionId: session.sessionId,
        token: token,
      },
      timestamp: new Date().toISOString(),
    });

    // Broadcast updated device list to all connected nodes
    this.broadcastDeviceUpdate();
  }

  /**
   * Handle explicit device disconnect / leave
   */
  private handleUnregister(ws: AuthenticatedWebSocket): void {
    if (ws.deviceId) {
      deviceRegistry.unregisterDevice(ws.deviceId);
      this.broadcastDeviceUpdate();
    }
  }

  /**
   * Send device list to requesting client
   */
  private handleGetDevices(ws: AuthenticatedWebSocket): void {
    this.send(ws, {
      type: 'DEVICE_UPDATE',
      payload: {
        devices: deviceRegistry.getAllDevices(),
      },
      timestamp: new Date().toISOString(),
    });
  }

  /**
   * Process keep-alive ping
   */
  private handleKeepAlive(ws: AuthenticatedWebSocket): void {
    ws.isAlive = true;
    if (ws.deviceId) {
      deviceRegistry.touchDevice(ws.deviceId);
    }
  }

  /**
   * Relay P2P signaling messages (SEND_OFFER, SEND_ANSWER, SEND_ICE_CANDIDATE) to target device
   */
  private relayMessage(ws: AuthenticatedWebSocket, msg: SignalingMessage): void {
    const toDeviceId = msg.toDeviceId;
    if (!toDeviceId) {
      return this.sendError(ws, `Missing 'toDeviceId' field for relay message type: ${msg.type}`);
    }

    const targetSocket = deviceRegistry.getSocket(toDeviceId);
    if (!targetSocket || targetSocket.readyState !== WebSocket.OPEN) {
      logger.warn(`Relay failed: target device ${toDeviceId} is not connected`);
      return this.sendError(ws, `Target device ${toDeviceId} is offline or unreachable`);
    }

    // Attach sender ID to payload if missing
    const outgoingMsg: SignalingMessage = {
      type: msg.type,
      fromDeviceId: ws.deviceId,
      toDeviceId: toDeviceId,
      payload: msg.payload,
      timestamp: new Date().toISOString(),
    };

    this.send(targetSocket, outgoingMsg);
    logger.info(`Relayed ${msg.type} from ${ws.deviceId} -> ${toDeviceId}`);
  }

  /**
   * Broadcast DEVICE_UPDATE to all active connected sockets
   */
  public broadcastDeviceUpdate(): void {
    const onlineDevices = deviceRegistry.getAllDevices();
    const message: SignalingMessage = {
      type: 'DEVICE_UPDATE',
      payload: {
        devices: onlineDevices,
      },
      timestamp: new Date().toISOString(),
    };

    const payloadStr = JSON.stringify(message);

    for (const socket of deviceRegistry.getAllSockets()) {
      if (socket.readyState === WebSocket.OPEN) {
        socket.send(payloadStr);
      }
    }
    logger.info(`Broadcasted DEVICE_UPDATE (${onlineDevices.length} devices) to network`);
  }

  private send(ws: WebSocket, msg: SignalingMessage): void {
    if (ws.readyState === WebSocket.OPEN) {
      ws.send(JSON.stringify(msg));
    }
  }

  private sendError(ws: WebSocket, message: string): void {
    this.send(ws, {
      type: 'ERROR',
      payload: { message },
      timestamp: new Date().toISOString(),
    });
  }

  public close(): void {
    if (this.pingInterval) clearInterval(this.pingInterval);
    this.wss.close();
  }
}
