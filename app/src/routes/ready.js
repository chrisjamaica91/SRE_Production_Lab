const express = require("express");
const router = express.Router();
const pool = require("../config/database");
const logger = require("../utils/logger");

/**
 * Readiness probe endpoint
 * Kubernetes uses this to know if the pod is ready to receive traffic
 * Checks database connectivity
 */
router.get("/ready", async (req, res) => {
  const checks = {};
  let isReady = true;

  // Check database connection
  try {
    const result = await pool.query("SELECT 1 as health");
    checks.database = "ok";
  } catch (error) {
    logger.error("Database health check failed", { error: error.message });
    checks.database = "failed";
    isReady = false;
  }

  const statusCode = isReady ? 200 : 503;

  res.status(statusCode).json({
    status: isReady ? "ready" : "not ready",
    checks,
    timestamp: new Date().toISOString(),
  });
});

module.exports = router;
