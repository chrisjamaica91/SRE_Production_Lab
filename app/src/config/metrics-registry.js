const client = require("prom-client");

// Create and export a single registry
const register = new client.Registry();

// Collect default metrics
client.collectDefaultMetrics({ register });

// Export both the client and registry
module.exports = { client, register };