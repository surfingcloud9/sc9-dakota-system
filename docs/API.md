# Dakota Phone Automation System - API Documentation

## Overview

The Dakota Phone Automation System exposes several webhook endpoints for triggering workflows and receiving callbacks from external services.

## Base URL

- **Local Development:** `http://localhost:5678`
- **Production:** `https://your-domain.com`

## Authentication

### n8n UI Access
- Method: Basic Authentication
- Username: Configured in `N8N_BASIC_AUTH_USER`
- Password: Configured in `N8N_BASIC_AUTH_PASSWORD`

### Webhook Endpoints
- No authentication required (use webhook signatures for verification)
- Recommended: Verify Twilio webhook signatures
- Optional: Add custom authentication in workflows

## Endpoints

### 1. Trigger Outbound Call

Initiates an automated outbound call with custom script.

**Endpoint:** `POST /webhook/dakota-call`

**Request Body:**
```json
{
  "contact_name": "John Doe",
  "phone_number": "+1234567890",
  "script": "Hello John, this is Dakota calling to confirm your appointment tomorrow at 3 PM. Please reply YES to confirm or NO to reschedule.",
  "voice_id": "21m00Tcm4TlvDq8ikWAM"
}
```

**Parameters:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| contact_name | string | Yes | Name of the person to call |
| phone_number | string | Yes | E.164 format phone number (+1234567890) |
| script | string | Yes | Text to be spoken during the call |
| voice_id | string | No | ElevenLabs voice ID (defaults to env var) |

**Response:**
```json
{
  "success": true,
  "call_id": "CALL-1700000000000",
  "status": "completed",
  "message": "Call completed and logged successfully"
}
```

**Status Codes:**
- `200 OK` - Call initiated successfully
- `400 Bad Request` - Invalid parameters
- `500 Internal Server Error` - Call failed

**Example:**

```bash
curl -X POST "https://your-domain.com/webhook/dakota-call" \
  -H "Content-Type: application/json" \
  -d '{
    "contact_name": "Jane Smith",
    "phone_number": "+19876543210",
    "script": "Hello Jane, this is a reminder about your upcoming appointment."
  }'
```

---

### 2. Handle Incoming Call

Receives webhooks from Twilio when an incoming call is received.

**Endpoint:** `POST /webhook/twilio-incoming`

**Request Body:** (Sent by Twilio)
```
CallSid=CA1234567890abcdef
From=+1234567890
To=+0987654321
CallStatus=ringing
Direction=inbound
```

**Response:** TwiML XML
```xml
<?xml version="1.0" encoding="UTF-8"?>
<Response>
  <Say voice="Polly.Joanna">Hello! Thank you for calling Dakota.</Say>
  <Gather input="speech" action="/webhook/ivr-response" method="POST" timeout="5">
    <Say>Please tell me how I can help you.</Say>
  </Gather>
  <Say>Thank you. We'll process your request and get back to you shortly.</Say>
  <Hangup/>
</Response>
```

**Configuration:**
Set this URL in Twilio Console under your phone number's voice configuration.

---

### 3. Receive SMS Message

Processes incoming SMS messages from Twilio or TextingBiz.

**Endpoint:** `POST /webhook/sms-received`

**Request Body:** (Twilio format)
```
MessageSid=SM1234567890abcdef
From=+1234567890
To=+0987654321
Body=HELP
```

**Response:**
```json
{
  "success": true,
  "message": "SMS processed successfully",
  "action": "help_request"
}
```

**Supported Commands:**

| Command | Description | Response |
|---------|-------------|----------|
| HELP | Request assistance | Sends help information |
| STOP | Unsubscribe from messages | Unsubscribes user |
| START | Resubscribe to messages | Resubscribes user |
| YES | Confirm action | Confirms request |
| NO | Cancel action | Cancels request |
| APPOINTMENT | Schedule appointment | Sends scheduling info |

**Example:**

```bash
# Simulate incoming SMS
curl -X POST "https://your-domain.com/webhook/sms-received" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "MessageSid=SM1234567890abcdef" \
  -d "From=+1234567890" \
  -d "To=+0987654321" \
  -d "Body=HELP"
```

---

### 4. Call Status Update

Receives call status updates from Twilio.

**Endpoint:** `POST /webhook/call-status-update`

**Request Body:** (Sent by Twilio)
```
CallSid=CA1234567890abcdef
CallStatus=completed
CallDuration=45
RecordingUrl=https://...
```

**Response:**
```json
{
  "success": true,
  "message": "Status updated"
}
```

**Call Status Values:**
- `queued` - Call is queued
- `initiated` - Call has been initiated
- `ringing` - Phone is ringing
- `in-progress` - Call is in progress
- `completed` - Call completed successfully
- `busy` - Line was busy
- `no-answer` - No answer
- `canceled` - Call was canceled
- `failed` - Call failed

---

### 5. Recording Complete

Receives notification when call recording is complete.

**Endpoint:** `POST /webhook/recording-complete`

**Request Body:** (Sent by Twilio)
```
RecordingSid=RE1234567890abcdef
RecordingUrl=https://api.twilio.com/...
CallSid=CA1234567890abcdef
Duration=45
```

**Response:**
```json
{
  "success": true,
  "message": "Recording processed"
}
```

---

### 6. Health Check

Check if the system is running and healthy.

**Endpoint:** `GET /healthz`

**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2025-11-22T18:20:00.000Z",
  "services": {
    "n8n": "up",
    "postgres": "up",
    "redis": "up"
  }
}
```

**Status Codes:**
- `200 OK` - System is healthy
- `503 Service Unavailable` - System is unhealthy

---

## Database Schema

### call_logs Table

Stores information about outbound calls.

```sql
CREATE TABLE call_logs (
    id SERIAL PRIMARY KEY,
    call_id VARCHAR(255) UNIQUE NOT NULL,
    contact_name VARCHAR(255),
    phone_number VARCHAR(50) NOT NULL,
    status VARCHAR(50),
    duration INTEGER DEFAULT 0,
    recording_url TEXT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    success BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### incoming_calls Table

Stores information about incoming calls.

```sql
CREATE TABLE incoming_calls (
    id SERIAL PRIMARY KEY,
    call_sid VARCHAR(255) UNIQUE NOT NULL,
    caller_phone VARCHAR(50) NOT NULL,
    caller_name VARCHAR(255),
    is_known BOOLEAN DEFAULT FALSE,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### sms_messages Table

Stores all SMS messages (inbound and outbound).

```sql
CREATE TABLE sms_messages (
    id SERIAL PRIMARY KEY,
    message_sid VARCHAR(255) UNIQUE NOT NULL,
    from_phone VARCHAR(50) NOT NULL,
    to_phone VARCHAR(50) NOT NULL,
    message_body TEXT,
    direction VARCHAR(20) CHECK (direction IN ('inbound', 'outbound')),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### contacts Table

Stores contact information and preferences.

```sql
CREATE TABLE contacts (
    id SERIAL PRIMARY KEY,
    phone_number VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(255),
    email VARCHAR(255),
    sms_opt_in BOOLEAN DEFAULT TRUE,
    call_opt_in BOOLEAN DEFAULT TRUE,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

---

## Query Examples

### Get Recent Calls

```sql
SELECT 
    call_id,
    contact_name,
    phone_number,
    status,
    duration,
    timestamp
FROM call_logs
WHERE timestamp >= NOW() - INTERVAL '7 days'
ORDER BY timestamp DESC
LIMIT 50;
```

### Get Call Success Rate

```sql
SELECT 
    COUNT(*) as total_calls,
    COUNT(CASE WHEN success = TRUE THEN 1 END) as successful_calls,
    ROUND(COUNT(CASE WHEN success = TRUE THEN 1 END)::NUMERIC / COUNT(*)::NUMERIC * 100, 2) as success_rate
FROM call_logs
WHERE timestamp >= NOW() - INTERVAL '30 days';
```

### Get SMS Conversation

```sql
SELECT 
    message_sid,
    CASE 
        WHEN direction = 'inbound' THEN from_phone
        ELSE to_phone
    END as contact_phone,
    message_body,
    direction,
    timestamp
FROM sms_messages
WHERE from_phone = '+1234567890' OR to_phone = '+1234567890'
ORDER BY timestamp ASC;
```

### Get Contact Activity

```sql
SELECT 
    c.name,
    c.phone_number,
    COUNT(DISTINCT cl.call_id) as total_calls,
    COUNT(DISTINCT sm.message_sid) as total_sms,
    MAX(GREATEST(cl.timestamp, sm.timestamp)) as last_activity
FROM contacts c
LEFT JOIN call_logs cl ON c.phone_number = cl.phone_number
LEFT JOIN sms_messages sm ON c.phone_number = sm.from_phone OR c.phone_number = sm.to_phone
GROUP BY c.id, c.name, c.phone_number
ORDER BY last_activity DESC NULLS LAST;
```

---

## Rate Limits

### Default Limits

- Webhook endpoints: 100 requests/second
- API endpoints: 10 requests/second
- Configurable in `deployment/nginx/nginx.conf`

### Twilio Limits

- API calls: 100 requests/second
- Concurrent calls: Based on account type
- SMS: 1 message/second per long code

### ElevenLabs Limits

- Free tier: 10,000 characters/month
- Paid tiers: Higher limits based on plan
- API rate limit: 5 requests/second

---

## Error Codes

### Common HTTP Status Codes

| Code | Meaning | Description |
|------|---------|-------------|
| 200 | OK | Request successful |
| 400 | Bad Request | Invalid parameters or malformed request |
| 401 | Unauthorized | Missing or invalid authentication |
| 403 | Forbidden | Insufficient permissions |
| 404 | Not Found | Endpoint or resource not found |
| 429 | Too Many Requests | Rate limit exceeded |
| 500 | Internal Server Error | Server-side error occurred |
| 503 | Service Unavailable | Service is temporarily unavailable |

### Custom Error Responses

```json
{
  "success": false,
  "error": {
    "code": "INVALID_PHONE_NUMBER",
    "message": "The phone number format is invalid",
    "details": "Phone number must be in E.164 format (+1234567890)"
  }
}
```

---

## Webhooks Security

### Verifying Twilio Signatures

Twilio signs all webhook requests. Verify signatures to ensure requests are authentic:

```javascript
const crypto = require('crypto');

function validateTwilioRequest(twilioSignature, url, params) {
  const authToken = process.env.TWILIO_AUTH_TOKEN;
  
  // Create signature
  const data = Object.keys(params)
    .sort()
    .reduce((acc, key) => acc + key + params[key], '');
  
  const expectedSignature = crypto
    .createHmac('sha1', authToken)
    .update(url + data)
    .digest('base64');
  
  return crypto.timingSafeEqual(
    Buffer.from(twilioSignature),
    Buffer.from(expectedSignature)
  );
}
```

**Implementation in n8n:**
Add signature verification in the webhook workflow using a Function node.

---

## Best Practices

### 1. Use E.164 Format for Phone Numbers
Always format phone numbers as: `+[country code][number]`
- ✅ Good: `+1234567890`
- ❌ Bad: `(123) 456-7890`, `1234567890`

### 2. Handle Webhook Failures
Implement retry logic for webhook failures:
- Twilio retries up to 3 times
- Implement idempotency using message/call IDs
- Store and process failed webhooks later

### 3. Rate Limit Protection
- Use exponential backoff for API calls
- Monitor rate limit headers
- Cache frequently accessed data

### 4. Data Privacy
- Store sensitive data encrypted
- Comply with TCPA regulations
- Implement opt-out mechanisms
- Respect user preferences

### 5. Error Handling
- Log all errors with context
- Implement graceful degradation
- Send alerts for critical failures
- Monitor error rates

---

## Testing

### Test Outbound Call

```bash
#!/bin/bash

# Test Dakota outbound call
curl -X POST "http://localhost:5678/webhook/dakota-call" \
  -H "Content-Type: application/json" \
  -d '{
    "contact_name": "Test User",
    "phone_number": "+1234567890",
    "script": "This is a test call from Dakota system."
  }' | jq
```

### Test SMS Processing

```bash
# Test SMS webhook
curl -X POST "http://localhost:5678/webhook/sms-received" \
  -d "MessageSid=SMtest123" \
  -d "From=+1234567890" \
  -d "To=+0987654321" \
  -d "Body=HELP" | jq
```

### Load Testing

Use tools like Apache Bench or Artillery for load testing:

```bash
# Install Artillery
npm install -g artillery

# Create test scenario
cat > load-test.yml <<EOF
config:
  target: "http://localhost:5678"
  phases:
    - duration: 60
      arrivalRate: 10
scenarios:
  - name: "Trigger calls"
    flow:
      - post:
          url: "/webhook/dakota-call"
          json:
            contact_name: "Load Test"
            phone_number: "+1234567890"
            script: "Test message"
EOF

# Run load test
artillery run load-test.yml
```

---

## Support

For API questions or issues:
- Check workflow execution logs in n8n
- Review this documentation
- Open an issue on GitHub
- Contact support@surfingcloud9.com
