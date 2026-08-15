const express = require('express');
const ActivityController = require('../controllers/activityController');

const router = express.Router();

// GET /api/stories/:storyId/activities
router.get('/:storyId/activities', ActivityController.getActivitiesByStory);

module.exports = router;
