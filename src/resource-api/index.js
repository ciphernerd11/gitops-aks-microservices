/**
 * Resource API — Express service for managing inventories of relief supplies.
 * Connects to PostgreSQL for persistent storage.
 */

const express = require("express");
const cors = require("cors");
const helmet = require("helmet");
const { Pool } = require("pg");

// ── Configuration ──
const PORT = parseInt(process.env.PORT || "3000", 10);
const DATABASE_URL =
    process.env.DATABASE_URL ||
    `postgresql://${process.env.PGUSER || "postgres"}:${process.env.PGPASSWORD || "postgres"}@${process.env.PGHOST || "postgres-service"}:${process.env.PGPORT || "5432"}/${process.env.PGDATABASE || "resources"}`;

const pool = new Pool({ connectionString: DATABASE_URL });

const app = express();

// ── Middleware ──
app.use(helmet());
app.use(cors());
app.use(express.json());

// ── Bootstrap table ──
async function initDB() {
    const client = await pool.connect();
    try {
        await client.query(`
      CREATE TABLE IF NOT EXISTS resources (
        id          SERIAL PRIMARY KEY,
        name        VARCHAR(256) NOT NULL,
        quantity    INTEGER NOT NULL DEFAULT 0,
        location    VARCHAR(256) NOT NULL DEFAULT '',
        status      VARCHAR(32)  NOT NULL DEFAULT 'available',
        created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
        updated_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
      );
    `);
        console.log("[resource-api] Database initialised.");
    } finally {
        client.release();
    }
}

// ── Routes ──
app.get("/health", (_req, res) => {
    res.json({ status: "ok", service: "resource-api" });
});

// List all resources
app.get("/resources", async (_req, res, next) => {
    try {
        const { rows } = await pool.query(
            "SELECT * FROM resources ORDER BY updated_at DESC"
        );
        res.json(rows);
    } catch (err) {
        next(err);
    }
});

// Create a resource
app.post("/resources", async (req, res, next) => {
    try {
        const { name, quantity, location, status } = req.body;

        if (!name) {
            return res.status(400).json({ error: "name is required" });
        }

        const { rows } = await pool.query(
            `INSERT INTO resources (name, quantity, location, status)
       VALUES ($1, $2, $3, $4)
       RETURNING *`,
            [name, quantity || 0, location || "", status || "available"]
        );
        res.status(201).json(rows[0]);
    } catch (err) {
        next(err);
    }
});

// Update a resource
app.put("/resources/:id", async (req, res, next) => {
    try {
        const { id } = req.params;
        const { name, quantity, location, status } = req.body;

        const { rows } = await pool.query(
            `UPDATE resources
       SET name       = COALESCE($1, name),
           quantity   = COALESCE($2, quantity),
           location   = COALESCE($3, location),
           status     = COALESCE($4, status),
           updated_at = NOW()
       WHERE id = $5
       RETURNING *`,
            [name, quantity, location, status, id]
        );

        if (rows.length === 0) {
            return res.status(404).json({ error: "Resource not found" });
        }
        res.json(rows[0]);
    } catch (err) {
        next(err);
    }
});

// ── Error handler ──
app.use((err, _req, res, _next) => {
    console.error("[resource-api] Error:", err.message);
    res.status(500).json({ error: "Internal server error" });
});

// ── Start ──
initDB()
    .then(() => {
        app.listen(PORT, () =>
            console.log(`[resource-api] Listening on :${PORT}`)
        );
    })
    .catch((err) => {
        console.error("[resource-api] Failed to initialise DB:", err);
        process.exit(1);
    });
