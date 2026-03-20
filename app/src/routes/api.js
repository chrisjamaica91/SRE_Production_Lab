const express = require("express");
const router = express.Router();
const pool = require("../config/database");
const logger = require("../utils/logger");

/**
 * Main API routes
 */

// Hello World endpoint
router.get("/", (req, res) => {
  res.json({
    message: "Hello World! Welcome to the SRE Lab API Enterprise Grade Application",
    version: "1.0.0",
    endpoints: {
      health: "/health",
      readiness: "/ready",
      metrics: "/metrics",
      api: "/api",
      users: "/api/users",
    },
  });
});

// Get all users from database
router.get("/users", async (req, res, next) => {
  try {
    const result = await pool.query(
      "SELECT id, name, email, created_at FROM users ORDER BY id",
    );
    res.json({
      count: result.rows.length,
      users: result.rows,
    });
  } catch (error) {
    logger.error("Failed to fetch users", { error: error.message });
    next(error);
  }
});

// Get specific user
router.get("/users/:id", async (req, res, next) => {
  try {
    const { id } = req.params;
    const result = await pool.query(
      "SELECT id, name, email, created_at FROM users WHERE id = $1",
      [id],
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: "User not found" });
    }

    res.json(result.rows[0]);
  } catch (error) {
    logger.error("Failed to fetch user", {
      error: error.message,
      userId: req.params.id,
    });
    next(error);
  }
});

// Simulate error (for testing error handling)
router.get("/simulate-error", (req, res, next) => {
  logger.warn("Simulated error endpoint called");
  const error = new Error("This is a simulated error for testing");
  error.statusCode = 500;
  next(error);
});

// Simulate latency (for testing performance)
router.get("/simulate-latency", (req, res) => {
  const ms = parseInt(req.query.ms) || 1000;
  logger.info("Simulated latency endpoint called", { latencyMs: ms });

  setTimeout(() => {
    res.json({
      message: `Response delayed by ${ms}ms`,
      timestamp: new Date().toISOString(),
    });
  }, ms);
});

module.exports = router;
