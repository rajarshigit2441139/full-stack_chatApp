import client from 'prom-client';

const register = new client.Registry();

client.collectDefaultMetrics({ register });

// HTTP request duration
export const httpRequestDuration = new client.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.01, 0.05, 0.1, 0.3, 0.5, 1, 2, 5],
  registers: [register],
});

// Active WebSocket connections
export const activeConnections = new client.Gauge({
  name: 'websocket_active_connections',
  help: 'Number of active WebSocket connections',
  registers: [register],
});

// Messages sent
export const messagesSent = new client.Counter({
  name: 'chat_messages_sent_total',
  help: 'Total number of chat messages sent',
  registers: [register],
});

// Auth events
export const authEvents = new client.Counter({
  name: 'auth_events_total',
  help: 'Total auth events by type',
  labelNames: ['event'],
  registers: [register],
});

export { register };