const ProgressService = require('../services/progressService');

class ProgressController {
  // GET /api/children/:childId/progress
  static async getProgress(req, res) {
    try {
      const { childId } = req.params;
      const progressMap = await ProgressService.getProgress(childId);
      return res.status(200).json({
        success: true,
        skills: progressMap
      });
    } catch (error) {
      return res.status(500).json({ success: false, error: error.message });
    }
  }

  // GET /api/children/:childId/progress/:skill
  static async getSkillProgress(req, res) {
    try {
      const { childId, skill } = req.params;
      const skillProgress = await ProgressService.getSkillProgress(childId, skill);
      if (!skillProgress) {
        return res.status(404).json({ success: false, error: 'Skill progress not found' });
      }
      return res.status(200).json({
        success: true,
        skillProgress
      });
    } catch (error) {
      return res.status(500).json({ success: false, error: error.message });
    }
  }

  // GET /api/children/:childId/progress/history
  static async getProgressHistory(req, res) {
    try {
      const { childId } = req.params;
      const history = await ProgressService.getProgressHistory(childId);
      return res.status(200).json({
        success: true,
        history
      });
    } catch (error) {
      return res.status(500).json({ success: false, error: error.message });
    }
  }

  // GET /api/children/:childId/report
  static async getClinicalReport(req, res) {
    try {
      const { childId } = req.params;
      const report = await ProgressService.generateClinicalReport(childId);
      return res.status(200).json({
        success: true,
        report
      });
    } catch (error) {
      return res.status(500).json({ success: false, error: error.message });
    }
  }
}

module.exports = ProgressController;
