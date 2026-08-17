const { Pool } = require('pg');
require('dotenv').config();

// PostgreSQL (Supabase) Connection Pool setup
const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: process.env.DATABASE_URL?.includes('localhost') 
        ? false 
        : { rejectUnauthorized: false }
});

// Query execution helper (compatibility for async/await)
const db = {
    query: (text, params) => pool.query(text, params),
    execute: (text, params) => pool.query(text, params)
};

pool.on('connect', () => {
    console.log("PostgreSQL (Supabase) Database connected successfully.");
});

pool.on('error', (err) => {
    console.error("Unexpected error on idle PostgreSQL client", err);
});

module.exports = db;