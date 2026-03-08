const logger = require("../utils/logger");

/**
 * Centralized error handling middleware
 * Catches all errors and returns safe responses
 */
function errorHandler(err, req, res, next) {
  // Log the error with full details
  logger.error("Error occurred", {
    error: err.message,
    stack: err.stack,
    path: req.path,
    method: req.method,
    ip: req.ip,
  });

  // Determine status code
  const statusCode = err.statusCode || 500;

  // Send safe error response (never expose internal details)
  res.status(statusCode).json({
    status: "error",
    message: statusCode === 500 ? "Internal server error" : err.message,
    timestamp: new Date().toISOString(),
  });
}

module.exports = errorHandler;
