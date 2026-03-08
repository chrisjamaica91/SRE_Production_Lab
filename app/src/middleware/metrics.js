const { client, register } = require("../config/metrics-registry");

// Create metrics with explicit registry
const httpRequestCounter = new client.Counter({
  name: "http_requests_total",
  help: "Total number of HTTP requests",
  labelNames: ["method", "route", "status"],
  registers: [register],
});

const httpRequestDuration = new client.Histogram({
  name: "http_request_duration_seconds",
  help: "Duration of HTTP requests in seconds",
  labelNames: ["method", "route", "status"],
  buckets: [0.1, 0.5, 1, 2, 5],
  registers: [register],
});

const activeRequests = new client.Gauge({
  name: "active_requests",
  help: "Current number of active HTTP requests",
  registers: [register],
});

// Middleware function to track metrics
const metricsMiddleware = (req, res, next) => {
  const start = Date.now();

  // Increment active requests
  activeRequests.inc();

  // Track response
  res.on("finish", () => {
    const duration = (Date.now() - start) / 1000;
    const route = req.route ? req.route.path : req.path;

    // Record metrics
    httpRequestCounter.inc({
      method: req.method,
      route: route,
      status: res.statusCode,
    });

    httpRequestDuration.observe(
      {
        method: req.method,
        route: route,
        status: res.statusCode,
      },
      duration,
    );

    // Decrement active requests
    activeRequests.dec();
  });

  next();
};

module.exports = metricsMiddleware;
