# Dakota Phone Automation System - Setup Guide

## Prerequisites

Before setting up the Dakota Phone Automation System, ensure you have:

1. **System Requirements:**
   - Docker 20.10 or higher
   - Docker Compose 2.0 or higher
   - 4GB RAM minimum (8GB recommended)
   - 20GB free disk space
   - Linux, macOS, or Windows with WSL2

2. **Service Accounts:**
   - ElevenLabs account with API access
   - Twilio account with phone number
   - TextingBiz account with API credentials
   - (Optional) DigitalOcean account for deployment

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/surfingcloud9/sc9-dakota-system.git
cd sc9-dakota-system
```

### 2. Configure Environment

```bash
# Copy environment template
cp .env.example .env

# Edit .env file with your credentials
nano .env  # or use your preferred editor
```

**Required Configuration:**

```bash
# n8n Authentication
N8N_BASIC_AUTH_PASSWORD=your_secure_password

# Database
DB_POSTGRESDB_PASSWORD=your_database_password

# ElevenLabs
ELEVENLABS_API_KEY=your_elevenlabs_api_key
ELEVENLABS_VOICE_ID=21m00Tcm4TlvDq8ikWAM  # Rachel voice

# Twilio
TWILIO_ACCOUNT_SID=your_twilio_account_sid
TWILIO_AUTH_TOKEN=your_twilio_auth_token
TWILIO_PHONE_NUMBER=+1234567890

# TextingBiz
TEXTINGBIZ_API_KEY=your_textingbiz_api_key
TEXTINGBIZ_API_URL=https://api.textingbiz.com/v1
```

### 3. Run Setup Script

```bash
chmod +x scripts/setup.sh
./scripts/setup.sh
```

The setup script will:
- Validate your configuration
- Create necessary directories
- Generate SSL certificates (development)
- Pull Docker images
- Start all services
- Initialize the database

### 4. Access n8n

Open your browser and navigate to:
- Local: http://localhost:5678
- Username: admin (or as configured in .env)
- Password: (as configured in .env)

### 5. Import Workflows

1. In n8n, click on **Workflows** in the sidebar
2. Click **Import from File**
3. Import each workflow from `n8n/workflows/`:
   - `dakota-phone-automation.json`
   - `incoming-call-handler.json`
   - `sms-response-workflow.json`

### 6. Configure Credentials

Follow the guide in `n8n/credentials/README.md` to set up:
- PostgreSQL connection
- Twilio API credentials
- ElevenLabs API (via environment variables)
- TextingBiz API (via environment variables)

## Getting API Credentials

### ElevenLabs

1. Visit https://elevenlabs.io/
2. Sign up for an account
3. Navigate to **Settings** → **API Keys**
4. Click **Generate API Key**
5. Copy the key to your `.env` file
6. Choose a voice from the Voice Library and copy its ID

**Popular Voices:**
- Rachel (21m00Tcm4TlvDq8ikWAM) - Professional, clear
- Antoni (ErXwobaYiN019PkySvjV) - Warm, friendly
- Bella (EXAVITQu4vr4xnSDxMaL) - Soft, engaging

### Twilio

1. Visit https://www.twilio.com/try-twilio
2. Sign up for an account
3. Go to **Console Dashboard**
4. Copy your **Account SID** and **Auth Token**
5. Purchase a phone number:
   - Navigate to **Phone Numbers** → **Buy a Number**
   - Select a number with Voice and SMS capabilities
6. Configure webhooks (see Webhook Configuration below)

### TextingBiz

1. Contact TextingBiz sales for API access
2. Request API credentials and documentation
3. Configure the API endpoint URL
4. Copy credentials to your `.env` file

## Webhook Configuration

### Configure Twilio Webhooks

1. Log in to Twilio Console
2. Navigate to **Phone Numbers** → **Manage** → **Active Numbers**
3. Click on your phone number
4. Configure the following webhooks:

**Voice Configuration:**
- **A Call Comes In:** Webhook
- URL: `https://your-domain.com/webhook/twilio-incoming`
- HTTP Method: POST

**Messaging Configuration:**
- **A Message Comes In:** Webhook
- URL: `https://your-domain.com/webhook/sms-received`
- HTTP Method: POST

**Status Callbacks:**
- Configure call status callback:
  - URL: `https://your-domain.com/webhook/call-status-update`
  - Events: Initiated, Ringing, Answered, Completed

### Configure TextingBiz Webhooks

1. Log in to TextingBiz dashboard
2. Navigate to **Settings** → **Webhooks**
3. Add webhook URL: `https://your-domain.com/webhook/sms-received`
4. Select events: Message Received, Delivery Status

## Testing the System

### Test ElevenLabs Integration

```bash
# Test voice generation
curl -X POST "https://api.elevenlabs.io/v1/text-to-speech/21m00Tcm4TlvDq8ikWAM" \
  -H "xi-api-key: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"text": "Hello from Dakota!", "model_id": "eleven_monolingual_v1"}' \
  --output test-voice.mp3
```

### Test Twilio Integration

```bash
# Test SMS sending
curl -X POST "https://api.twilio.com/2010-04-01/Accounts/YOUR_ACCOUNT_SID/Messages.json" \
  --data-urlencode "From=+1234567890" \
  --data-urlencode "To=+0987654321" \
  --data-urlencode "Body=Test from Dakota System" \
  -u YOUR_ACCOUNT_SID:YOUR_AUTH_TOKEN
```

### Test Dakota Workflow

```bash
# Trigger outbound call workflow
curl -X POST "http://localhost:5678/webhook/dakota-call" \
  -H "Content-Type: application/json" \
  -d '{
    "contact_name": "John Doe",
    "phone_number": "+1234567890",
    "script": "Hello John, this is Dakota calling to confirm your appointment."
  }'
```

## Troubleshooting

### Services Won't Start

```bash
# Check service status
docker-compose ps

# View logs
docker-compose logs

# Restart services
docker-compose restart
```

### Database Connection Issues

```bash
# Check PostgreSQL is running
docker-compose exec postgres pg_isready -U n8n_user

# Verify database exists
docker-compose exec postgres psql -U n8n_user -d n8n -c "SELECT 1;"
```

### n8n Won't Load

1. Check Docker logs: `docker-compose logs n8n`
2. Verify port 5678 is not in use: `lsof -i :5678`
3. Check environment variables are set correctly
4. Ensure database connection is working

### Webhook Not Receiving Calls

1. Verify webhook URLs are publicly accessible
2. Check ngrok or public domain is configured
3. Verify Twilio webhook configuration
4. Check n8n webhook is activated
5. Review n8n execution logs

## Development vs Production

### Development Setup (Current)
- Self-signed SSL certificates
- Local database and Redis
- Exposed ports for debugging
- HTTP webhooks (use ngrok for testing)

### Production Setup (See DEPLOYMENT.md)
- Let's Encrypt SSL certificates
- Managed database and Redis on DigitalOcean
- Private networks
- HTTPS webhooks only
- Rate limiting and monitoring

## Next Steps

1. ✅ Complete basic setup
2. ✅ Import workflows
3. ✅ Configure credentials
4. ✅ Test integrations
5. → Read [DEPLOYMENT.md](DEPLOYMENT.md) for production deployment
6. → Read [API.md](API.md) for API reference
7. → Customize workflows for your use case

## Getting Help

- n8n Documentation: https://docs.n8n.io/
- ElevenLabs Support: https://help.elevenlabs.io/
- Twilio Support: https://support.twilio.com/
- GitHub Issues: https://github.com/surfingcloud9/sc9-dakota-system/issues

## Backup and Restore

### Create Backup

```bash
./scripts/backup.sh
```

Backups are stored in `backups/` directory and include:
- n8n workflows
- PostgreSQL database
- Configuration files

### Restore from Backup

```bash
# Stop services
docker-compose down

# Extract backup
cd backups
tar -xzf dakota-backup-YYYYMMDD_HHMMSS.tar.gz

# Restore database
docker-compose up -d postgres
docker-compose exec -T postgres psql -U n8n_user n8n < dakota-backup-YYYYMMDD_HHMMSS/database.sql

# Restore workflows
cp -r dakota-backup-YYYYMMDD_HHMMSS/workflows/* n8n/workflows/

# Start all services
docker-compose up -d
```

## Support

For issues or questions:
1. Check this documentation
2. Review n8n logs: `docker-compose logs n8n`
3. Open an issue on GitHub
4. Contact support at support@surfingcloud9.com
