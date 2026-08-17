const { Pool } = require('pg');
require('dotenv').config();

// Direct Supabase Connection String (Port 5432)
const connectionString = process.env.DATABASE_URL || "postgresql://postgres:aftab4049102@db.nwydokomsuozvvqwekwn.supabase.co:5432/postgres";

const pool = new Pool({
    connectionString: connectionString,
    ssl: {
        rejectUnauthorized: false
    },
    connectionTimeoutMillis: 10000, // 10 seconds
    idleTimeoutMillis: 30000
});

const db = {
    query: (text, params) => pool.query(text, params),
    execute: (text, params) => pool.query(text, params),
    getClient: () => pool.connect(), // Added for transactions
    connect: () => pool.connect(),   // Added direct alias
    pool: pool                       // Direct pool reference
};

pool.on('connect', () => {
    console.log("PostgreSQL (Supabase) Database connected successfully.");
});

pool.on('error', (err) => {
    console.error("Unexpected error on idle PostgreSQL client", err);
});

module.exports = db;