FROM n8nio/n8n:latest

# Switch to node user BEFORE copying files
USER node

WORKDIR /home/node

# Ensure .n8n directory exists with correct permissions
RUN mkdir -p /home/node/.n8n/workflows

# Copy workflows (will be owned by node user)
COPY --chown=node:node n8n/workflows /home/node/.n8n/workflows

EXPOSE 5678

HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:5678/healthz || exit 1

CMD ["n8n"]
