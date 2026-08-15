const SessionService = require('../services/sessionService');

class SessionController {
  // POST /api/sessions
  static async startSession(req, res) {
    try {
      const { childId, storyId } = req.body;
      if (!childId) {
        return res.status(400).json({ success: false, error: 'childId is required to start a session' });
      }
      const session = await SessionService.startSession(childId, storyId || 'netaji');
      return res.status(201).json(session.toJSON());
    } catch (error) {
      return res.status(500).json({ success: false, error: error.message });
    }
  }

  // GET /api/sessions/:sessionId
  static async getSessionById(req, res) {
    try {
      const { sessionId } = req.params;
      const session = await SessionService.getSessionById(sessionId);
      if (!session) {
        return res.status(404).json({ success: false, error: 'Session not found' });
      }
      return res.status(200).json(session.toJSON());
    } catch (error) {
      return res.status(500).json({ success: false, error: error.message });
    }
  }

  // PATCH /api/sessions/:sessionId/end
  static async endSession(req, res) {
    try {
      const { sessionId } = req.params;
      const { endedAt } = req.body || {};
      const session = await SessionService.endSession(sessionId, endedAt);
      if (!session) {
        return res.status(404).json({ success: false, error: 'Session not found' });
      }
      return res.status(200).json(session.toJSON());
    } catch (error) {
      return res.status(500).json({ success: false, error: error.message });
    }
  }

  // POST /api/sessions/:sessionId/interactions
  static async logInteraction(req, res) {
    try {
      const { sessionId } = req.params;
      const interactionData = req.body;
      const result = await SessionService.logInteraction(sessionId, interactionData);
      if (!result) {
        return res.status(404).json({ success: false, error: 'Session not found' });
      }
      return res.status(200).json({ success: true, data: result.interaction });
    } catch (error) {
      return res.status(500).json({ success: false, error: error.message });
    }
  }

  // PATCH /api/sessions/:sessionId
  static async updateSession(req, res) {
    try {
      const { sessionId } = req.params;
      const updates = req.body;
      const updatedSession = await SessionService.updateSession(sessionId, updates);
      if (!updatedSession) {
        return res.status(404).json({ success: false, error: 'Session not found' });
      }
      return res.status(200).json(updatedSession.toJSON());
    } catch (error) {
      return res.status(500).json({ success: false, error: error.message });
    }
  }
}

module.exports = SessionController;
