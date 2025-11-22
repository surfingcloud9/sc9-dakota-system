#!/bin/bash

# Dakota Phone Automation System - Backup Script
# Backs up n8n workflows and PostgreSQL database

set -e

BACKUP_DIR="backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="dakota-backup-$DATE"
BACKUP_PATH="$BACKUP_DIR/$BACKUP_NAME"

echo "================================================"
echo "Dakota Phone Automation - Backup"
echo "================================================"
echo ""

# Detect docker-compose command
if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE="docker-compose"
else
    DOCKER_COMPOSE="docker compose"
fi

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Create temporary backup directory
mkdir -p "$BACKUP_PATH"

echo "📦 Backing up n8n workflows..."
cp -r n8n/workflows "$BACKUP_PATH/"

echo "🗄️  Backing up PostgreSQL database..."
$DOCKER_COMPOSE exec -T postgres pg_dump -U ${DB_POSTGRESDB_USER:-n8n_user} ${DB_POSTGRESDB_DATABASE:-n8n} > "$BACKUP_PATH/database.sql" || {
    echo "❌ Database backup failed!"
    rm -rf "$BACKUP_PATH"
    exit 1
}

echo "⚙️  Backing up configuration..."
cp .env "$BACKUP_PATH/env.backup" 2>/dev/null || echo "No .env file to backup"
cp docker-compose.yml "$BACKUP_PATH/"

echo "🗜️  Compressing backup..."
cd "$BACKUP_DIR"
tar -czf "$BACKUP_NAME.tar.gz" "$BACKUP_NAME"
rm -rf "$BACKUP_NAME"
cd ..

BACKUP_SIZE=$(du -h "$BACKUP_DIR/$BACKUP_NAME.tar.gz" | cut -f1)
echo ""
echo "✅ Backup completed successfully!"
echo "   File: $BACKUP_DIR/$BACKUP_NAME.tar.gz"
echo "   Size: $BACKUP_SIZE"
echo ""

# Clean up old backups (keep last 30 days)
echo "🧹 Cleaning up old backups..."
find "$BACKUP_DIR" -name "dakota-backup-*.tar.gz" -mtime +30 -delete
REMAINING=$(ls -1 "$BACKUP_DIR"/dakota-backup-*.tar.gz 2>/dev/null | wc -l)
echo "   Backups retained: $REMAINING"
echo ""
echo "================================================"
