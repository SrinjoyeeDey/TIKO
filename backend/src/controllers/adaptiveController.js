const AdaptiveService = require('../services/adaptiveService');

class AdaptiveController {
  // GET /api/children/:childId/next-activity
  static async getNextActivity(req, res) {
    try {
      const { childId } = req.params;
      const { skill } = req.query;
      const response = await AdaptiveService.getNextActivity(childId, skill);
      return res.status(200).json(response);
    } catch (error) {
      return res.status(500).json({ success: false, error: error.message });
    }
  }

  // POST /api/adaptive/evaluate
  static async evaluateChild(req, res) {
    try {
      const { childId, skill } = req.body || {};
      if (!childId) {
        return res.status(400).json({ success: false, error: 'childId is required' });
      }

      const decision = await AdaptiveService.evaluateChild(childId, skill);
      return res.status(200).json({
        success: true,
        decision: decision.toJSON()
      });
    } catch (error) {
      return res.status(500).json({ success: false, error: error.message });
    }
  }
}

module.exports = AdaptiveController;
