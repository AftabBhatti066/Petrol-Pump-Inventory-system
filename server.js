const express = require('express');
const path = require('path');
const cors = require('cors');

const app = express();

// Middlewares
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Terminal Logging Middleware
app.use((req, res, next) => {
    console.log(`[${new Date().toLocaleTimeString()}] ${req.method} ${req.url}`);
    next();
});

// Static files (public folder)
app.use(express.static(path.join(__dirname, 'public')));

// HTML Base Routes
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'login.html'));
});

app.get('/login', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'login.html'));
});

app.get('/dashboard', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'dashboard.html'));
});

// ==========================================
// ALL API ROUTES REGISTERED HERE
// ==========================================
const authRoutes = require('./routes/authRoutes');
app.use('/api', authRoutes);

const fuelRoutes = require('./routes/fuelRoutes');
app.use('/api/fuel', fuelRoutes);

const meterRoutes = require('./routes/meterRoutes');
app.use('/api/meter', meterRoutes);

const ledgerRoutes = require('./routes/ledgerRoutes');
app.use('/api/ledger', ledgerRoutes);

const dailySheetRoutes = require('./routes/dailySheetRoutes');
app.use('/api/daily-sheet', dailySheetRoutes);

// DASHBOARD ROUTE (Crucial Fix)
const dashboardRoutes = require('./routes/dashboardRoutes');
app.use('/api/dashboard', dashboardRoutes);

const reportRoutes = require('./routes/reportRoutes'); 
app.use('/api/report', reportRoutes);

const expenseRoutes = require('./routes/expenseRoutes');
app.use('/api/expense', expenseRoutes);

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
    console.log(`🚀 Unified Server running on port ${PORT}`);
});