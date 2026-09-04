const express = require('express');
const router = express.Router();
const meterController = require('../controllers/meterController');

// Helper fallback to prevent app crashing if controller function is missing
const handleRoute = (controllerFn) => {
    return typeof controllerFn === 'function' 
        ? controllerFn 
        : (req, res) => res.status(500).json({ status: "Error", message: "Controller handler missing" });
};

// ⛽ Get Fuel Rates Route (/api/meter/rates)
router.get('/rates', async (req, res, next) => {
    if (typeof meterController.getRates === 'function') {
        return meterController.getRates(req, res, next);
    }
    
    // Default Fallback
    try {
        const db = require('../config/db');
        const userId = req.query.userId;
        if (!userId) {
            return res.json({ status: "Success", data: [] });
        }

        try {
            const result = await db.query(
                'SELECT product_type, purchase_price FROM fuel_rates WHERE user_id = $1', 
                [userId]
            );
            return res.json({ status: "Success", data: result.rows || result });
        } catch (dbErr) {
            try {
                const result = await db.query(
                    'SELECT product_type, purchase_price FROM pricing WHERE user_id = $1', 
                    [userId]
                );
                return res.json({ status: "Success", data: result.rows || result });
            } catch (err2) {
                return res.json({ status: "Success", data: [] });
            }
        }
    } catch (err) {
        console.error("Rates fetch error:", err);
        return res.json({ status: "Success", data: [] });
    }
});

// 🗓️ Latest Date Route
router.get('/latest-date', async (req, res, next) => {
    if (typeof meterController.getLatestDate === 'function') {
        return meterController.getLatestDate(req, res, next);
    }

    try {
        const db = require('../config/db');
        const userId = req.query.userId || '1';
        const result = await db.query(
            `SELECT MAX(reading_date) AS latest_date FROM meter_readings WHERE user_id = $1`, 
            [userId]
        );
        const latestDate = result.rows && result.rows[0] ? result.rows[0].latest_date : null;
        return res.json({ status: "Success", latest_date: latestDate });
    } catch (err) {
        console.error("Latest date route error:", err);
        return res.json({ status: "Success", latest_date: null });
    }
});

// 📝 Meter Readings Routes
router.post('/add', handleRoute(meterController.addReading));
router.post('/add-reading', handleRoute(meterController.addReading));
router.get('/all', handleRoute(meterController.getAllReadings));

// ⛽ Tank & Lubricants Routes
router.get('/tank-stock', handleRoute(meterController.getTankStock));
router.post('/update-receipt', handleRoute(meterController.updateReceipt));
router.get('/lubricant-stock', handleRoute(meterController.getLubricantStock));
router.post('/update-lubricants', handleRoute(meterController.updateLubricants));

module.exports = router;