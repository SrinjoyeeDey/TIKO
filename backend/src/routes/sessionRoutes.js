const express = require('express');
const SessionController = require('../controllers/sessionController');

const router = express.Router();

router.post('/', SessionController.startSession);
router.get('/:sessionId', SessionController.getSessionById);
router.patch('/:sessionId/end', SessionController.endSession);
router.post('/:sessionId/interactions', SessionController.logInteraction);
router.patch('/:sessionId', SessionController.updateSession);

module.exports = router;
