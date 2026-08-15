const IntegrationService = require('../services/integrationService');

class IntegrationController {
  // POST /api/integrations/events
  static async processEvent(req, res) {
    try {
      const result = await IntegrationService.validateAndProcessEvent(req.body);
      if (!result.valid) {
        return res.status(result.status || 400).json({
          success: false,
          error: result.error
        });
      }

      return res.status(201).json({
        success: true,
        event: result.event.toJSON()
      });
    } catch (error) {
      return res.status(500).json({
        success: false,
        error: error.message
      });
    }
  }

  // GET /api/integrations/mocks
  static async getMocks(req, res) {
    const mocks = {
      successfulSpeech: {
        source: 'python_speech',
        eventType: 'SPEECH_ANALYSIS',
        childId: 'A001',
        sessionId: 'SES_001',
        activityId: 'netaji_q01',
        data: {
          transcript: 'Subhas Chandra Bose',
          speechDetected: true,
          speechAttempt: true,
          pronunciationScore: 82,
          responseTime: 4.2,
          confidence: 0.91
        }
      },
      failedSpeech: {
        source: 'python_speech',
        eventType: 'SPEECH_ANALYSIS',
        childId: 'A001',
        sessionId: 'SES_001',
        activityId: 'netaji_q01',
        data: {
          transcript: '',
          speechDetected: false,
          speechAttempt: false,
          pronunciationScore: 0,
          responseTime: 7.2,
          confidence: 0
        }
      },
      visionEngagement: {
        source: 'python_vision',
        eventType: 'ENGAGEMENT_ANALYSIS',
        childId: 'A001',
        sessionId: 'SES_001',
        activityId: 'netaji_q01',
        data: {
          faceDetected: true,
          lookingAtScreen: false,
          mouthMovement: false,
          engagementScore: 35
        }
      },
      mockHardwareGrip: {
        source: 'mock_hardware',
        eventType: 'GRIP_DETECTED',
        childId: 'A001',
        sessionId: 'SES_001',
        activityId: 'netaji_q01',
        data: {
          force: 1.8,
          duration: 2.4
        }
      }
    };

    return res.status(200).json({
      success: true,
      mocks
    });
  }
}

module.exports = IntegrationController;
