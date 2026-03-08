const express = require("express");
const router = express.Router();
const { register } = require("../config/metrics-registry");

/**
 * Prometheus metrics endpoint
 * Returns metrics in Prometheus format
 */

router.get("/metrics", async (req, res) => {
  res.set("Content-Type", register.contentType);
  res.end(await register.metrics());
});

module.exports = { router, register };
