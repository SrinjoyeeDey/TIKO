const ChildService = require('../services/childService');

class ChildController {
  // GET /api/children/:id
  static async getChildById(req, res) {
    try {
      const { id } = req.params;
      const child = await ChildService.getChildById(id);
      if (!child) {
        return res.status(404).json({ success: false, error: 'Child profile not found' });
      }
      return res.status(200).json({ success: true, data: child });
    } catch (error) {
      return res.status(500).json({ success: false, error: error.message });
    }
  }

  // POST /api/children
  static async createChild(req, res) {
    try {
      const childData = req.body;
      if (!childData || !childData.name) {
        return res.status(400).json({ success: false, error: 'Name is required' });
      }
      const newChild = await ChildService.createChild(childData);
      return res.status(201).json({ success: true, data: newChild });
    } catch (error) {
      return res.status(500).json({ success: false, error: error.message });
    }
  }

  // PATCH /api/children/:id
  static async updateChild(req, res) {
    try {
      const { id } = req.params;
      const updates = req.body;
      const updatedChild = await ChildService.updateChild(id, updates);
      if (!updatedChild) {
        return res.status(404).json({ success: false, error: 'Child profile not found' });
      }
      return res.status(200).json({ success: true, data: updatedChild });
    } catch (error) {
      return res.status(500).json({ success: false, error: error.message });
    }
  }

  // GET /api/children
  static async getAllChildren(req, res) {
    try {
      const children = await ChildService.getAllChildren();
      return res.status(200).json({ success: true, data: children });
    } catch (error) {
      return res.status(500).json({ success: false, error: error.message });
    }
  }
}

module.exports = ChildController;
