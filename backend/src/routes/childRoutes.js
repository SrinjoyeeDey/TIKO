const express = require('express');
const ChildController = require('../controllers/childController');

const router = express.Router();

router.get('/', ChildController.getAllChildren);
router.get('/:id', ChildController.getChildById);
router.post('/', ChildController.createChild);
router.patch('/:id', ChildController.updateChild);

module.exports = router;
