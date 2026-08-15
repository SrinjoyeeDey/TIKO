/**
 * Event Model Schema Definition & Factory
 */
class Event {
  constructor({
    eventId,
    childId,
    sessionId,
    activityId = null,
    source = 'flutter',
    eventType,
    timestamp = new Date().toISOString(),
    serverReceivedAt = new Date().toISOString(),
    data = {}
  }) {
    const id = eventId || `EVT_${Date.now()}`;
    this.eventId = id;
    this.childId = childId;
    this.sessionId = sessionId;
    this.activityId = activityId;
    this.source = source || 'flutter';
    this.eventType = eventType;
    this.timestamp = timestamp;
    this.serverReceivedAt = serverReceivedAt;
    this.data = data || {};
  }

  toJSON() {
    return {
      eventId: this.eventId,
      childId: this.childId,
      sessionId: this.sessionId,
      activityId: this.activityId,
      source: this.source,
      eventType: this.eventType,
      timestamp: this.timestamp,
      serverReceivedAt: this.serverReceivedAt,
      data: this.data,
    };
  }
}

module.exports = Event;
