const express = require('express');
const cors = require('cors');
const parentRoutes = require('./routes/parentRoutes');
const childRoutes = require('./routes/childRoutes');
const sessionRoutes = require('./routes/sessionRoutes');
const activityRoutes = require('./routes/activityRoutes');
const storyRoutes = require('./routes/storyRoutes');
const eventRoutes = require('./routes/eventRoutes');
const scoringRoutes = require('./routes/scoringRoutes');
const progressRoutes = require('./routes/progressRoutes');
const adaptiveRoutes = require('./routes/adaptiveRoutes');
const recommendationRoutes = require('./routes/recommendationRoutes');
const integrationRoutes = require('./routes/integrationRoutes');

const app = express();
const PORT = process.env.PORT || 3000;

// Enable CORS for Flutter Web / Desktop / Mobile
app.use(cors());
app.use(express.json());

// Request logging middleware
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
  next();
});

// API Routes
app.use('/api/parents', parentRoutes);
app.use('/api/children', childRoutes);
app.use('/api/sessions', sessionRoutes);
app.use('/api/activities', activityRoutes);
app.use('/api/stories', storyRoutes);
app.use('/api/events', eventRoutes);
app.use('/api', scoringRoutes);
app.use('/api', progressRoutes);
app.use('/api', adaptiveRoutes);
app.use('/api', recommendationRoutes);
app.use('/api/integrations', integrationRoutes);

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.status(200).json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Start Express Server
const server = app.listen(PORT, () => {
  console.log(`=================================`);
  console.log(`🚀 Peppa Backend running on port ${PORT}`);
  console.log(`   Health: http://localhost:${PORT}/api/health`);
  console.log(`   Children: http://localhost:${PORT}/api/children`);
  console.log(`   Sessions: http://localhost:${PORT}/api/sessions`);
  console.log(`=================================`);
});

server.on('error', (err) => {
  if (err.code === 'EADDRINUSE') {
    console.error(`❌ Port ${PORT} is already in use by another process.`);
    console.error(`   Please stop the existing Node process or set PORT environment variable.`);
  } else {
    console.error('❌ Server error:', err);
  }
});

module.exports = app;
