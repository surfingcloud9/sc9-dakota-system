# Dakota Phone Automation System - Deployment Guide

## Deployment Options

The Dakota Phone Automation System can be deployed in two ways:

1. **DigitalOcean App Platform** (Recommended) - Fully managed, auto-scaling
2. **DigitalOcean Droplet** - Self-managed, more control

## Option 1: DigitalOcean App Platform (Recommended)

### Prerequisites

- DigitalOcean account
- GitHub repository access
- Domain name (optional but recommended)

### Step 1: Prepare Repository

Ensure your repository has all required files committed:

```bash
git add .
git commit -m "Prepare for deployment"
git push origin main
```

### Step 2: Create App Platform App

1. Log in to DigitalOcean
2. Navigate to **Apps** in the control panel
3. Click **Create App**
4. Choose **GitHub** as source
5. Authorize DigitalOcean to access your repository
6. Select `surfingcloud9/sc9-dakota-system` repository
7. Choose `main` branch
8. Click **Next**

### Step 3: Configure App Spec

You can use the provided `deployment/digitalocean/app-spec.yaml` or configure manually:

1. Import the app spec:
   ```bash
   doctl apps create --spec deployment/digitalocean/app-spec.yaml
   ```

2. Or configure in the UI:
   - **n8n Service:**
     - Name: `n8n`
     - Build Command: (none, using Docker image)
     - Run Command: `n8n`
     - HTTP Port: 5678
     - Instance Size: Basic (512MB RAM)
     
   - **n8n Worker Service:**
     - Name: `n8n-worker`
     - Run Command: `n8n worker`
     - Instance Size: Basic (512MB RAM)

### Step 4: Add Database

1. In the App Platform UI, click **Add Resource**
2. Select **Database**
3. Choose **PostgreSQL**
4. Database Configuration:
   - Version: 15
   - Name: `db`
   - Size: Basic (1GB RAM, 10GB Disk)
   - Database Name: `n8n`
   - User: `n8n_user`

### Step 5: Add Redis

1. Click **Add Resource**
2. Select **Database**
3. Choose **Redis**
4. Configuration:
   - Version: 7
   - Name: `redis`
   - Size: Basic (1GB RAM)

### Step 6: Configure Environment Variables

Add the following environment variables in App Platform:

```bash
# n8n Configuration
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=<encrypted-secret>
N8N_HOST=<your-app-domain>
N8N_PROTOCOL=https
N8N_PORT=5678
WEBHOOK_URL=https://<your-app-domain>

# Database (auto-configured by App Platform)
DB_TYPE=postgresdb
DB_POSTGRESDB_HOST=${db.HOSTNAME}
DB_POSTGRESDB_PORT=${db.PORT}
DB_POSTGRESDB_DATABASE=${db.DATABASE}
DB_POSTGRESDB_USER=${db.USERNAME}
DB_POSTGRESDB_PASSWORD=${db.PASSWORD}

# Redis (auto-configured by App Platform)
QUEUE_BULL_REDIS_HOST=${redis.HOSTNAME}
QUEUE_BULL_REDIS_PORT=${redis.PORT}

# ElevenLabs
ELEVENLABS_API_KEY=<encrypted-secret>
ELEVENLABS_VOICE_ID=21m00Tcm4TlvDq8ikWAM

# Twilio
TWILIO_ACCOUNT_SID=<encrypted-secret>
TWILIO_AUTH_TOKEN=<encrypted-secret>
TWILIO_PHONE_NUMBER=+1234567890

# TextingBiz
TEXTINGBIZ_API_KEY=<encrypted-secret>
TEXTINGBIZ_API_URL=https://api.textingbiz.com/v1
```

**Note:** Use encrypted secrets for sensitive values.

### Step 7: Configure Domain (Optional)

1. In App Settings, go to **Domains**
2. Add your custom domain
3. Update DNS records as instructed
4. App Platform will provision SSL automatically

### Step 8: Deploy

1. Review configuration
2. Click **Create Resources**
3. Wait for deployment (5-10 minutes)
4. Monitor deployment logs in the UI

### Step 9: Initialize Database

After first deployment:

```bash
# Connect to your app using doctl
doctl apps list
doctl apps exec <app-id> --component n8n -- /bin/bash

# Run database initialization
psql $DATABASE_URL -f scripts/init-db.sql
```

### Step 10: Update Webhook URLs

Update Twilio and TextingBiz webhooks with your new domain:
- Replace `http://localhost:5678` with `https://your-app-domain.com`

## Option 2: DigitalOcean Droplet

### Step 1: Create Droplet

1. Log in to DigitalOcean
2. Click **Create** → **Droplets**
3. Choose:
   - Image: Ubuntu 22.04 LTS
   - Size: Basic - 2GB RAM, 2 vCPUs ($18/month)
   - Datacenter: Closest to your users
   - Authentication: SSH keys (recommended)
   - Hostname: `dakota-production`

### Step 2: Configure DNS

1. Add an A record pointing to your droplet's IP:
   ```
   dakota.yourdomain.com → <droplet-ip>
   ```

### Step 3: Run Setup Script

SSH into your droplet and run:

```bash
# Download and run setup script
curl -fsSL https://raw.githubusercontent.com/surfingcloud9/sc9-dakota-system/main/deployment/digitalocean/droplet-setup.sh -o setup.sh
chmod +x setup.sh
./setup.sh
```

The script will:
- Install Docker and Docker Compose
- Configure firewall
- Clone the repository
- Set up SSL with Certbot
- Create systemd service
- Configure automatic backups

### Step 4: Configure Environment

```bash
cd /opt/dakota-system
nano .env
```

Update all required credentials (same as App Platform).

### Step 5: Generate SSL Certificate

```bash
sudo certbot certonly --standalone -d dakota.yourdomain.com
```

Update nginx configuration with certificate paths:
```bash
sudo nano deployment/nginx/nginx.conf
# Update ssl_certificate and ssl_certificate_key paths
```

### Step 6: Start Services

```bash
cd /opt/dakota-system
sudo systemctl start dakota-system
sudo systemctl status dakota-system
```

### Step 7: Verify Deployment

```bash
# Check all services are running
docker-compose ps

# View logs
docker-compose logs -f

# Test endpoints
curl -I https://dakota.yourdomain.com/healthz
```

## Post-Deployment Configuration

### 1. Import Workflows

Access n8n at your domain and import workflows:
1. Navigate to **Workflows**
2. Click **Import from File**
3. Import all workflows from `n8n/workflows/`

### 2. Activate Workflows

For each imported workflow:
1. Open the workflow
2. Click **Settings** → **Active**
3. Verify webhook URLs are correct

### 3. Test Integration

Test each integration:

```bash
# Test outbound call
curl -X POST "https://dakota.yourdomain.com/webhook/dakota-call" \
  -H "Content-Type: application/json" \
  -d '{
    "contact_name": "Test User",
    "phone_number": "+1234567890",
    "script": "This is a test call from Dakota."
  }'
```

### 4. Configure Monitoring

Set up monitoring for:
- Service uptime
- Database performance
- Redis queue depth
- API rate limits
- Error rates

**Recommended Tools:**
- DigitalOcean Monitoring (built-in)
- UptimeRobot for external monitoring
- Sentry for error tracking
- Grafana for metrics visualization

### 5. Set Up Backups

**App Platform:**
- Database backups are automatic (daily)
- Configure backup retention in database settings

**Droplet:**
- Automated via cron (configured by setup script)
- Manual backup: `./scripts/backup.sh`
- Store backups off-site (S3, Spaces)

## Scaling Considerations

### Horizontal Scaling (App Platform)

1. In App Platform, go to your app settings
2. Navigate to the n8n-worker component
3. Increase instance count based on load
4. Workers will automatically distribute load via Redis queue

### Vertical Scaling

If experiencing performance issues:
1. Increase instance sizes:
   - App Platform: Upgrade to Professional tier
   - Droplet: Resize to 4GB or 8GB RAM
2. Upgrade database:
   - More RAM for better query performance
   - More storage for growing data
3. Upgrade Redis:
   - Larger instance for bigger queue

### Database Optimization

```sql
-- Add indexes for frequently queried fields
CREATE INDEX idx_call_logs_status ON call_logs(status);
CREATE INDEX idx_sms_direction ON sms_messages(direction);

-- Vacuum database regularly
VACUUM ANALYZE;
```

### Performance Monitoring

Monitor these metrics:
- Response time: < 200ms for webhooks
- Queue depth: < 100 jobs pending
- Database connections: < 80% of limit
- Memory usage: < 80% of available
- CPU usage: < 70% sustained

## Security Best Practices

### 1. Firewall Configuration

**App Platform:** Managed automatically

**Droplet:**
```bash
# Only allow necessary ports
sudo ufw allow 22/tcp   # SSH
sudo ufw allow 80/tcp   # HTTP
sudo ufw allow 443/tcp  # HTTPS
sudo ufw enable
```

### 2. SSL/TLS Configuration

- Use Let's Encrypt for free SSL
- Enable HTTPS-only access
- Configure HSTS headers (already in nginx.conf)
- Use TLS 1.2 minimum

### 3. Secrets Management

- Never commit secrets to Git
- Use DigitalOcean App Platform encrypted secrets
- Rotate API keys regularly (every 90 days)
- Use separate credentials for dev/staging/prod

### 4. Access Control

- Enable n8n basic authentication
- Use strong passwords (16+ characters)
- Limit database access to private network only
- Use SSH keys for droplet access (no password)

### 5. Webhook Security

```javascript
// In n8n workflows, verify Twilio signatures
const crypto = require('crypto');

function validateTwilioSignature(signature, url, params) {
  const authToken = $env.TWILIO_AUTH_TOKEN;
  const data = Object.keys(params)
    .sort()
    .map(key => key + params[key])
    .join('');
  
  const expectedSignature = crypto
    .createHmac('sha1', authToken)
    .update(url + data)
    .digest('base64');
  
  return signature === expectedSignature;
}
```

## Maintenance

### Regular Tasks

**Daily:**
- Monitor error logs
- Check queue depth
- Verify webhook endpoints

**Weekly:**
- Review system metrics
- Check backup completion
- Update dependencies if needed

**Monthly:**
- Rotate API keys
- Review and optimize workflows
- Clean up old logs and data
- Update SSL certificates (automatic with Let's Encrypt)

### Updates and Patches

```bash
# Update n8n to latest version
docker-compose pull
docker-compose up -d

# Update system packages (Droplet)
sudo apt-get update && sudo apt-get upgrade -y
```

### Troubleshooting Production Issues

**High Memory Usage:**
```bash
# Check container memory
docker stats

# Restart services if needed
docker-compose restart
```

**Database Connection Pool Exhausted:**
```sql
-- Check active connections
SELECT count(*) FROM pg_stat_activity;

-- Kill idle connections
SELECT pg_terminate_backend(pid) 
FROM pg_stat_activity 
WHERE state = 'idle' AND state_change < now() - interval '5 minutes';
```

**Queue Backed Up:**
```bash
# Check Redis queue
docker-compose exec redis redis-cli
> LLEN bull:n8n:*

# Clear queue if needed (use cautiously)
> FLUSHDB
```

## Rollback Procedure

If deployment fails:

**App Platform:**
1. Go to your app in DigitalOcean
2. Navigate to **Deployments**
3. Click on previous successful deployment
4. Click **Redeploy**

**Droplet:**
```bash
# Restore from backup
cd /opt/dakota-system
./scripts/restore.sh backups/dakota-backup-YYYYMMDD_HHMMSS.tar.gz

# Restart services
sudo systemctl restart dakota-system
```

## Cost Estimation

### App Platform (Managed)
- n8n Service: $12/month (Basic)
- n8n Worker: $12/month (Basic)
- PostgreSQL: $15/month (Basic)
- Redis: $15/month (Basic)
- **Total: ~$54/month**

### Droplet (Self-Managed)
- Droplet (2GB): $18/month
- **Total: ~$18/month**
- (Plus separate managed database/Redis if desired)

### Third-Party Services
- Twilio: Pay-as-you-go (varies by usage)
- ElevenLabs: $5-$99/month depending on usage
- TextingBiz: Contact for pricing

## Support

For deployment assistance:
- DigitalOcean Support: https://www.digitalocean.com/support/
- n8n Community: https://community.n8n.io/
- GitHub Issues: https://github.com/surfingcloud9/sc9-dakota-system/issues
