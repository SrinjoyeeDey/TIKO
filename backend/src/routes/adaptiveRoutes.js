const express = require('express');
const AdaptiveController = require('../controllers/adaptiveController');

const router = express.Router();

router.get('/children/:childId/next-activity', AdaptiveController.getNextActivity);
router.post('/adaptive/evaluate', AdaptiveController.evaluateChild);

module.exports = router;
