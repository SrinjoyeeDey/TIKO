const ScoringService = require('../services/scoringService');

class ScoringController {
  // POST /api/scoring/evaluate
  static async evaluateActivity(req, res) {
    try {
      const { sessionId, activityId, childId } = req.body || {};
      if (!sessionId) {
        return res.status(400).json({
          success: false,
          error: 'sessionId is required for scoring evaluation'
        });
      }

      const evaluation = await ScoringService.evaluateActivity({
        sessionId,
        activityId,
        childId
      });

      return res.status(200).json({
        success: true,
        data: {
          result: evaluation.result.toJSON(),
          child: evaluation.child ? evaluation.child.toJSON() : null
        }
      });
    } catch (error) {
      return res.status(500).json({ success: false, error: error.message });
    }
  }

  // GET /api/results/:sessionId
  static async getResultsBySession(req, res) {
    try {
      const { sessionId } = req.params;
      const results = await ScoringService.getResultsBySession(sessionId);
      return res.status(200).json({
        success: true,
        results: results.map(r => r.toJSON())
      });
    } catch (error) {
      return res.status(500).json({ success: false, error: error.message });
    }
  }

  // GET /api/results/child/:childId
  static async getResultsByChild(req, res) {
    try {
      const { childId } = req.params;
      const results = await ScoringService.getResultsByChild(childId);
      return res.status(200).json({
        success: true,
        results: results.map(r => r.toJSON())
      });
    } catch (error) {
      return res.status(500).json({ success: false, error: error.message });
    }
  }
}

module.exports = ScoringController;
