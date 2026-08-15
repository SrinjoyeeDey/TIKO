const EventService = require('../services/eventService');

class EventController {
  // POST /api/events
  static async logEvent(req, res) {
    try {
      const { childId, sessionId, eventType } = req.body || {};
      if (!childId || !sessionId || !eventType) {
        return res.status(400).json({
          success: false,
          error: 'childId, sessionId, and eventType are required fields'
        });
      }

      const event = await EventService.logEvent(req.body);
      return res.status(201).json({
        success: true,
        event: event.toJSON()
      });
    } catch (error) {
      return res.status(500).json({ success: false, error: error.message });
    }
  }

  // GET /api/events
  static async getEvents(req, res) {
    try {
      const { sessionId, childId } = req.query;
      const events = await EventService.getEvents({ sessionId, childId });
      return res.status(200).json({
        success: true,
        events: events.map(e => e.toJSON())
      });
    } catch (error) {
      return res.status(500).json({ success: false, error: error.message });
    }
  }
}

module.exports = EventController;
