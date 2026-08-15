const express = require('express');
const IntegrationController = require('../controllers/integrationController');

const router = express.Router();

router.post('/events', IntegrationController.processEvent);
router.get('/mocks', IntegrationController.getMocks);

module.exports = router;
