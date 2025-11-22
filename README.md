# Dakota Phone Automation System

**Production-ready n8n workflow system for automated phone calls and SMS messaging**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![n8n](https://img.shields.io/badge/n8n-latest-orange)](https://n8n.io/)
[![Docker](https://img.shields.io/badge/docker-enabled-blue)](https://www.docker.com/)

## Overview

The Dakota Phone Automation System is a comprehensive, production-ready solution for automated phone interactions using n8n workflows. It seamlessly integrates ElevenLabs AI voice synthesis, Twilio telephony, and TextingBiz SMS services to create intelligent, automated communication workflows.

### Key Features

✅ **Visual Workflow Automation** - Powered by n8n for easy customization  
✅ **AI Voice Synthesis** - Natural-sounding voices via ElevenLabs  
✅ **Phone & SMS Integration** - Complete telephony via Twilio & TextingBiz  
✅ **Production-Ready** - Redis queue, PostgreSQL database, Docker deployment  
✅ **Scalable Architecture** - Horizontal scaling with worker nodes  
✅ **DigitalOcean Deployment** - One-click deployment with App Platform  
✅ **Comprehensive Documentation** - Setup, deployment, and API guides

## Quick Start

### Prerequisites

- Docker 20.10+ and Docker Compose 2.0+
- Accounts: [ElevenLabs](https://elevenlabs.io/), [Twilio](https://www.twilio.com/), TextingBiz
- 4GB RAM minimum (8GB recommended)

### Installation

```bash
# Clone the repository
git clone https://github.com/surfingcloud9/sc9-dakota-system.git
cd sc9-dakota-system

# Configure environment
cp .env.example .env
nano .env  # Add your API credentials

# Run setup script
chmod +x scripts/setup.sh
./scripts/setup.sh
```

Access n8n at **http://localhost:5678** (default credentials in `.env`)

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Dakota System                            │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────┐      ┌──────────┐      ┌───────────────┐     │
│  │   n8n    │◄────►│  Redis   │◄────►│  n8n Worker   │     │
│  │ (Main)   │      │  Queue   │      │   (Async)     │     │
│  └────┬─────┘      └──────────┘      └───────────────┘     │
│       │                                                       │
│       ├──────────────┬───────────────┬──────────────────┐   │
│       ▼              ▼               ▼                  ▼   │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐      ┌─────────┐│
│  │PostgreSQL│  │ElevenLabs│  │  Twilio  │      │Texting  ││
│  │ Database │  │   API    │  │   API    │      │Biz API  ││
│  └──────────┘  └──────────┘  └──────────┘      └─────────┘│
└─────────────────────────────────────────────────────────────┘
```

## Core Workflows

### 1. Dakota Phone Automation
Automated outbound calls with AI-generated voice
- Trigger: Webhook or scheduled
- Generates speech with ElevenLabs
- Makes call via Twilio
- Logs results to database
- Sends follow-up SMS

### 2. Incoming Call Handler
Intelligent handling of incoming calls
- Recognizes known vs unknown callers
- Plays personalized greetings
- Captures voice input (IVR)
- Routes to appropriate handlers

### 3. SMS Response Workflow
Automated SMS processing and responses
- Parses incoming messages
- Detects intent (help, appointment, etc.)
- Sends intelligent auto-responses
- Manages opt-in/opt-out preferences

## Project Structure

```
sc9-dakota-system/
├── GITHUB-COPILOT-PROMPT.md    # Complete system specification
├── docker-compose.yml           # Multi-container orchestration
├── .env.example                 # Environment template
├── n8n/
│   ├── workflows/               # n8n workflow definitions
│   └── credentials/             # Credential setup guide
├── deployment/
│   ├── digitalocean/            # DigitalOcean deployment configs
│   └── nginx/                   # Reverse proxy configuration
├── scripts/
│   ├── setup.sh                 # Initial setup script
│   └── backup.sh                # Backup workflows and data
└── docs/
    ├── SETUP.md                 # Setup instructions
    ├── DEPLOYMENT.md            # Deployment guide
    └── API.md                   # API documentation
```

## Documentation

- **[Setup Guide](docs/SETUP.md)** - Local development setup
- **[Deployment Guide](docs/DEPLOYMENT.md)** - Production deployment
- **[API Documentation](docs/API.md)** - Webhook endpoints and database schema
- **[Credentials Guide](n8n/credentials/README.md)** - API credential setup

## Technology Stack

| Component | Technology | Purpose |
|-----------|-----------|---------|
| Workflow Engine | n8n | Visual workflow automation |
| Voice Synthesis | ElevenLabs | AI-powered text-to-speech |
| Telephony | Twilio | Phone calls and SMS |
| SMS Gateway | TextingBiz | SMS messaging |
| Database | PostgreSQL 15 | Data persistence |
| Queue | Redis 7 | Job queue for scalability |
| Proxy | Nginx | Reverse proxy and SSL |
| Container | Docker | Containerization |
| Deployment | DigitalOcean | Cloud hosting |

## Configuration

Key environment variables (see `.env.example` for complete list):

```bash
# n8n Configuration
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=your_password

# ElevenLabs
ELEVENLABS_API_KEY=your_api_key
ELEVENLABS_VOICE_ID=21m00Tcm4TlvDq8ikWAM

# Twilio
TWILIO_ACCOUNT_SID=your_account_sid
TWILIO_AUTH_TOKEN=your_auth_token
TWILIO_PHONE_NUMBER=+1234567890

# TextingBiz
TEXTINGBIZ_API_KEY=your_api_key
TEXTINGBIZ_API_URL=https://api.textingbiz.com/v1
```

## API Usage

### Trigger Outbound Call

```bash
curl -X POST "http://localhost:5678/webhook/dakota-call" \
  -H "Content-Type: application/json" \
  -d '{
    "contact_name": "John Doe",
    "phone_number": "+1234567890",
    "script": "Hello John, this is Dakota calling with an important message."
  }'
```

### Process Incoming SMS

```bash
curl -X POST "http://localhost:5678/webhook/sms-received" \
  -d "From=+1234567890" \
  -d "Body=HELP"
```

See [API Documentation](docs/API.md) for complete endpoint reference.

## Deployment

### DigitalOcean App Platform (Recommended)

```bash
doctl apps create --spec deployment/digitalocean/app-spec.yaml
```

### DigitalOcean Droplet

```bash
ssh root@your-droplet-ip
curl -fsSL https://raw.githubusercontent.com/surfingcloud9/sc9-dakota-system/main/deployment/digitalocean/droplet-setup.sh | bash
```

See [Deployment Guide](docs/DEPLOYMENT.md) for detailed instructions.

## Maintenance

### Backup

```bash
./scripts/backup.sh
```

Backups are stored in `backups/` and include:
- n8n workflows
- PostgreSQL database
- Configuration files

### Monitoring

```bash
# View logs
docker-compose logs -f

# Check service status
docker-compose ps

# View resource usage
docker stats
```

## Security

- ✅ SSL/TLS encryption (production)
- ✅ Basic authentication for n8n UI
- ✅ Environment variable secrets
- ✅ Webhook signature verification
- ✅ Firewall configuration
- ✅ Rate limiting via Nginx
- ✅ Database connection encryption

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## Support

- **Documentation**: Check [docs/](docs/) directory
- **Issues**: [GitHub Issues](https://github.com/surfingcloud9/sc9-dakota-system/issues)
- **Email**: support@surfingcloud9.com

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [n8n](https://n8n.io/) - Workflow automation platform
- [ElevenLabs](https://elevenlabs.io/) - AI voice synthesis
- [Twilio](https://www.twilio.com/) - Cloud communications
- [DigitalOcean](https://www.digitalocean.com/) - Cloud infrastructure

---

**Built with ❤️ by SurfingCloud9**
