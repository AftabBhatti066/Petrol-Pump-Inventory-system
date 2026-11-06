const router = require('express').Router();
const c = require('../controllers/meterController');
router.get('/day', c.getDay);
router.post('/setup', c.initialize);
router.post('/save-day', c.saveDay);
router.get('/latest-date', c.getLatestDate);
router.get('/rates', c.getRates);
router.get('/all', c.getAllReadings);
router.get('/tank-stock', c.getTankStock);
router.get('/lubricant-stock', c.getLubricantStock);
// Old browser tabs must not bypass the new transaction/duplicate protections.
for (const route of ['/add','/add-reading','/update-receipt','/update-lubricants']) router.post(route,c.legacyWrite);
module.exports = router;
