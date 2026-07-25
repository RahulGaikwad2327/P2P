import { Router, Request, Response } from 'express';
import { deviceRegistry } from '../services/deviceRegistry.js';

const router = Router();

/**
 * GET /api/devices
 * List all registered devices
 */
router.get('/', (_req: Request, res: Response): void => {
  const devices = deviceRegistry.getAllDevices();
  res.status(200).json({
    count: devices.length,
    onlineCount: devices.filter((d) => d.isOnline).length,
    devices,
  });
});

/**
 * GET /api/devices/:id
 * Get single device by ID
 */
router.get('/:id', (req: Request, res: Response): void => {
  const device = deviceRegistry.getDevice(req.params.id);
  if (!device) {
    res.status(404).json({ error: 'Device not found' });
    return;
  }
  res.status(200).json(device);
});

export default router;
