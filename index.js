// 0. Dotenv config
require('dotenv').config();

// 1. Imports
const express = require('express');
const path = require('path');
const cors = require('cors');

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