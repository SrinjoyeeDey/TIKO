const ActivityService = require('../services/activityService');

class ActivityController {
  // POST /api/activities
  static async createActivity(req, res) {
    try {
      const activityData = req.body;
      if (!activityData || !activityData.question) {
        return res.status(400).json({ success: false, error: 'Question content is required' });
      }
      const activity = await ActivityService.createActivity(activityData);
      return res.status(201).json(activity.toJSON());
    } catch (error) {
      return res.status(500).json({ success: false, error: error.message });
    }
  }

  // GET /api/activities/:activityId
  static async getActivityById(req, res) {
    try {
      const { activityId } = req.params;
      const activity = await ActivityService.getActivityById(activityId);
      if (!activity) {
        return res.status(404).json({ success: false, error: 'Activity not found' });
      }
      return res.status(200).json(activity.toJSON());
    } catch (error) {
      return res.status(500).json({ success: false, error: error.message });
    }
  }

  // GET /api/stories/:storyId/activities
  static async getActivitiesByStory(req, res) {
    try {
      const { storyId } = req.params;
      const activities = await ActivityService.getActivitiesByStory(storyId);
      return res.status(200).json({
        storyId,
        activities: activities.map(act => act.toJSON())
      });
    } catch (error) {
      return res.status(500).json({ success: false, error: error.message });
    }
  }
}

module.exports = ActivityController;
