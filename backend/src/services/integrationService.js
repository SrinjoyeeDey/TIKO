const ChildService = require('./childService');
const SessionService = require('./sessionService');
const ActivityService = require('./activityService');
const EventService = require('./eventService');

const SUPPORTED_SOURCES = [
  'flutter',
  'python_speech',
  'python_vision',
  'esp32',
  'mock_hardware'
];

const SUPPORTED_EVENT_TYPES = [
  // Learning Events
  'SESSION_STARTED',
  'SESSION_COMPLETED',
  'ACTIVITY_STARTED',
  'ACTIVITY_COMPLETED',
  'ACTIVITY_SKIPPED',
  'ANSWER_SUBMITTED',
  'ANSWER_CORRECT',
  'ANSWER_WRONG',
  'HINT_USED',
  'RETRY',

  // Speech Events
  'SPEECH_ATTEMPT',
  'SPEECH_ANALYSIS',
  'PRONUNCIATION_ANALYSIS',

  // Vision Events
  'ENGAGEMENT_ANALYSIS',
  'ENGAGEMENT_SUMMARY',

  // Hardware Events
  'GRIP_DETECTED',
  'ROTATION_DETECTED',
  'MOVEMENT_DETECTED',
  'PRESSURE_DETECTED'
];

class IntegrationService {
  /**
   * Validate incoming external integration event and route into existing Event System
   */
  static async validateAndProcessEvent(payload) {
    const {
      childId,
      sessionId,
      activityId,
      source,
      eventType,
      timestamp,
      data = {}
    } = payload || {};

    // 1. Required Field Existence
    if (!childId) {
      return { valid: false, status: 400, error: 'Missing required field: childId' };
    }
    if (!sessionId) {
      return { valid: false, status: 400, error: 'Missing required field: sessionId' };
    }
    if (!eventType) {
      return { valid: false, status: 400, error: 'Missing required field: eventType' };
    }
    if (!source) {
      return { valid: false, status: 400, error: 'Missing required field: source' };
    }

    // 2. Validate Source Whitelist
    if (!SUPPORTED_SOURCES.includes(source)) {
      return {
        valid: false,
        status: 400,
        error: `Unsupported event source: "${source}". Must be one of: ${SUPPORTED_SOURCES.join(', ')}`
      };
    }

    // 3. Validate EventType Whitelist
    if (!SUPPORTED_EVENT_TYPES.includes(eventType)) {
      return {
        valid: false,
        status: 400,
        error: `Unsupported eventType: "${eventType}". Must be one of supported multimodal types.`
      };
    }

    // 4. Validate Child Existence (auto-register if new)
    let child = await ChildService.getChildById(childId);
    if (!child) {
      child = await ChildService.createChild({
        childId,
        name: childId === 'A001' ? 'Aarav' : `Child ${childId}`,
        age: 6
      });
    }

    // 5. Validate Session Existence (auto-register if new)
    let session = await SessionService.getSessionById(sessionId);
    if (!session) {
      session = await SessionService.startSession(childId, 'netaji');
      session.sessionId = sessionId;
      await SessionService.updateSession(sessionId, session);
    }

    // 6. Validate Activity Existence if supplied (auto-allow dynamic video/qa activities)
    if (activityId) {
      const activity = await ActivityService.getActivityById(activityId);
      if (!activity) {
        // Automatically create or treat as dynamic activity without throwing 404
      }
    }

    // 7. Validate Timestamp format if supplied
    if (timestamp) {
      const parsed = Date.parse(timestamp);
      if (isNaN(parsed)) {
        return { valid: false, status: 400, error: 'Invalid timestamp format. Must be an ISO 8601 string.' };
      }
    }

    // 8. Numeric Range Validations in `data`
    if (data) {
      // Speech validations
      if (data.pronunciationScore !== undefined && data.pronunciationScore !== null) {
        if (typeof data.pronunciationScore !== 'number' || data.pronunciationScore < 0 || data.pronunciationScore > 100) {
          return { valid: false, status: 400, error: 'Invalid pronunciationScore. Must be between 0 and 100.' };
        }
      }

      if (data.confidence !== undefined && data.confidence !== null) {
        if (typeof data.confidence !== 'number' || data.confidence < 0.0 || data.confidence > 1.0) {
          return { valid: false, status: 400, error: 'Invalid confidence. Must be between 0 and 1.0.' };
        }
      }

      if (data.responseTime !== undefined && data.responseTime !== null) {
        if (typeof data.responseTime !== 'number' || data.responseTime < 0) {
          return { valid: false, status: 400, error: 'Invalid responseTime. Must not be negative.' };
        }
      }

      // Vision validations
      if (data.engagementScore !== undefined && data.engagementScore !== null) {
        if (typeof data.engagementScore !== 'number' || data.engagementScore < 0 || data.engagementScore > 100) {
          return { valid: false, status: 400, error: 'Invalid engagementScore. Must be between 0 and 100.' };
        }
      }

      // Hardware validations
      if (data.force !== undefined && data.force !== null) {
        if (typeof data.force !== 'number' || data.force < 0) {
          return { valid: false, status: 400, error: 'Invalid force. Must not be negative.' };
        }
      }

      if (data.duration !== undefined && data.duration !== null) {
        if (typeof data.duration !== 'number' || data.duration < 0) {
          return { valid: false, status: 400, error: 'Invalid duration. Must not be negative.' };
        }
      }
    }

    // 9. Everything is valid -> Log into unified Event System!
    const event = await EventService.logEvent({
      childId,
      sessionId,
      activityId,
      source,
      eventType,
      timestamp,
      data
    });

    return {
      valid: true,
      status: 201,
      event
    };
  }
}

module.exports = IntegrationService;
