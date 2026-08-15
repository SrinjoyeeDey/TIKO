const RecommendationService = require('../services/recommendationService');

class RecommendationController {
  // GET /api/children/:childId/recommendation
  static async getRecommendation(req, res) {
    try {
      const { childId } = req.params;
      const result = await RecommendationService.getRecommendation(childId);
      return res.status(200).json(result);
    } catch (error) {
      return res.status(500).json({ success: false, error: error.message });
    }
  }
}

module.exports = RecommendationController;
