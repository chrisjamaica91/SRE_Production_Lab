require("dotenv").config();
const express = require("express");
const helmet = require("helmet");
const cors = require("cors");
const logger = require("./utils/logger");
const requestLogger = require("./middleware/requestLogger");
const metricsMiddleware = require("./middleware/metrics");
const errorHandler = require("./middleware/errorHandler");

// Import routes
const healthRoute = require("./routes/health");
const readyRoute = require("./routes/ready");
const apiRoute = require("./routes/api");
const { router: metricsRoute } = require("./routes/metrics");

// Initialize Express app
const app = express();
const PORT = process.env.PORT || 3000;

// Security middleware
app.use(helmet());

// CORS configuration
app.use(cors());

// Body parsing middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Request logging middleware
app.use(requestLogger);

// Metrics middleware (track all requests)
app.use(metricsMiddleware);

// Mount routes
app.use(healthRoute);
app.use(readyRoute);
app.use("/api", apiRoute);
app.use(metricsRoute);

// Root endpoint
app.get("/", (req, res) => {
  res.json({
    message: "SRE Lab API - Enterprise Grade Application",
    version: "1.0.0",
    status: "running",
    endpoints: {
      health: "/health",
      readiness: "/ready",
      metrics: "/metrics",
      api: "/api",
      users: "/api/users",
      "simulate-error": "/api/simulate-error",
      "simulate-latency": "/api/simulate-latency?ms=1000",
    },
    documentation: "https://github.com/yourname/sre-lab",
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    status: "error",
    message: "Endpoint not found",
    path: req.path,
  });
});

// Error handling middleware (must be last!)
app.use(errorHandler);

// Start server
let server;

async function startServer() {
  try {
    server = app.listen(PORT, "0.0.0.0", () => {
      logger.info("Server started successfully", {
        port: PORT,
        nodeEnv: process.env.NODE_ENV || "development",
        pid: process.pid,
      });

      logger.info("Available endpoints", {
        health: `http://localhost:${PORT}/health`,
        ready: `http://localhost:${PORT}/ready`,
        metrics: `http://localhost:${PORT}/metrics`,
        api: `http://localhost:${PORT}/api`,
      });
    });
  } catch (error) {
    logger.error("Failed to start server", { error: error.message });
    process.exit(1);
  }
}

// Graceful shutdown handler
function gracefulShutdown(signal) {
  logger.info(`Received ${signal}. Starting graceful shutdown...`);

  if (server) {
    server.close(() => {
      logger.info("HTTP server closed");

      // Close database connections
      const pool = require("./config/database");
      pool.end(() => {
        logger.info("Database connections closed");
        logger.info("Graceful shutdown complete");
        process.exit(0);
      });
    });

    // Force shutdown after 30 seconds
    setTimeout(() => {
      logger.error("Forced shutdown after timeout");
      process.exit(1);
    }, 30000);
  } else {
    process.exit(0);
  }
}

// Handle shutdown signals (from Kubernetes)
process.on("SIGTERM", () => gracefulShutdown("SIGTERM"));
process.on("SIGINT", () => gracefulShutdown("SIGINT"));

// Handle uncaught errors
process.on("uncaughtException", (error) => {
  logger.error("Uncaught exception", {
    error: error.message,
    stack: error.stack,
  });
  gracefulShutdown("uncaughtException");
});

process.on("unhandledRejection", (reason, promise) => {
  logger.error("Unhandled rejection", { reason, promise });
  gracefulShutdown("unhandledRejection");
});

// Start the server
startServer();

module.exports = app;
