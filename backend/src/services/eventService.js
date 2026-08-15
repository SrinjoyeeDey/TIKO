const Event = require('../models/Event');

const eventsList = [];
let eventCounter = 1;

class EventService {
  /**
   * Log an event: generates eventId and serverReceivedAt timestamp automatically
   */
  static async logEvent(data) {
    const eventId = `EVT_${String(eventCounter++).padStart(3, '0')}`;
    const serverReceivedAt = new Date().toISOString();
    const timestamp = data.timestamp || serverReceivedAt;

    const event = new Event({
      eventId,
      childId: data.childId,
      sessionId: data.sessionId,
      activityId: data.activityId || null,
      source: data.source || 'flutter',
      eventType: data.eventType,
      timestamp,
      serverReceivedAt,
      data: data.data || {}
    });

    eventsList.push(event);
    console.log(`⚡ [EVENT LOGGED] [${event.source}] ${event.eventType} | childId: ${event.childId} | sessionId: ${event.sessionId} | activityId: ${event.activityId || 'N/A'}`);
    return event;
  }

  /**
   * Fetch all logged events, optionally filtered by sessionId or childId
   */
  static async getEvents({ sessionId, childId }) {
    return eventsList.filter(e => {
      if (sessionId && e.sessionId !== sessionId) return false;
      if (childId && e.childId !== childId) return false;
      return true;
    });
  }

  /**
   * Clear events list (useful for automated testing)
   */
  static clearEvents() {
    eventsList.length = 0;
  }
}

module.exports = EventService;
