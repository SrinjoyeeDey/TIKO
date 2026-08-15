const express = require('express');
const ScoringController = require('../controllers/scoringController');

const router = express.Router();

router.post('/scoring/evaluate', ScoringController.evaluateActivity);
router.get('/results/:sessionId', ScoringController.getResultsBySession);
router.get('/results/child/:childId', ScoringController.getResultsByChild);

module.exports = router;
