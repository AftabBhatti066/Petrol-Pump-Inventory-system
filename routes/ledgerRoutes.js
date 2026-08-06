const express = require('express');
const router = express.Router();

// Controller handlers import (getTrialBalance ko add kar diya hai)
const {
    registerVehicle,
    logCreditFuel,
    logVehicleVasooli,
    getVehicleLedger,
    deleteCreditEntry,
    getAccountTypes,
    createAccount,
    getTrialBalance // <-- Yahan add kiya hai
} = require('../controllers/ledgerController');

// Routes Setup
router.post('/register-vehicle', registerVehicle);
router.post('/log-credit-fuel', logCreditFuel);
router.post('/log-vasooli', logVehicleVasooli);

// Fixed Route
router.get('/vehicle-ledger', getVehicleLedger);
router.get('/vehicle-ledger/:gari_number', getVehicleLedger);

router.delete('/credit-entry/:id', deleteCreditEntry);
router.get('/account-types', getAccountTypes);
router.post('/create-account', createAccount);

// Direct function reference use karein
router.get('/trial-balance', getTrialBalance); 

module.exports = router;