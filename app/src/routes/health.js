const express = require("express");
const router = express.Router();

/**
 * Liveness probe endpoint
 * Kubernetes uses this to know if the pod is alive
 * Simple check - just return 200 if process is running
 */
router.get("/health", (req, res) => {
  res.status(200).json({
    status: "ok",
    service: "sre-lab-api",
    version: "2.0.0",
    cicd: "automated",
    gitops: "argocd-enabled",
    timestamp: new Date().toISOString(),
  });
});

module.exports = router;
