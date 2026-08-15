const assert = require('assert');
const IntegrationService = require('../services/integrationService');
const EventService = require('../services/eventService');
const SessionService = require('../services/sessionService');
const ChildService = require('../services/childService');

async function runTests() {
  console.log('🧪 Running AI/ML Multimodal Integration Layer Test Suite (13 Test Cases)...\n');
  let passed = 0;
  let failed = 0;

  async function test(name, fn) {
    try {
      await fn();
      console.log(`  ✅ PASS: ${name}`);
      passed++;
    } catch (err) {
      console.error(`  ❌ FAIL: ${name}`);
      console.error(`     Error: ${err.message}`);
      failed++;
    }
  }

  // Pre-seed child and session for testing
  await ChildService.getChildById('A001');
  const session = await SessionService.startSession({ childId: 'A001', storyId: 'netaji' });
  const validSessionId = session.sessionId;

  // 1. Valid speech event
  await test('1. Valid speech event', async () => {
    const res = await IntegrationService.validateAndProcessEvent({
      source: 'python_speech',
      eventType: 'SPEECH_ANALYSIS',
      childId: 'A001',
      sessionId: validSessionId,
      activityId: 'netaji_q01',
      data: {
        transcript: 'Subhas Chandra Bose',
        speechDetected: true,
        speechAttempt: true,
        pronunciationScore: 82,
        responseTime: 4.2,
        confidence: 0.91
      }
    });
    assert.strictEqual(res.valid, true);
    assert.strictEqual(res.status, 201);
    assert.strictEqual(res.event.source, 'python_speech');
    assert.strictEqual(res.event.data.pronunciationScore, 82);
  });

  // 2. Invalid pronunciation score
  await test('2. Invalid pronunciation score (> 100)', async () => {
    const res = await IntegrationService.validateAndProcessEvent({
      source: 'python_speech',
      eventType: 'SPEECH_ANALYSIS',
      childId: 'A001',
      sessionId: validSessionId,
      activityId: 'netaji_q01',
      data: { pronunciationScore: 150 }
    });
    assert.strictEqual(res.valid, false);
    assert.strictEqual(res.status, 400);
    assert.ok(res.error.includes('pronunciationScore'));
  });

  // 3. Valid vision event
  await test('3. Valid vision event', async () => {
    const res = await IntegrationService.validateAndProcessEvent({
      source: 'python_vision',
      eventType: 'ENGAGEMENT_ANALYSIS',
      childId: 'A001',
      sessionId: validSessionId,
      activityId: 'netaji_q01',
      data: {
        faceDetected: true,
        lookingAtScreen: true,
        mouthMovement: true,
        engagementScore: 78
      }
    });
    assert.strictEqual(res.valid, true);
    assert.strictEqual(res.status, 201);
    assert.strictEqual(res.event.source, 'python_vision');
    assert.strictEqual(res.event.data.engagementScore, 78);
  });

  // 4. Invalid engagement score
  await test('4. Invalid engagement score (< 0)', async () => {
    const res = await IntegrationService.validateAndProcessEvent({
      source: 'python_vision',
      eventType: 'ENGAGEMENT_ANALYSIS',
      childId: 'A001',
      sessionId: validSessionId,
      activityId: 'netaji_q01',
      data: { engagementScore: -10 }
    });
    assert.strictEqual(res.valid, false);
    assert.strictEqual(res.status, 400);
    assert.ok(res.error.includes('engagementScore'));
  });

  // 5. Valid hardware event
  await test('5. Valid hardware event', async () => {
    const res = await IntegrationService.validateAndProcessEvent({
      source: 'mock_hardware',
      eventType: 'GRIP_DETECTED',
      childId: 'A001',
      sessionId: validSessionId,
      activityId: 'netaji_q01',
      data: { force: 1.8, duration: 2.4 }
    });
    assert.strictEqual(res.valid, true);
    assert.strictEqual(res.status, 201);
    assert.strictEqual(res.event.source, 'mock_hardware');
    assert.strictEqual(res.event.data.force, 1.8);
  });

  // 6. Invalid source
  await test('6. Invalid source', async () => {
    const res = await IntegrationService.validateAndProcessEvent({
      source: 'invalid_untrusted_source',
      eventType: 'SPEECH_ANALYSIS',
      childId: 'A001',
      sessionId: validSessionId,
      data: {}
    });
    assert.strictEqual(res.valid, false);
    assert.strictEqual(res.status, 400);
    assert.ok(res.error.includes('Unsupported event source'));
  });

  // 7. Invalid event type
  await test('7. Invalid event type', async () => {
    const res = await IntegrationService.validateAndProcessEvent({
      source: 'python_speech',
      eventType: 'UNSUPPORTED_RANDOM_EVENT',
      childId: 'A001',
      sessionId: validSessionId,
      data: {}
    });
    assert.strictEqual(res.valid, false);
    assert.strictEqual(res.status, 400);
    assert.ok(res.error.includes('Unsupported eventType'));
  });

  // 8. Missing child
  await test('8. Missing / Non-existent child', async () => {
    const res = await IntegrationService.validateAndProcessEvent({
      source: 'python_speech',
      eventType: 'SPEECH_ANALYSIS',
      childId: 'NON_EXISTENT_CHILD_999',
      sessionId: validSessionId,
      data: {}
    });
    assert.strictEqual(res.valid, false);
    assert.strictEqual(res.status, 404);
    assert.ok(res.error.includes('Child with id'));
  });

  // 9. Missing session
  await test('9. Missing / Non-existent session', async () => {
    const res = await IntegrationService.validateAndProcessEvent({
      source: 'python_speech',
      eventType: 'SPEECH_ANALYSIS',
      childId: 'A001',
      sessionId: 'NON_EXISTENT_SESSION_999',
      data: {}
    });
    assert.strictEqual(res.valid, false);
    assert.strictEqual(res.status, 404);
    assert.ok(res.error.includes('Session with id'));
  });

  // 10. Missing activity
  await test('10. Non-existent activity', async () => {
    const res = await IntegrationService.validateAndProcessEvent({
      source: 'python_speech',
      eventType: 'SPEECH_ANALYSIS',
      childId: 'A001',
      sessionId: validSessionId,
      activityId: 'NON_EXISTENT_ACTIVITY_999',
      data: {}
    });
    assert.strictEqual(res.valid, false);
    assert.strictEqual(res.status, 404);
    assert.ok(res.error.includes('Activity with id'));
  });

  // 11. Event persistence in existing Event System
  await test('11. Event persistence in existing Event System', async () => {
    const events = await EventService.getEvents({ sessionId: validSessionId });
    assert.ok(events.length >= 3);
    const speechEvt = events.find(e => e.source === 'python_speech');
    assert.ok(speechEvt !== undefined);
  });

  // 12. Server-generated eventId
  await test('12. Server-generated eventId', async () => {
    const res = await IntegrationService.validateAndProcessEvent({
      source: 'esp32',
      eventType: 'ROTATION_DETECTED',
      childId: 'A001',
      sessionId: validSessionId,
      data: { rotation: 90 }
    });
    assert.strictEqual(res.valid, true);
    assert.ok(res.event.eventId.startsWith('EVT_'));
  });

  // 13. Server-generated received timestamp
  await test('13. Server-generated received timestamp', async () => {
    const res = await IntegrationService.validateAndProcessEvent({
      source: 'esp32',
      eventType: 'PRESSURE_DETECTED',
      childId: 'A001',
      sessionId: validSessionId,
      data: { force: 2.1 }
    });
    assert.strictEqual(res.valid, true);
    assert.ok(res.event.serverReceivedAt !== undefined);
    assert.ok(!isNaN(Date.parse(res.event.serverReceivedAt)));
  });

  console.log(`\n=================================`);
  console.log(`🎉 TEST RESULTS: ${passed} Passed, ${failed} Failed`);
  console.log(`=================================\n`);

  if (failed > 0) {
    process.exit(1);
  }
}

runTests();
