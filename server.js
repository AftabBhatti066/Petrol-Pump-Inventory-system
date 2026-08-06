const express = require('express');
const path = require('path');
const cors = require('cors');

// 1. All Route Imports
const authRoutes = require('./routes/authRoutes');
const reportRoutes = require('./routes/reportRoutes'); 

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

// 2. Register ALL API Routes Here
app.use('/api', authRoutes);               // Login, Auth & Main APIs
app.use('/api/reports', reportRoutes);     // Reports APIs

// Note: Agar index.js mein koi aur extra routes register hue thay,
// toh unko bhi yahan app.use('/api/...', extraRoutes) karke add kar dein.

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
    console.log(`🚀 Unified Server running on port ${PORT}`);
});