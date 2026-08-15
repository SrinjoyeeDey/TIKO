const express = require('express');
const EventController = require('../controllers/eventController');

const router = express.Router();

router.post('/', EventController.logEvent);
router.get('/', EventController.getEvents);

module.exports = router;
