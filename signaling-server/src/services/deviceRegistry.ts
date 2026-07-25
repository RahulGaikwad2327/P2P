import { Device, AuthenticatedWebSocket } from '../types/index.js';
import { logger } from '../utils/logger.js';

class DeviceRegistry {
  private devices: Map<string, Device> = new Map(); // deviceId -> Device
  private sockets: Map<string, AuthenticatedWebSocket> = new Map(); // deviceId -> WebSocket

  /**
   * Register or update a device in the registry
   */
  public registerDevice(device: Device, socket: AuthenticatedWebSocket): void {
    const existing = this.devices.get(device.id);

    const updatedDevice: Device = {
      ...device,
      isOnline: true,
      lastSeen: new Date(),
    };

    this.devices.set(device.id, updatedDevice);
    this.sockets.set(device.id, socket);

    socket.deviceId = device.id;
    socket.isAlive = true;

    logger.info(`Device registered: ${device.name} [ID: ${device.id}] (${device.type}/${device.platform})`);
  }

  /**
   * Mark a device as offline when socket disconnects
   */
  public unregisterDevice(deviceId: string): void {
    const device = this.devices.get(deviceId);
    if (device) {
      device.isOnline = false;
      device.lastSeen = new Date();
      logger.info(`Device unregistered: ${device.name} [ID: ${deviceId}]`);
    }
    this.sockets.delete(deviceId);
  }

  /**
   * Get device by ID
   */
  public getDevice(deviceId: string): Device | undefined {
    return this.devices.get(deviceId);
  }

  /**
   * Get all registered devices
   */
  public getAllDevices(): Device[] {
    return Array.from(this.devices.values());
  }

  /**
   * Get all currently online devices
   */
  public getOnlineDevices(): Device[] {
    return Array.from(this.devices.values()).filter((d) => d.isOnline);
  }

  /**
   * Get WebSocket for a specific device
   */
  public getSocket(deviceId: string): AuthenticatedWebSocket | undefined {
    return this.sockets.get(deviceId);
  }

  /**
   * Get all active WebSockets
   */
  public getAllSockets(): AuthenticatedWebSocket[] {
    return Array.from(this.sockets.values());
  }

  /**
   * Update heartbeat timestamp for a device
   */
  public touchDevice(deviceId: string): void {
    const device = this.devices.get(deviceId);
    if (device) {
      device.lastSeen = new Date();
      device.isOnline = true;
    }
  }
}

export const deviceRegistry = new DeviceRegistry();
