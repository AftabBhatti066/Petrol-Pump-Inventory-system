const express = require('express');
const router = express.Router();
const reportController = require('../controllers/reportController');

// Debugging log to see which controller function is undefined
console.log('Loaded reportController handlers:', {
    getCustomerLedgerReport: typeof reportController.getCustomerLedgerReport,
    getTrialBalance: typeof reportController.getTrialBalance,
    getDispenserProfitReport: typeof reportController.getDispenserProfitReport,
    getDailySummary: typeof reportController.getDailySummary,
    postMonthEndProfit: typeof reportController.postMonthEndProfit,
});

router.get('/customer-ledger', reportController.getCustomerLedgerReport);
router.get('/trial-balance', reportController.getTrialBalance);
router.get('/dispenser-profit', reportController.getDispenserProfitReport);
router.get('/daily-summary', reportController.getDailySummary);
router.post('/month-end-profit', reportController.postMonthEndProfit);

module.exports = router;