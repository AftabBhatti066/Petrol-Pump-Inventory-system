const express = require('express');
const router = express.Router();
const reportController = require('../controllers/reportController');

// Clean route definitions - Ensure functions are properly referenced
router.get('/customer-ledger', reportController.getCustomerLedgerReport);
router.get('/trial-balance', reportController.getTrialBalance);
router.get('/dispenser-profit', reportController.getDispenserProfitReport);
router.get('/daily-summary', reportController.getDailySummary);

module.exports = router;