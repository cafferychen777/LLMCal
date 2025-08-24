/**
 * Mock Anthropic Claude API responses for testing
 * Provides realistic API response patterns and error conditions
 */

const http = require('http');

class AnthropicApiMock {
  constructor(port = 3003) {
    this.port = port;
    this.server = null;
  }

  start() {
    return new Promise((resolve) => {
      this.server = http.createServer((req, res) => {
        this.handleRequest(req, res);
      });

      this.server.listen(this.port, () => {
        console.log(`Anthropic API Mock server started on port ${this.port}`);
        resolve();
      });
    });
  }

  stop() {
    return new Promise((resolve) => {
      if (this.server) {
        this.server.close(() => {
          console.log('Anthropic API Mock server stopped');
          resolve();
        });
      } else {
        resolve();
      }
    });
  }

  handleRequest(req, res) {
    // CORS headers
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, x-api-key, anthropic-version');

    if (req.method === 'OPTIONS') {
      res.writeHead(200);
      res.end();
      return;
    }

    if (req.url === '/v1/messages' && req.method === 'POST') {
      this.handleMessagesRequest(req, res);
    } else {
      res.writeHead(404, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ 
        error: { 
          type: 'not_found_error', 
          message: 'The requested endpoint was not found.' 
        } 
      }));
    }
  }

  handleMessagesRequest(req, res) {
    const apiKey = req.headers['x-api-key'];
    const anthropicVersion = req.headers['anthropic-version'];

    // Check API key authentication
    if (!apiKey) {
      res.writeHead(401, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({
        error: {
          type: 'authentication_error',
          message: 'Missing API key'
        }
      }));
      return;
    }

    // Check for specific test keys
    if (apiKey === 'invalid-key') {
      res.writeHead(401, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({
        error: {
          type: 'authentication_error',
          message: 'Invalid API key'
        }
      }));
      return;
    }

    if (apiKey === 'rate-limit-key') {
      res.writeHead(429, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({
        error: {
          type: 'rate_limit_error',
          message: 'Rate limit exceeded'
        }
      }));
      return;
    }

    // Check anthropic version header
    if (!anthropicVersion) {
      res.writeHead(400, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({
        error: {
          type: 'invalid_request_error',
          message: 'Missing required header: anthropic-version'
        }
      }));
      return;
    }

    let body = '';
    req.on('data', chunk => {
      body += chunk.toString();
    });

    req.on('end', () => {
      try {
        const requestData = JSON.parse(body);
        this.processMessage(requestData, res);
      } catch (error) {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
          error: {
            type: 'invalid_request_error',
            message: 'Invalid JSON in request body'
          }
        }));
      }
    });
  }

  processMessage(requestData, res) {
    // Validate required fields
    if (!requestData.model) {
      res.writeHead(400, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({
        error: {
          type: 'invalid_request_error',
          message: 'Missing required field: model'
        }
      }));
      return;
    }

    if (!requestData.messages || !Array.isArray(requestData.messages) || requestData.messages.length === 0) {
      res.writeHead(400, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({
        error: {
          type: 'invalid_request_error',
          message: 'Missing or invalid messages array'
        }
      }));
      return;
    }

    const userMessage = requestData.messages[0];
    if (!userMessage.content) {
      res.writeHead(400, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({
        error: {
          type: 'invalid_request_error',
          message: 'Message content is required'
        }
      }));
      return;
    }

    // Generate appropriate response based on content
    const response = this.generateResponse(userMessage.content, requestData);

    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(response));
  }

  generateResponse(content, requestData) {
    // Analyze content to generate appropriate calendar event
    const eventData = this.parseEventFromContent(content);

    return {
      id: 'msg_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9),
      type: 'message',
      role: 'assistant',
      content: [{
        type: 'text',
        text: JSON.stringify(eventData, null, 2)
      }],
      model: requestData.model || 'claude-sonnet-4-20250514',
      stop_reason: 'end_turn',
      stop_sequence: null,
      usage: {
        input_tokens: this.estimateTokens(content),
        output_tokens: this.estimateTokens(JSON.stringify(eventData))
      }
    };
  }

  parseEventFromContent(content) {
    // Extract meeting details from content using simple pattern matching
    const lowerContent = content.toLowerCase();
    
    // Default event data
    let eventData = {
      title: 'Meeting',
      start_time: '2024-01-15 15:00',
      end_time: '2024-01-15 16:00',
      description: '',
      location: '',
      url: '',
      alerts: [15],
      recurrence: 'none',
      attendees: []
    };

    // Extract title from content
    const titlePatterns = [
      /convert text to calendar event:\s*['"]([^'"]+)['"]/i,
      /meeting[:\s]+([^.!?\n]+)/i,
      /call[:\s]+([^.!?\n]+)/i,
      /(team|project|client|review)[\s\w]*/i
    ];

    for (const pattern of titlePatterns) {
      const match = content.match(pattern);
      if (match && match[1]) {
        eventData.title = match[1].trim();
        break;
      }
    }

    // Extract time information
    const timePatterns = [
      /(\d{1,2}):?(\d{2})?\s*(am|pm)/gi,
      /(\d{1,2})\s*(am|pm)/gi,
      /(morning|afternoon|evening)/gi
    ];

    let foundTime = false;
    for (const pattern of timePatterns) {
      const match = content.match(pattern);
      if (match && !foundTime) {
        const hour = this.parseTimeToHour(match[0]);
        if (hour) {
          const startHour = hour.toString().padStart(2, '0');
          const endHour = (hour + 1).toString().padStart(2, '0');
          eventData.start_time = `2024-01-15 ${startHour}:00`;
          eventData.end_time = `2024-01-15 ${endHour}:00`;
          foundTime = true;
        }
      }
    }

    // Extract date information
    if (lowerContent.includes('tomorrow')) {
      const tomorrow = new Date();
      tomorrow.setDate(tomorrow.getDate() + 1);
      const dateStr = tomorrow.toISOString().split('T')[0];
      eventData.start_time = eventData.start_time.replace('2024-01-15', dateStr);
      eventData.end_time = eventData.end_time.replace('2024-01-15', dateStr);
    }

    // Extract location information
    if (lowerContent.includes('zoom')) {
      eventData.location = 'Zoom Meeting';
      eventData.url = 'https://zoom.us/j/123456789';
    } else if (lowerContent.includes('office')) {
      eventData.location = 'Office';
    } else if (lowerContent.includes('conference room')) {
      eventData.location = 'Conference Room';
    }

    // Extract duration
    const durationPatterns = [
      /(\d+)\s*hours?/i,
      /(\d+)\s*hr/i,
      /(\d+)\s*minutes?/i,
      /(\d+)\s*mins?/i
    ];

    for (const pattern of durationPatterns) {
      const match = content.match(pattern);
      if (match) {
        const value = parseInt(match[1]);
        if (pattern.source.includes('hour') || pattern.source.includes('hr')) {
          // Adjust end time based on hours
          const startTime = new Date(eventData.start_time + ':00');
          startTime.setHours(startTime.getHours() + value);
          eventData.end_time = startTime.toISOString().slice(0, 19).replace('T', ' ');
        } else if (pattern.source.includes('minute') || pattern.source.includes('min')) {
          // Adjust end time based on minutes
          const startTime = new Date(eventData.start_time + ':00');
          startTime.setMinutes(startTime.getMinutes() + value);
          eventData.end_time = startTime.toISOString().slice(0, 19).replace('T', ' ');
        }
        break;
      }
    }

    // Extract recurrence
    if (lowerContent.includes('daily') || lowerContent.includes('every day')) {
      eventData.recurrence = 'daily';
    } else if (lowerContent.includes('weekly') || lowerContent.includes('every week')) {
      eventData.recurrence = 'weekly';
    } else if (lowerContent.includes('monthly') || lowerContent.includes('every month')) {
      eventData.recurrence = 'monthly';
    }

    // Generate description
    eventData.description = `Meeting scheduled based on: "${content.slice(0, 100)}${content.length > 100 ? '...' : ''}"`;

    return eventData;
  }

  parseTimeToHour(timeStr) {
    const lowerTime = timeStr.toLowerCase();
    
    if (lowerTime.includes('morning')) return 9;
    if (lowerTime.includes('afternoon')) return 14;
    if (lowerTime.includes('evening')) return 18;

    const timeMatch = timeStr.match(/(\d{1,2}):?(\d{2})?\s*(am|pm)?/i);
    if (timeMatch) {
      let hour = parseInt(timeMatch[1]);
      const isPM = timeMatch[3] && timeMatch[3].toLowerCase() === 'pm';
      
      if (isPM && hour !== 12) hour += 12;
      if (!isPM && hour === 12) hour = 0;
      
      return hour;
    }

    return null;
  }

  estimateTokens(text) {
    // Rough estimation: ~4 characters per token
    return Math.ceil(text.length / 4);
  }
}

// Test scenarios
const testScenarios = {
  simpleMeeting: {
    input: "Team meeting tomorrow at 3pm",
    expected: {
      title: "Team meeting",
      location: "",
      start_time: "2024-01-16 15:00"
    }
  },

  zoomMeeting: {
    input: "Zoom call with client at 2:30 PM for 90 minutes",
    expected: {
      title: "call with client",
      location: "Zoom Meeting",
      url: "https://zoom.us/j/123456789"
    }
  },

  recurringMeeting: {
    input: "Weekly standup meeting every Monday at 9am",
    expected: {
      title: "standup meeting",
      recurrence: "weekly",
      start_time: "2024-01-15 09:00"
    }
  },

  detailedMeeting: {
    input: "Project review meeting in conference room tomorrow from 2pm to 4pm",
    expected: {
      title: "Project review meeting",
      location: "Conference Room",
      start_time: "2024-01-16 14:00",
      end_time: "2024-01-16 16:00"
    }
  }
};

module.exports = { AnthropicApiMock, testScenarios };