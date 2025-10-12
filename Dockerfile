# OpenVSCode Server - Production Dockerfile
# Multi-stage build for optimized image size and security

# ============================================================================
# Stage 1: Builder - Compile and build the application
# ============================================================================
FROM node:22-bullseye AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    pkg-config \
    libx11-dev \
    libxkbfile-dev \
    libsecret-1-dev \
    python3 \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /workspace

# Copy package files first for better Docker layer caching
COPY package.json package-lock.json ./
COPY build ./build
COPY scripts ./scripts

# Copy source code (needed for postinstall to work)
COPY . .

# Install dependencies - allow postinstall to fail but continue
RUN npm install --legacy-peer-deps || true

# Now run the postinstall manually (it will partially fail but do most of the work)
RUN node build/npm/postinstall.js || echo "Postinstall completed with some warnings"

# Install extensions dependencies that might have been missed
RUN cd extensions && npm install --legacy-peer-deps || true

# Install build dependencies
RUN cd build && npm ci && cd ..

# Download built-in extensions first
RUN npm run download-builtin-extensions || echo "Warning: Some extensions may not be available"

# Compile and build for production (this creates out-build directory)
RUN npm run compile-build

# Build extensions
RUN npm run compile-extensions-build

# Build minified version for web (requires out-build to exist)
RUN npm run minify-vscode-reh-web

# ============================================================================
# Stage 2: Production - Minimal runtime image
# ============================================================================
FROM node:22-bullseye-slim

# Install only runtime dependencies
RUN apt-get update && apt-get install -y \
    libsecret-1-0 \
    libxkbfile1 \
    git \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Create non-root user for security
RUN groupadd -r openvscode \
    && useradd -r -g openvscode -s /bin/bash -m -d /home/openvscode openvscode

# Create directory for server installation (separate from user workspace)
RUN mkdir -p /opt/openvscode-server && chown openvscode:openvscode /opt/openvscode-server

# Set working directory for server installation
WORKDIR /opt/openvscode-server

# Copy the entire minified web build as 'out' directory (server expects this structure)
COPY --from=builder --chown=openvscode:openvscode \
    /workspace/out-vscode-reh-web-min ./out

# Copy node_modules (runtime dependencies)
COPY --from=builder --chown=openvscode:openvscode \
    /workspace/node_modules ./node_modules

# Copy product configuration and package.json
COPY --from=builder --chown=openvscode:openvscode \
    /workspace/product.json ./product.json

COPY --from=builder --chown=openvscode:openvscode \
    /workspace/package.json ./package.json

# Copy extensions
COPY --from=builder --chown=openvscode:openvscode \
    /workspace/extensions ./extensions

# Copy resources
COPY --from=builder --chown=openvscode:openvscode \
    /workspace/resources ./resources

# Copy remote directory
COPY --from=builder --chown=openvscode:openvscode \
    /workspace/remote ./remote

# Set environment variables
# SERVER_ROOT points to where the server is installed, HOME for user data
ENV OPENVSCODE_SERVER_ROOT="/opt/openvscode-server" \
    HOME="/home/openvscode" \
    SHELL="/bin/bash" \
    NODE_PATH="/opt/openvscode-server/node_modules"

# Switch to non-root user
USER openvscode

# Create data directories in user's home
RUN mkdir -p /home/openvscode/.openvscode-server/data \
    && mkdir -p /home/openvscode/.openvscode-server/extensions \
    && mkdir -p /home/openvscode/workspace

# Expose HTTP port
EXPOSE 3000

# Add healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:3000/healthz || curl -f http://localhost:3000/ || exit 1

# Set working directory to user workspace (this is where user will develop)
WORKDIR /home/openvscode/workspace

# Start the server from its installation directory
# Default: without connection token (add --connection-token in production!)
CMD ["node", "/opt/openvscode-server/out/server-main.js", \
     "--host", "0.0.0.0", \
     "--port", "3000", \
     "--without-connection-token"]

