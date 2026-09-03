const express = require('express');
const router = express.Router();
const meterController = require('../controllers/meterController');

// 🗓️ Aakhri Saved Date Fetch Karne Ke Liye Route
router.get('/latest-date', meterController.getLatestDate || (async (req, res) => {
    try {
        const db = require('../config/db');
        const userId = req.query.userId || '1';

        // Database se sab se aakhri (MAX) reading date fetch karein
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
}));

// URLs ko controller k functions k sath jorna
router.post('/add', meterController.addReading);
router.get('/all', meterController.getAllReadings);

router.get('/tank-stock', meterController.getTankStock);
// 🔥 Sahi function name map kar diya: updateReceipt
router.post('/update-receipt', meterController.updateReceipt);

router.get('/lubricant-stock', meterController.getLubricantStock);
// 🔥 Sahi function name map kar diya: updateLubricants
router.post('/update-lubricants', meterController.updateLubricants);

module.exports = router;