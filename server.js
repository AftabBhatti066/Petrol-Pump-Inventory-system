// 0. Dotenv config
require('dotenv').config();

// 1. Imports
const express = require('express');
const path = require('path');
const cors = require('cors');
const cron = require('node-cron');

// 2. Database Config Import
const db = require('./config/db');

// 3. Express App Initialize
const app = express();

// 4. Port Number Define
const PORT = process.env.PORT || 5000;

// 5. Middlewares
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// 6. Static Files Serve (public folder)
app.use(express.static(path.join(__dirname, 'public')));

// Favicon 404 Ignore
app.get('/favicon.ico', (req, res) => res.status(204).end());

// ==========================================
// AUTOMATIC MONTH-END PROFIT CRON JOB
// Runs automatically on 1st of every month at 12:00 AM
// ==========================================
cron.schedule('0 0 1 * *', async () => {
    console.log('--- Running Automatic Month-End Profit Posting (Fuel + Lubricants) ---');
    try {
        const now = new Date();
        const firstDayPrevMonth = new Date(now.getFullYear(), now.getMonth() - 1, 1);
        const lastDayPrevMonth = new Date(now.getFullYear(), now.getMonth(), 0);

        const startDate = firstDayPrevMonth.toISOString().split('T')[0];
        const endDate = lastDayPrevMonth.toISOString().split('T')[0];

        // Fetch unique users
        const { rows: users } = await db.query(`SELECT DISTINCT user_id FROM meter_readings WHERE user_id IS NOT NULL`);
        const userList = users.length > 0 ? users.map(u => u.user_id) : [1];

        for (const uId of userList) {
            let profitQuery = `
                SELECT 
                    combined.fuel_type,
                    SUM(
                        (combined.liters_sold * COALESCE(fr.rate_per_litre, 0)) - 
                        (combined.liters_sold * COALESCE(fr.purchase_price, 0))
                    ) AS item_profit
                FROM (
                    -- Fuel Sales
                    SELECT 
                        TRIM(mr.fuel_type) AS fuel_type,
                        COALESCE(mr.liters_sold, 0) AS liters_sold,
                        mr.user_id,
                        mr.reading_date::date AS transaction_date
                    FROM meter_readings mr
                    WHERE COALESCE(mr.liters_sold, 0) > 0

                    UNION ALL

                    -- Lubricants Sales / Stock
                    SELECT 
                        TRIM(ls.item_name) AS fuel_type,
                        COALESCE(ls.current_stock, 0) AS liters_sold,
                        ls.user_id,
                        CURRENT_DATE AS transaction_date
                    FROM lubricant_stocks ls
                    WHERE COALESCE(ls.current_stock, 0) > 0
                ) combined
                LEFT JOIN (
                    SELECT product_name, product_type, rate_per_litre, purchase_price
                    FROM fuel_rates
                    WHERE id IN (SELECT MAX(id) FROM fuel_rates GROUP BY product_name, product_type)
                ) fr ON LOWER(TRIM(combined.fuel_type)) = LOWER(TRIM(fr.product_name))
                     OR LOWER(TRIM(combined.fuel_type)) = LOWER(TRIM(fr.product_type))
                     OR LOWER(TRIM(combined.fuel_type)) LIKE '%' || LOWER(TRIM(fr.product_type)) || '%'
                     OR LOWER(TRIM(fr.product_name)) LIKE '%' || LOWER(TRIM(combined.fuel_type)) || '%'
                WHERE combined.transaction_date BETWEEN $1 AND $2
                  AND (combined.user_id = $3 OR combined.user_id IS NULL)
                GROUP BY combined.fuel_type
            `;

            const { rows: profits } = await db.query(profitQuery, [startDate, endDate, uId]);

            for (const row of profits) {
                const rawItemName = (row.fuel_type || '').toLowerCase();
                const profitAmount = parseFloat(row.item_profit) || 0;

                if (profitAmount <= 0) continue;

                let searchId = 'mb'; // Default for Mobiloil / Lubricants
                if (rawItemName.includes('diesel') || rawItemName.includes('hsd') || rawItemName.includes('dl')) {
                    searchId = 'dl';
                } else if (rawItemName.includes('super') || rawItemName.includes('petrol') || rawItemName.includes('sp') || rawItemName.includes('pm')) {
                    searchId = 'sp';
                }

                const description = `Auto Month-End Profit Return (${startDate} to ${endDate}) - ${row.fuel_type}`;

                await db.query(
                    `INSERT INTO daily_sheets (search_id, debit_udhaar, credit_vasooli, description, sheet_date, user_id, total_balance) 
                     VALUES ($1, $2, 0.00, $3, $4, $5, $6)`,
                    [searchId, profitAmount, description, endDate, uId, -profitAmount]
                );
            }
        }
        console.log(`[CRON SUCCESS] Month-End Profit posted automatically for period: ${startDate} to ${endDate}`);
    } catch (error) {
        console.error('[CRON ERROR] Automatic Profit Posting failed:', error);
    }
});

// ==========================================
// API ROUTES SETUP
// ==========================================
const authRoutes = require('./routes/authRoutes');
app.use('/api', authRoutes);

const fuelRoutes = require('./routes/fuelRoutes');
app.use('/api/fuel', fuelRoutes);

// ------------------------------------------
// ⛽ FUEL RATES API ROUTE (SUPABASE / POSTGRESQL FIXED)
// ------------------------------------------
app.get('/api/rates', async (req, res) => {
    try {
        const userId = req.query.userId;
        if (!userId) {
            return res.json({ status: "Success", data: [] });
        }

        // Supabase / PostgreSQL Direct Safe Query
        try {
            // Check in fuel_rates table
            const result = await db.query(
                'SELECT product_type, purchase_price FROM fuel_rates WHERE user_id = $1', 
                [userId]
            );
            return res.json({ status: "Success", data: result.rows || result });
        } catch (dbErr) {
            console.warn("fuel_rates table check failed, checking pricing table...");
            
            try {
                // Fallback to pricing table if fuel_rates doesn't exist
                const result = await db.query(
                    'SELECT product_type, purchase_price FROM pricing WHERE user_id = $1', 
                    [userId]
                );
                return res.json({ status: "Success", data: result.rows || result });
            } catch (err2) {
                console.warn("Pricing table query failed as well:", err2.message);
                return res.json({ status: "Success", data: [] });
            }
        }
    } catch (err) {
        console.error("Rates fetch error:", err);
        return res.json({ status: "Success", data: [] });
    }
});

const meterRoutes = require('./routes/meterRoutes');
app.use('/api/meter', meterRoutes);

const ledgerRoutes = require('./routes/ledgerRoutes');
app.use('/api/ledger', ledgerRoutes);

const dailySheetRoutes = require('./routes/dailySheetRoutes');
app.use('/api/daily-sheet', dailySheetRoutes);

const dashboardRoutes = require('./routes/dashboardRoutes');
app.use('/api/dashboard', dashboardRoutes);

const reportRoutes = require('./routes/reportRoutes'); 
app.use('/api/report', reportRoutes);

const expenseRoutes = require('./routes/expenseRoutes');
app.use('/api/expense', expenseRoutes);

// ==========================================
// HTML PAGE ROUTES (Views)
// ==========================================

app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'login.html'));
});

app.get('/login', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'login.html'));
});

app.get('/login.html', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'login.html'));
});

app.get('/register', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'register.html'));
});

app.get('/dashboard', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'dashboard.html'));
});

app.get('/ledgers', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'ledgers.html'));
});

app.get('/report', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'report.html'));
});

// ==========================================
// SERVER START
// ==========================================
app.listen(PORT, () => {
    console.log(`=================================`);
    console.log(`🚀 Server is running on port: ${PORT}`);
    console.log(`=================================`);
});