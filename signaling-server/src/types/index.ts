import { WebSocket } from 'ws';

export interface DeviceCapabilities {
  supportsFolder: boolean;
  supportsBatch: boolean;
  maxFileSize: number;
}

export interface Device {
  id: string; // UUID
  name: string;
  type: 'android' | 'windows' | 'linux';
  platform: string;
  ipAddress: string;
  localIp: string;
  port: number;
  publicKey: string;
  lastSeen: Date;
  isOnline: boolean;
  capabilities: DeviceCapabilities;
}

export interface Transfer {
  id: string;
  deviceId: string;
  fileName: string;
  filePath: string;
  fileSize: number;
  fileHash: string; // SHA-256
  status: 'pending' | 'inProgress' | 'paused' | 'completed' | 'failed' | 'cancelled';
  direction: 'send' | 'receive';
  progress: number; // 0-100
  transferSpeed: number; // bytes/sec
  chunkSize: number;
  retryCount: number;
}

export interface Session {
  sessionId: string;
  deviceId: string;
  token: string; // JWT
  connectedAt: Date;
  isActive: boolean;
}

export type SignalingMessageType =
  | 'REGISTER'
  | 'UNREGISTER'
  | 'GET_DEVICES'
  | 'SEND_OFFER'
  | 'SEND_ANSWER'
  | 'SEND_ICE_CANDIDATE'
  | 'LEAVE'
  | 'KEEP_ALIVE'
  | 'ERROR'
  | 'DEVICE_UPDATE'
  | 'TRANSFER_COMPLETE';

export interface SignalingMessage {
  type: SignalingMessageType;
  fromDeviceId?: string;
  toDeviceId?: string;
  payload: Record<string, any>;
  timestamp: string;
}

export interface AuthenticatedWebSocket extends WebSocket {
  deviceId?: string;
  sessionId?: string;
  isAlive?: boolean;
  remoteIp?: string;
}

export interface JwtPayload {
  deviceId: string;
  sessionId: string;
  type: string;
  iat?: number;
  exp?: number;
}
