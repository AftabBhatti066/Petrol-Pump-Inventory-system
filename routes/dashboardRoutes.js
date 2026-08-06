const express = require('express');
const router = express.Router();
const dashboardController = require('../controllers/dashboardController');
const dailySheetController = require('../controllers/dailySheetController');

// Dashboard data route
router.get('/data', dashboardController.getDashboardData);

// Master Customers list for live Search ID auto-fill lookup
router.get('/customers', dailySheetController.getMasterCustomers);

module.exports = router;