const express = require('express');
const ProgressController = require('../controllers/progressController');

const router = express.Router();

router.get('/children/:childId/progress', ProgressController.getProgress);
router.get('/children/:childId/progress/history', ProgressController.getProgressHistory);
router.get('/children/:childId/progress/:skill', ProgressController.getSkillProgress);

module.exports = router;
