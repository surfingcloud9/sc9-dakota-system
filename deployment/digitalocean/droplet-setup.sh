#!/bin/bash

# Dakota Phone Automation - DigitalOcean Droplet Setup Script
# This script sets up a Ubuntu 22.04 droplet for running the Dakota system

set -e

echo "================================================"
echo "Dakota Phone Automation - Droplet Setup"
echo "================================================"

# Update system
echo "Updating system packages..."
sudo apt-get update
sudo apt-get upgrade -y

# Install required packages
echo "Installing required packages..."
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    git \
    ufw \
    fail2ban

# Install Docker
echo "Installing Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
rm get-docker.sh

# Install Docker Compose
echo "Installing Docker Compose..."
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Configure firewall
echo "Configuring firewall..."
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw --force enable

# Create application directory
echo "Creating application directory..."
sudo mkdir -p /opt/dakota-system
sudo chown $USER:$USER /opt/dakota-system
cd /opt/dakota-system

# Clone repository (if not already present)
if [ ! -d ".git" ]; then
    echo "Cloning repository..."
    git clone https://github.com/surfingcloud9/sc9-dakota-system.git .
fi

# Create environment file
echo "Creating environment file..."
if [ ! -f ".env" ]; then
    cp .env.example .env
    echo "⚠️  IMPORTANT: Edit .env file with your actual credentials!"
fi

# Create necessary directories
echo "Creating directories..."
mkdir -p n8n/workflows
mkdir -p deployment/nginx/ssl
mkdir -p logs
mkdir -p backups

# Set up SSL certificate placeholder (use Let's Encrypt in production)
echo "Setting up SSL placeholders..."
if [ ! -f "deployment/nginx/ssl/cert.pem" ]; then
    echo "⚠️  SSL certificates not found. Use certbot to generate them."
    echo "Run: sudo certbot certonly --standalone -d your-domain.com"
fi

# Install Certbot for SSL
echo "Installing Certbot..."
sudo apt-get install -y certbot

# Create systemd service for auto-start
echo "Creating systemd service..."
sudo tee /etc/systemd/system/dakota-system.service > /dev/null <<EOF
[Unit]
Description=Dakota Phone Automation System
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/dakota-system
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

# Enable service
echo "Enabling Dakota system service..."
sudo systemctl daemon-reload
sudo systemctl enable dakota-system.service

# Set up log rotation
echo "Setting up log rotation..."
sudo tee /etc/logrotate.d/dakota-system > /dev/null <<EOF
/opt/dakota-system/logs/*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 $USER $USER
    sharedscripts
}
EOF

# Create backup script
echo "Creating backup script..."
cat > /opt/dakota-system/scripts/backup.sh <<'EOF'
#!/bin/bash
BACKUP_DIR="/opt/dakota-system/backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/backup_$DATE.tar.gz"

# Backup workflows and database
docker-compose exec -T postgres pg_dump -U n8n_user n8n > "$BACKUP_DIR/db_$DATE.sql"
tar -czf "$BACKUP_FILE" n8n/workflows/ "$BACKUP_DIR/db_$DATE.sql"

# Clean up old backups (keep 30 days)
find "$BACKUP_DIR" -name "backup_*.tar.gz" -mtime +30 -delete
find "$BACKUP_DIR" -name "db_*.sql" -mtime +30 -delete

echo "Backup completed: $BACKUP_FILE"
EOF

chmod +x /opt/dakota-system/scripts/backup.sh

# Set up cron for daily backups
echo "Setting up daily backup cron job..."
(crontab -l 2>/dev/null; echo "0 2 * * * /opt/dakota-system/scripts/backup.sh >> /opt/dakota-system/logs/backup.log 2>&1") | crontab -

# Create monitoring script
echo "Creating monitoring script..."
cat > /opt/dakota-system/scripts/monitor.sh <<'EOF'
#!/bin/bash
cd /opt/dakota-system

# Check if services are running
if ! docker-compose ps | grep -q "Up"; then
    echo "Services are down! Attempting restart..."
    docker-compose restart
fi

# Check disk space
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ $DISK_USAGE -gt 80 ]; then
    echo "WARNING: Disk usage is at ${DISK_USAGE}%"
fi

# Check memory usage
MEM_USAGE=$(free | grep Mem | awk '{print ($3/$2) * 100.0}' | cut -d. -f1)
if [ $MEM_USAGE -gt 80 ]; then
    echo "WARNING: Memory usage is at ${MEM_USAGE}%"
fi
EOF

chmod +x /opt/dakota-system/scripts/monitor.sh

# Set up monitoring cron (every 5 minutes)
echo "Setting up monitoring cron job..."
(crontab -l 2>/dev/null; echo "*/5 * * * * /opt/dakota-system/scripts/monitor.sh >> /opt/dakota-system/logs/monitor.log 2>&1") | crontab -

echo ""
echo "================================================"
echo "Setup Complete!"
echo "================================================"
echo ""
echo "Next steps:"
echo "1. Edit /opt/dakota-system/.env with your credentials"
echo "2. Generate SSL certificates:"
echo "   sudo certbot certonly --standalone -d your-domain.com"
echo "3. Update nginx.conf with your domain"
echo "4. Start the system:"
echo "   cd /opt/dakota-system"
echo "   docker-compose up -d"
echo "5. Access n8n at: http://your-droplet-ip:5678"
echo ""
echo "⚠️  Remember to configure DNS to point your domain to this droplet's IP"
echo "================================================"
