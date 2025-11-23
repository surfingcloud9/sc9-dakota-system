# Use official n8n image (pinned version for reproducible builds)
FROM n8nio/n8n:1.120.4

# Set working directory
WORKDIR /home/node

# Switch to root to install wget and set permissions
USER root

# Install wget for healthcheck (Alpine version)
RUN apk add --no-cache wget

# Create .n8n directory and set proper ownership
RUN mkdir -p /home/node/.n8n/workflows && \
    chown -R node:node /home/node/.n8n

# Copy workflows and ensure proper ownership
# Use Docker's --chown so files are owned by node without extra RUN chown step.
COPY --chown=node:node n8n/workflows/ /home/node/.n8n/workflows/

# Switch back to node user for security
USER node

# Environment variables
ENV N8N_HOST=0.0.0.0
ENV N8N_PORT=5678
ENV N8N_PROTOCOL=http

# Expose port
EXPOSE 5678

# Fixed healthcheck with wget
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:5678/healthz || exit 1

# Start n8n
CMD ["n8n", "start"]
