const express = require('express');
const RecommendationController = require('../controllers/recommendationController');

const router = express.Router();

router.get('/children/:childId/recommendation', RecommendationController.getRecommendation);

module.exports = router;
