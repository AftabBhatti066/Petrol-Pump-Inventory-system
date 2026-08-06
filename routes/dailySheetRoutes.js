const express = require('express');
const router = express.Router();
const dailySheetController = require('../controllers/dailySheetController');

// Master Customers Fetch Route (For auto-fill)
router.get('/customers', dailySheetController.getMasterCustomers);

// Customer registration
router.post('/customer', dailySheetController.addCustomer);

// Entry save/update karne ka route
router.post('/save', dailySheetController.saveDailySheetEntry);

// Date ke mutabik daily sheet fetch karne ka route
router.get('/view/:date', dailySheetController.getDailySheetByDate);

// Entry delete karne ka route
router.delete('/delete-entry/:id', dailySheetController.deleteSheetEntry);

// Customer ko Search ID ke zariye permanently delete karne ka route
router.delete('/delete-customer/:search_id', dailySheetController.deleteCustomerPermanently);

router.get('/expenses-report', dailySheetController.getExpensesReport);

module.exports = router;