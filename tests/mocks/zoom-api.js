/**
 * Mock Zoom API responses for testing
 * Provides realistic Zoom API response patterns and error conditions
 */

const http = require('http');

class ZoomApiMock {
  constructor(apiPort = 3004, oauthPort = 3005) {
    this.apiPort = apiPort;
    this.oauthPort = oauthPort;
    this.apiServer = null;
    this.oauthServer = null;
    this.meetings = new Map(); // Store created meetings
    this.meetingIdCounter = 123456789;
  }

  start() {
    return Promise.all([
      this.startOAuthServer(),
      this.startApiServer()
    ]);
  }

  stop() {
    return Promise.all([
      this.stopOAuthServer(),
      this.stopApiServer()
    ]);
  }

  startOAuthServer() {
    return new Promise((resolve) => {
      this.oauthServer = http.createServer((req, res) => {
        this.handleOAuthRequest(req, res);
      });

      this.oauthServer.listen(this.oauthPort, () => {
        console.log(`Zoom OAuth Mock server started on port ${this.oauthPort}`);
        resolve();
      });
    });
  }

  startApiServer() {
    return new Promise((resolve) => {
      this.apiServer = http.createServer((req, res) => {
        this.handleApiRequest(req, res);
      });

      this.apiServer.listen(this.apiPort, () => {
        console.log(`Zoom API Mock server started on port ${this.apiPort}`);
        resolve();
      });
    });
  }

  stopOAuthServer() {
    return new Promise((resolve) => {
      if (this.oauthServer) {
        this.oauthServer.close(() => {
          console.log('Zoom OAuth Mock server stopped');
          resolve();
        });
      } else {
        resolve();
      }
    });
  }

  stopApiServer() {
    return new Promise((resolve) => {
      if (this.apiServer) {
        this.apiServer.close(() => {
          console.log('Zoom API Mock server stopped');
          resolve();
        });
      } else {
        resolve();
      }
    });
  }

  handleOAuthRequest(req, res) {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Content-Type', 'application/json');

    if (req.method === 'OPTIONS') {
      res.writeHead(200);
      res.end();
      return;
    }

    if (req.url.includes('/oauth/token') && req.method === 'POST') {
      this.handleTokenRequest(req, res);
    } else {
      res.writeHead(404, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ 
        error: 'invalid_request',
        error_description: 'The request is missing a required parameter.'
      }));
    }
  }

  handleTokenRequest(req, res) {
    const authHeader = req.headers.authorization;
    const url = new URL(req.url, `http://localhost:${this.oauthPort}`);
    const grantType = url.searchParams.get('grant_type');
    const accountId = url.searchParams.get('account_id');

    // Validate authorization header
    if (!authHeader || !authHeader.startsWith('Basic ')) {
      res.writeHead(401, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({
        error: 'invalid_client',
        error_description: 'Invalid client credentials'
      }));
      return;
    }

    // Decode basic auth
    const base64Credentials = authHeader.replace('Basic ', '');
    const credentials = Buffer.from(base64Credentials, 'base64').toString('ascii');
    const [clientId, clientSecret] = credentials.split(':');

    // Test scenarios for different credential combinations
    const testCredentials = {
      'invalid-client': 'invalid_client_error',
      'expired-client': 'invalid_client_error', 
      'rate-limit-client': 'rate_limit_error',
      'test-client-id': 'success'
    };

    const credentialResult = testCredentials[clientId];

    if (credentialResult === 'invalid_client_error') {
      res.writeHead(401, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({
        error: 'invalid_client',
        error_description: 'Invalid client credentials'
      }));
      return;
    }

    if (credentialResult === 'rate_limit_error') {
      res.writeHead(429, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({
        error: 'rate_limit_exceeded',
        error_description: 'Rate limit exceeded. Please try again later.'
      }));
      return;
    }

    // Validate grant type and account ID
    if (grantType !== 'account_credentials') {
      res.writeHead(400, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({
        error: 'unsupported_grant_type',
        error_description: 'Grant type not supported'
      }));
      return;
    }

    if (!accountId) {
      res.writeHead(400, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({
        error: 'invalid_request',
        error_description: 'Missing account_id parameter'
      }));
      return;
    }

    // Generate access token
    const accessToken = this.generateAccessToken(clientId, accountId);

    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({
      access_token: accessToken,
      token_type: 'bearer',
      expires_in: 3600,
      scope: 'meeting:write meeting:read'
    }));
  }

  handleApiRequest(req, res) {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Content-Type', 'application/json');

    if (req.method === 'OPTIONS') {
      res.writeHead(200);
      res.end();
      return;
    }

    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      res.writeHead(401, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({
        code: 124,
        message: 'Invalid access token'
      }));
      return;
    }

    const token = authHeader.replace('Bearer ', '');
    
    // Validate token
    if (!this.isValidToken(token)) {
      res.writeHead(401, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({
        code: 124,
        message: 'Invalid access token'
      }));
      return;
    }

    // Route API requests
    if (req.url === '/v2/users/me/meetings' && req.method === 'POST') {
      this.handleCreateMeeting(req, res);
    } else if (req.url.match(/^\/v2\/meetings\/\d+$/) && req.method === 'GET') {
      this.handleGetMeeting(req, res);
    } else if (req.url.match(/^\/v2\/meetings\/\d+$/) && req.method === 'DELETE') {
      this.handleDeleteMeeting(req, res);
    } else if (req.url === '/v2/users/me' && req.method === 'GET') {
      this.handleGetUser(req, res);
    } else {
      res.writeHead(404, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({
        code: 404,
        message: 'Resource not found'
      }));
    }
  }

  handleCreateMeeting(req, res) {
    let body = '';
    req.on('data', chunk => {
      body += chunk.toString();
    });

    req.on('end', () => {
      try {
        const meetingData = JSON.parse(body);
        
        // Validate required fields
        if (!meetingData.topic) {
          res.writeHead(400, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({
            code: 300,
            message: 'Meeting topic is required',
            errors: [{ field: 'topic', message: 'Required field is missing' }]
          }));
          return;
        }

        // Create meeting object
        const meeting = this.createMeeting(meetingData);
        this.meetings.set(meeting.id, meeting);

        res.writeHead(201, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify(meeting));

      } catch (error) {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
          code: 300,
          message: 'Invalid request format',
          errors: [{ field: 'body', message: 'Invalid JSON format' }]
        }));
      }
    });
  }

  handleGetMeeting(req, res) {
    const meetingId = parseInt(req.url.split('/').pop());
    const meeting = this.meetings.get(meetingId);

    if (!meeting) {
      res.writeHead(404, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({
        code: 3001,
        message: 'Meeting not found'
      }));
      return;
    }

    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(meeting));
  }

  handleDeleteMeeting(req, res) {
    const meetingId = parseInt(req.url.split('/').pop());
    
    if (this.meetings.has(meetingId)) {
      this.meetings.delete(meetingId);
      res.writeHead(204);
      res.end();
    } else {
      res.writeHead(404, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({
        code: 3001,
        message: 'Meeting not found'
      }));
    }
  }

  handleGetUser(req, res) {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({
      id: 'mock_user_id',
      first_name: 'Test',
      last_name: 'User',
      email: 'test@example.com',
      type: 1,
      role_name: 'Owner',
      pmi: 1234567890,
      use_pmi: false,
      timezone: 'America/New_York',
      verified: 1,
      dept: 'Engineering',
      created_at: '2024-01-01T00:00:00Z',
      last_login_time: '2024-01-15T10:00:00Z',
      last_client_version: '5.9.0.1234',
      language: 'en-US',
      phone_country: 'US',
      phone_number: '+15551234567',
      status: 'active'
    }));
  }

  createMeeting(meetingData) {
    const meetingId = this.meetingIdCounter++;
    const uuid = this.generateUuid();
    const password = this.generatePassword();
    
    return {
      uuid: uuid,
      id: meetingId,
      host_id: 'mock_host_id_12345',
      host_email: 'test@example.com',
      topic: meetingData.topic,
      type: meetingData.type || 2,
      status: 'waiting',
      start_time: meetingData.start_time || new Date().toISOString(),
      duration: meetingData.duration || 60,
      timezone: meetingData.timezone || 'UTC',
      agenda: meetingData.agenda || '',
      created_at: new Date().toISOString(),
      join_url: `https://zoom.us/j/${meetingId}?pwd=${password}`,
      start_url: `https://zoom.us/s/${meetingId}?zak=mock_zak_token`,
      password: password.slice(0, 6),
      h323_password: '123456',
      pstn_password: '123456',
      encrypted_password: password,
      settings: {
        host_video: meetingData.settings?.host_video !== undefined ? meetingData.settings.host_video : true,
        participant_video: meetingData.settings?.participant_video !== undefined ? meetingData.settings.participant_video : true,
        cn_meeting: false,
        in_meeting: false,
        join_before_host: meetingData.settings?.join_before_host !== undefined ? meetingData.settings.join_before_host : true,
        mute_upon_entry: meetingData.settings?.mute_upon_entry !== undefined ? meetingData.settings.mute_upon_entry : false,
        watermark: false,
        use_pmi: false,
        approval_type: 2,
        registration_type: 1,
        audio: 'both',
        auto_recording: meetingData.settings?.auto_recording || 'none',
        enforce_login: false,
        enforce_login_domains: '',
        alternative_hosts: '',
        close_registration: false,
        show_share_button: true,
        allow_multiple_devices: true,
        registrants_email_notification: meetingData.settings?.registrants_email_notification !== undefined ? meetingData.settings.registrants_email_notification : true,
        meeting_invitees: meetingData.settings?.meeting_invitees || [],
        email_notification: meetingData.settings?.email_notification !== undefined ? meetingData.settings.email_notification : true,
        calendar_type: meetingData.settings?.calendar_type || 1,
        schedule_for_reminder: meetingData.settings?.schedule_for_reminder !== undefined ? meetingData.settings.schedule_for_reminder : true,
        contact_name: meetingData.settings?.contact_name || 'Test User',
        contact_email: meetingData.settings?.contact_email || 'test@example.com'
      },
      pre_schedule: false,
      occurrences: meetingData.recurrence ? this.generateOccurrences(meetingData.recurrence) : undefined,
      recurrence: meetingData.recurrence ? {
        type: meetingData.recurrence.type || 1,
        repeat_interval: meetingData.recurrence.repeat_interval || 1,
        weekly_days: meetingData.recurrence.weekly_days || '2',
        monthly_day: meetingData.recurrence.monthly_day || 1,
        monthly_week: meetingData.recurrence.monthly_week || 1,
        monthly_week_day: meetingData.recurrence.monthly_week_day || 2,
        end_times: meetingData.recurrence.end_times || 10,
        end_date_time: meetingData.recurrence.end_date_time
      } : undefined
    };
  }

  generateAccessToken(clientId, accountId) {
    const tokenData = {
      iss: clientId,
      aud: 'zoom',
      iat: Math.floor(Date.now() / 1000),
      exp: Math.floor(Date.now() / 1000) + 3600,
      accountId: accountId
    };
    
    // Simple token generation for testing
    return 'mock_token_' + Buffer.from(JSON.stringify(tokenData)).toString('base64').replace(/=/g, '');
  }

  generateUuid() {
    return 'mock-uuid-' + Math.random().toString(36).substr(2, 9) + '-' + Date.now();
  }

  generatePassword() {
    return Math.random().toString(36).substr(2, 12) + Math.random().toString(36).substr(2, 12);
  }

  generateOccurrences(recurrence) {
    const occurrences = [];
    const baseDate = new Date();
    
    for (let i = 0; i < (recurrence.end_times || 5); i++) {
      const occurrenceDate = new Date(baseDate);
      
      switch (recurrence.type) {
        case 1: // Daily
          occurrenceDate.setDate(baseDate.getDate() + i * (recurrence.repeat_interval || 1));
          break;
        case 2: // Weekly
          occurrenceDate.setDate(baseDate.getDate() + i * 7 * (recurrence.repeat_interval || 1));
          break;
        case 3: // Monthly
          occurrenceDate.setMonth(baseDate.getMonth() + i * (recurrence.repeat_interval || 1));
          break;
      }
      
      occurrences.push({
        occurrence_id: 'occurrence_' + i,
        start_time: occurrenceDate.toISOString(),
        duration: 60,
        status: 'available'
      });
    }
    
    return occurrences;
  }

  isValidToken(token) {
    // Simple token validation for testing
    return token && (
      token.startsWith('mock_token_') ||
      token === 'test-valid-token' ||
      token === 'mock_access_token_12345'
    );
  }
}

// Test scenarios for Zoom API
const zoomTestScenarios = {
  successfulMeeting: {
    request: {
      topic: 'Test Meeting',
      type: 2,
      start_time: '2024-01-15T15:00:00Z',
      duration: 60,
      timezone: 'America/New_York',
      settings: {
        host_video: true,
        participant_video: true,
        join_before_host: true
      }
    },
    expectedStatus: 201
  },

  missingTopic: {
    request: {
      type: 2,
      start_time: '2024-01-15T15:00:00Z',
      duration: 60
    },
    expectedStatus: 400,
    expectedError: 'Meeting topic is required'
  },

  invalidToken: {
    request: {
      topic: 'Test Meeting'
    },
    token: 'invalid_token_123',
    expectedStatus: 401,
    expectedError: 'Invalid access token'
  },

  recurringMeeting: {
    request: {
      topic: 'Weekly Standup',
      type: 8,
      start_time: '2024-01-15T09:00:00Z',
      duration: 30,
      recurrence: {
        type: 2,
        repeat_interval: 1,
        weekly_days: '2',
        end_times: 10
      }
    },
    expectedStatus: 201
  },

  meetingWithSettings: {
    request: {
      topic: 'Team Meeting',
      type: 2,
      start_time: '2024-01-15T14:00:00Z',
      duration: 90,
      settings: {
        host_video: true,
        participant_video: false,
        join_before_host: true,
        mute_upon_entry: true,
        auto_recording: 'cloud',
        meeting_invitees: [
          { email: 'alice@example.com' },
          { email: 'bob@example.com' }
        ]
      }
    },
    expectedStatus: 201
  }
};

module.exports = { ZoomApiMock, zoomTestScenarios };