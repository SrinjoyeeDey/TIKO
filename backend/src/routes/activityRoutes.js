const express = require('express');
const ActivityController = require('../controllers/activityController');

const router = express.Router();

router.post('/', ActivityController.createActivity);
router.get('/:activityId', ActivityController.getActivityById);

module.exports = router;
