# Dakota Phone Automation System - n8n Workflow

## Overview
Build a production-ready n8n workflow system for Dakota phone automation with seamless integrations for ElevenLabs (voice synthesis), Twilio (phone calls), and TextingBiz (SMS messaging). Deploy on DigitalOcean with Redis queue for reliability.

## System Architecture

### Core Components
1. **n8n Workflow Engine** - Visual workflow automation platform
2. **Redis Queue** - Message queue for reliable job processing
3. **PostgreSQL Database** - Data persistence for n8n workflows
4. **Docker Containers** - Containerized deployment

### Service Integrations
1. **ElevenLabs** - AI voice synthesis for natural phone conversations
2. **Twilio** - Telephony API for making/receiving calls
3. **TextingBiz** - SMS messaging service

## File Structure

```
sc9-dakota-system/
├── docker-compose.yml          # Multi-container orchestration
├── .env.example                # Environment variables template
├── n8n/
│   ├── workflows/
│   │   ├── dakota-phone-automation.json    # Main phone automation workflow
│   │   ├── incoming-call-handler.json      # Handle incoming calls
│   │   └── sms-response-workflow.json      # SMS automation
│   └── credentials/
│       └── README.md                        # Credential setup guide
├── deployment/
│   ├── digitalocean/
│   │   ├── app-spec.yaml                   # DigitalOcean App Platform config
│   │   └── droplet-setup.sh                # Droplet initialization script
│   └── nginx/
│       └── nginx.conf                       # Reverse proxy configuration
├── scripts/
│   ├── setup.sh                            # Initial setup script
│   └── backup.sh                           # Backup workflows and data
└── docs/
    ├── SETUP.md                            # Setup instructions
    ├── DEPLOYMENT.md                       # Deployment guide
    └── API.md                              # API documentation
```

## Dependencies

### Runtime Dependencies
- **n8n** (^1.0.0) - Workflow automation
- **Redis** (^7.0) - Message queue
- **PostgreSQL** (^15.0) - Database
- **Node.js** (^20.0) - Runtime environment

### Integration SDKs
- **elevenlabs** - ElevenLabs API client
- **twilio** - Twilio API client
- **axios** - HTTP client for TextingBiz API

## Docker Configuration

### Services
1. **n8n**: Port 5678, connected to PostgreSQL and Redis
2. **postgres**: Port 5432, persistent volume
3. **redis**: Port 6379, persistent volume
4. **nginx**: Port 80/443, SSL termination

## n8n Workflows

### 1. Dakota Phone Automation Workflow
**Triggers:**
- Webhook trigger for external system integration
- Schedule trigger for automated outbound calls

**Flow:**
1. Receive call request with contact info
2. Generate personalized script using ElevenLabs
3. Initiate call via Twilio
4. Process call responses
5. Store results in database
6. Send follow-up SMS via TextingBiz

### 2. Incoming Call Handler
**Triggers:**
- Twilio webhook for incoming calls

**Flow:**
1. Receive incoming call webhook
2. Play greeting using ElevenLabs voice
3. Capture caller input (IVR)
4. Route to appropriate handler
5. Log interaction
6. Send summary SMS

### 3. SMS Response Workflow
**Triggers:**
- TextingBiz webhook for incoming SMS

**Flow:**
1. Receive SMS webhook
2. Parse message content
3. Generate response
4. Send reply via TextingBiz
5. Update contact record

## Environment Variables

```bash
# n8n Configuration
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=secure_password
N8N_HOST=dakota.yourdomain.com
N8N_PROTOCOL=https
N8N_PORT=5678

# Database
DB_TYPE=postgresdb
DB_POSTGRESDB_HOST=postgres
DB_POSTGRESDB_PORT=5432
DB_POSTGRESDB_DATABASE=n8n
DB_POSTGRESDB_USER=n8n_user
DB_POSTGRESDB_PASSWORD=secure_db_password

# Redis Queue
QUEUE_BULL_REDIS_HOST=redis
QUEUE_BULL_REDIS_PORT=6379
EXECUTIONS_MODE=queue

# ElevenLabs
ELEVENLABS_API_KEY=your_elevenlabs_api_key
ELEVENLABS_VOICE_ID=your_preferred_voice_id

# Twilio
TWILIO_ACCOUNT_SID=your_twilio_account_sid
TWILIO_AUTH_TOKEN=your_twilio_auth_token
TWILIO_PHONE_NUMBER=+1234567890

# TextingBiz
TEXTINGBIZ_API_KEY=your_textingbiz_api_key
TEXTINGBIZ_API_URL=https://api.textingbiz.com/v1
```

## DigitalOcean Deployment

### Option 1: App Platform (Recommended)
- Use app-spec.yaml for automated deployment
- Managed PostgreSQL and Redis
- Auto-scaling and SSL

### Option 2: Droplet
- Ubuntu 22.04 LTS
- Docker and Docker Compose
- Manual setup with droplet-setup.sh
- Nginx for reverse proxy

## Production Features

### High Availability
- Redis queue for job distribution
- Database connection pooling
- Automatic workflow recovery

### Security
- Basic auth for n8n UI
- Environment variable secrets
- SSL/TLS encryption
- Webhook signature verification

### Monitoring
- n8n execution logs
- Redis queue metrics
- Database performance monitoring
- Error alerting via SMS/email

### Backup & Recovery
- Automated workflow exports
- Database backups (daily)
- Redis persistence (AOF)

## Getting Started

1. Clone repository
2. Copy `.env.example` to `.env`
3. Configure all API credentials
4. Run `./scripts/setup.sh`
5. Access n8n at http://localhost:5678
6. Import workflows from `n8n/workflows/`
7. Test each integration
8. Deploy to DigitalOcean

## API Endpoints

### Webhook Endpoints
- `POST /webhook/dakota-call` - Trigger outbound call
- `POST /webhook/twilio-incoming` - Handle incoming call
- `POST /webhook/sms-received` - Process incoming SMS

### Health Check
- `GET /healthz` - Service health status

## Testing

1. **Local Development**: Test workflows in n8n UI
2. **Integration Tests**: Verify each service connection
3. **End-to-End Tests**: Complete call flow simulation
4. **Load Testing**: Validate queue performance

## Support & Documentation

- n8n Documentation: https://docs.n8n.io
- ElevenLabs API: https://docs.elevenlabs.io
- Twilio API: https://www.twilio.com/docs
- TextingBiz API: Contact provider for documentation

## Notes

- All workflows are version-controlled in JSON format
- Credentials are stored securely in n8n's encrypted storage
- Production deployment uses managed services for reliability
- System supports horizontal scaling for high volume
