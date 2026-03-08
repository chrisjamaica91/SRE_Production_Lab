const { Pool } = require("pg");
const logger = require("../utils/logger");

// Create connection pool (not individual connections!)
// Pool config: max connections, idle timeout, connection timeout
// Export pool for reuse
// Include error handling
// Test connection with a query
const pool = new Pool({
  host: process.env.DB_HOST || "localhost",
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || "srelab",
  user: process.env.DB_USER || "postgres",
  password: process.env.DB_PASSWORD || "postgres",
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

pool.on("error", (err, client) => {
  logger.error("Unexpected error on idle client", { error: err.message });
  process.exit(-1);
});

const testConnection = async () => {
  try {
    const res = await pool.query("SELECT NOW()");
    logger.info("Database connected successfully", {
      timestamp: res.rows[0].now,
    });
  } catch (err) {
    logger.error("Database connection error", { error: err.message });
  }
};

testConnection();

module.exports = pool;
