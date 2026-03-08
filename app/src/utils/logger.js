const winston = require('winston');

// JSON format for structured logging
// Log to console (K8s captures stdout)
// Levels: error, warn, info, http, debug
// Include timestamp and metadata
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.Console()
  ]
});

module.exports = logger;
