#!/bin/bash

# Dakota Phone Automation System - Setup Script
# This script initializes the system for first-time use

set -e

echo "================================================"
echo "Dakota Phone Automation System - Setup"
echo "================================================"
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    echo "Visit: https://docs.docker.com/get-docker/"
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    echo "Visit: https://docs.docker.com/compose/install/"
    exit 1
fi

echo "✅ Docker and Docker Compose are installed"
echo ""

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "📝 Creating .env file from template..."
    cp .env.example .env
    echo "⚠️  IMPORTANT: Please edit .env file with your actual credentials"
    echo ""
    echo "Required credentials:"
    echo "  - N8N_BASIC_AUTH_PASSWORD"
    echo "  - DB_POSTGRESDB_PASSWORD"
    echo "  - ELEVENLABS_API_KEY"
    echo "  - ELEVENLABS_VOICE_ID"
    echo "  - TWILIO_ACCOUNT_SID"
    echo "  - TWILIO_AUTH_TOKEN"
    echo "  - TWILIO_PHONE_NUMBER"
    echo "  - TEXTINGBIZ_API_KEY"
    echo "  - TEXTINGBIZ_API_URL"
    echo ""
    read -p "Press Enter after you've configured .env file..."
else
    echo "✅ .env file exists"
fi

# Validate required environment variables
echo "🔍 Validating environment configuration..."
source .env

MISSING_VARS=()

if [ -z "$N8N_BASIC_AUTH_PASSWORD" ] || [ "$N8N_BASIC_AUTH_PASSWORD" = "change_this_secure_password" ]; then
    MISSING_VARS+=("N8N_BASIC_AUTH_PASSWORD")
fi

if [ -z "$DB_POSTGRESDB_PASSWORD" ] || [ "$DB_POSTGRESDB_PASSWORD" = "change_this_db_password" ]; then
    MISSING_VARS+=("DB_POSTGRESDB_PASSWORD")
fi

if [ -z "$ELEVENLABS_API_KEY" ] || [ "$ELEVENLABS_API_KEY" = "your_elevenlabs_api_key_here" ]; then
    MISSING_VARS+=("ELEVENLABS_API_KEY")
fi

if [ -z "$TWILIO_ACCOUNT_SID" ] || [ "$TWILIO_ACCOUNT_SID" = "your_twilio_account_sid_here" ]; then
    MISSING_VARS+=("TWILIO_ACCOUNT_SID")
fi

if [ ${#MISSING_VARS[@]} -gt 0 ]; then
    echo "⚠️  The following environment variables need to be configured:"
    for var in "${MISSING_VARS[@]}"; do
        echo "   - $var"
    done
    echo ""
    echo "Please edit .env file and run this script again."
    exit 1
fi

echo "✅ Environment configuration is valid"
echo ""

# Create necessary directories
echo "📁 Creating directories..."
mkdir -p n8n/workflows
mkdir -p n8n/credentials
mkdir -p deployment/nginx/ssl
mkdir -p logs
mkdir -p backups
echo "✅ Directories created"
echo ""

# Generate self-signed SSL certificate for development (if not exists)
if [ ! -f "deployment/nginx/ssl/cert.pem" ]; then
    echo "🔐 Generating self-signed SSL certificate for development..."
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout deployment/nginx/ssl/key.pem \
        -out deployment/nginx/ssl/cert.pem \
        -subj "/C=US/ST=State/L=City/O=Dakota/CN=localhost" \
        2>/dev/null
    echo "✅ SSL certificate generated"
    echo "⚠️  Note: This is a self-signed certificate for development only."
    echo "   For production, use Let's Encrypt or a commercial certificate."
else
    echo "✅ SSL certificate already exists"
fi
echo ""

# Initialize database schema script
echo "📝 Creating database initialization script..."
cat > scripts/init-db.sql <<'EOF'
-- Create tables for Dakota Phone Automation System

-- Call logs table
CREATE TABLE IF NOT EXISTS call_logs (
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

CREATE INDEX idx_call_logs_phone ON call_logs(phone_number);
CREATE INDEX idx_call_logs_timestamp ON call_logs(timestamp);

-- Incoming calls table
CREATE TABLE IF NOT EXISTS incoming_calls (
    id SERIAL PRIMARY KEY,
    call_sid VARCHAR(255) UNIQUE NOT NULL,
    caller_phone VARCHAR(50) NOT NULL,
    caller_name VARCHAR(255),
    is_known BOOLEAN DEFAULT FALSE,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_incoming_calls_phone ON incoming_calls(caller_phone);
CREATE INDEX idx_incoming_calls_timestamp ON incoming_calls(timestamp);

-- SMS messages table
CREATE TABLE IF NOT EXISTS sms_messages (
    id SERIAL PRIMARY KEY,
    message_sid VARCHAR(255) UNIQUE NOT NULL,
    from_phone VARCHAR(50) NOT NULL,
    to_phone VARCHAR(50) NOT NULL,
    message_body TEXT,
    direction VARCHAR(20) CHECK (direction IN ('inbound', 'outbound')),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_sms_from_phone ON sms_messages(from_phone);
CREATE INDEX idx_sms_to_phone ON sms_messages(to_phone);
CREATE INDEX idx_sms_timestamp ON sms_messages(timestamp);

-- Contacts table
CREATE TABLE IF NOT EXISTS contacts (
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

CREATE INDEX idx_contacts_phone ON contacts(phone_number);

-- Insert sample contact for testing
INSERT INTO contacts (phone_number, name, email, sms_opt_in, call_opt_in, notes)
VALUES ('+1234567890', 'Test User', 'test@example.com', TRUE, TRUE, 'Sample contact for testing')
ON CONFLICT (phone_number) DO NOTHING;

-- Create view for call analytics
CREATE OR REPLACE VIEW call_analytics AS
SELECT 
    DATE(timestamp) as call_date,
    COUNT(*) as total_calls,
    COUNT(CASE WHEN success = TRUE THEN 1 END) as successful_calls,
    COUNT(CASE WHEN success = FALSE THEN 1 END) as failed_calls,
    AVG(duration) as avg_duration
FROM call_logs
GROUP BY DATE(timestamp)
ORDER BY call_date DESC;

-- Create view for SMS analytics
CREATE OR REPLACE VIEW sms_analytics AS
SELECT 
    DATE(timestamp) as message_date,
    COUNT(*) as total_messages,
    COUNT(CASE WHEN direction = 'inbound' THEN 1 END) as inbound_messages,
    COUNT(CASE WHEN direction = 'outbound' THEN 1 END) as outbound_messages
FROM sms_messages
GROUP BY DATE(timestamp)
ORDER BY message_date DESC;
EOF

echo "✅ Database initialization script created"
echo ""

# Pull Docker images
echo "🐳 Pulling Docker images..."
docker-compose pull

echo ""
echo "🚀 Starting services..."
docker-compose up -d

echo ""
echo "⏳ Waiting for services to be ready..."
sleep 10

# Check if services are running
if docker-compose ps | grep -q "Up"; then
    echo "✅ Services are running"
else
    echo "❌ Some services failed to start. Check logs with: docker-compose logs"
    exit 1
fi

# Initialize database
echo ""
echo "🗄️  Initializing database..."
docker-compose exec -T postgres psql -U $DB_POSTGRESDB_USER -d $DB_POSTGRESDB_DATABASE < scripts/init-db.sql || echo "⚠️  Database may already be initialized"

echo ""
echo "================================================"
echo "✅ Setup Complete!"
echo "================================================"
echo ""
echo "Services are running:"
echo "  - n8n UI: http://localhost:5678"
echo "  - Username: ${N8N_BASIC_AUTH_USER}"
echo "  - Password: (check your .env file)"
echo ""
echo "Next steps:"
echo "  1. Open http://localhost:5678 in your browser"
echo "  2. Log in with your credentials"
echo "  3. Import workflows from n8n/workflows/ directory"
echo "  4. Configure credentials in n8n (see n8n/credentials/README.md)"
echo "  5. Test your workflows"
echo ""
echo "Useful commands:"
echo "  - View logs: docker-compose logs -f"
echo "  - Stop services: docker-compose stop"
echo "  - Restart services: docker-compose restart"
echo "  - Backup: ./scripts/backup.sh"
echo ""
echo "================================================"
