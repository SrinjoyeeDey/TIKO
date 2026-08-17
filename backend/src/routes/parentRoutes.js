const express = require('express');
const router = express.Router();
const parentController = require('../controllers/parentController');

router.post('/signup', (req, res) => parentController.signup(req, res));
router.post('/set-pin', (req, res) => parentController.setPin(req, res));
router.post('/verify-pin', (req, res) => parentController.verifyPin(req, res));
router.get('/:parentId/children', (req, res) => parentController.getChildren(req, res));
router.post('/:parentId/children', (req, res) => parentController.createChild(req, res));

module.exports = router;
