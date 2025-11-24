# ============================================================================
# Stage 1: Builder - Compile and build the application
# ============================================================================
FROM node:22-bullseye AS builder

ARG VERSION=dev

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
    bash \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

# Ensure shell is available
ENV SHELL=/bin/bash

# Copy package files first for better Docker layer caching
COPY package.json package-lock.json ./
COPY build ./build
COPY scripts ./scripts

# Copy source code
COPY . .

# Install dependencies without running scripts first (to avoid postinstall issues)
# Note: We use --ignore-scripts to avoid postinstall, but we'll run it manually
# We need optional dependencies for native modules like @parcel/watcher
RUN npm install --legacy-peer-deps --ignore-scripts

# Now run postinstall manually after dependencies are installed
RUN node build/npm/postinstall.js || echo "Postinstall completed with some warnings"

# Install optional dependencies that may have been skipped (like @parcel/watcher prebuilds)
RUN npm install --legacy-peer-deps --no-save --optional || echo "Optional dependencies installation completed with warnings"

# Rebuild all critical native modules to ensure they are compiled correctly
# These modules need to be compiled for the target architecture
RUN echo "Rebuilding native modules..." && \
    npm rebuild --build-from-source @vscode/spdlog node-pty 2>&1 | head -50 || \
    (echo "Warning: Some native modules could not be rebuilt, trying individually..." && \
     npm rebuild --build-from-source @vscode/spdlog || echo "spdlog rebuild failed" && \
     npm rebuild --build-from-source node-pty || echo "node-pty rebuild failed")

# Install extensions dependencies
RUN cd extensions && npm install --legacy-peer-deps || true

# Install build dependencies
RUN cd build && npm ci && cd ..

# Verify gulp is installed
RUN test -f node_modules/gulp/bin/gulp.js || (echo "ERROR: gulp not found!" && npm list gulp && exit 1)

# Download built-in extensions
RUN npm run download-builtin-extensions || echo "Warning: Some extensions may not be available"

# Compile and build for production
RUN npm run compile-build

# Build extensions
RUN npm run compile-extensions-build

# Minified web build
RUN npm run minify-vscode-reh-web

# ============================================================================
# Stage 1.5: Export tar.gz (para releases)
# ============================================================================
FROM builder AS export

ARG VERSION=dev

RUN mkdir -p /export && \
    mkdir -p /export/openvscode-custom && \
    cp -r /workspace/out-vscode-reh-web-min /export/openvscode-custom/out && \
    cp -r /workspace/node_modules /export/openvscode-custom/node_modules && \
    cp -r /workspace/extensions /export/openvscode-custom/extensions && \
    cp -r /workspace/resources /export/openvscode-custom/resources && \
    cp -r /workspace/remote /export/openvscode-custom/remote && \
    cp /workspace/product.json /export/openvscode-custom/product.json && \
    cp /workspace/package.json /export/openvscode-custom/package.json && \
    tar -czf /export/openvscode-custom-${VERSION}-linux-x64.tar.gz -C /export/openvscode-custom .

# ============================================================================
# Stage 2: Production - Minimal runtime image
# ============================================================================
FROM node:22-bullseye-slim

ARG VERSION=dev

# Install only runtime dependencies
# Note: python3 and build-essential are needed to rebuild native modules if needed
RUN apt-get update && apt-get install -y \
    libsecret-1-0 \
    libxkbfile1 \
    git \
    curl \
    ca-certificates \
    python3 \
    build-essential \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Create non-root user for security
RUN groupadd -r openvscode \
    && useradd -r -g openvscode -s /bin/bash -m -d /home/openvscode openvscode

RUN mkdir -p /opt/openvscode-server && chown openvscode:openvscode /opt/openvscode-server

WORKDIR /opt/openvscode-server

# Copy build from builder
COPY --from=builder --chown=openvscode:openvscode \
    /workspace/out-vscode-reh-web-min ./out

COPY --from=builder --chown=openvscode:openvscode \
    /workspace/node_modules ./node_modules

# Verify spdlog native module exists, if not we'll rebuild it
RUN test -f /opt/openvscode-server/node_modules/@vscode/spdlog/build/Release/spdlog.node || \
    test -f /opt/openvscode-server/node_modules/@vscode/spdlog/build/spdlog.node || \
    echo "Warning: spdlog.node not found, will attempt rebuild"

COPY --from=builder --chown=openvscode:openvscode \
    /workspace/product.json ./product.json

COPY --from=builder --chown=openvscode:openvscode \
    /workspace/package.json ./package.json

COPY --from=builder --chown=openvscode:openvscode \
    /workspace/extensions ./extensions

COPY --from=builder --chown=openvscode:openvscode \
    /workspace/resources ./resources

COPY --from=builder --chown=openvscode:openvscode \
    /workspace/remote ./remote

ENV OPENVSCODE_SERVER_ROOT="/opt/openvscode-server" \
    HOME="/home/openvscode" \
    SHELL="/bin/bash" \
    NODE_PATH="/opt/openvscode-server/node_modules"

USER openvscode

# Create all necessary directories for openvscode-server
RUN mkdir -p /home/openvscode/.openvscode-server/data \
    && mkdir -p /home/openvscode/.openvscode-server/data/logs \
    && mkdir -p /home/openvscode/.openvscode-server/extensions \
    && mkdir -p /home/openvscode/workspace

# Rebuild native modules to ensure compatibility with production image
# Switch to root temporarily to rebuild native modules
USER root
RUN cd /opt/openvscode-server && \
    echo "Rebuilding native modules for production..." && \
    npm rebuild --build-from-source @vscode/spdlog node-pty 2>&1 | head -50 || \
    (echo "Warning: Some native modules could not be rebuilt, trying individually..." && \
     npm rebuild --build-from-source @vscode/spdlog || echo "spdlog rebuild failed" && \
     npm rebuild --build-from-source node-pty || echo "node-pty rebuild failed") && \
    echo "Installing optional dependencies (prebuilds)..." && \
    npm install --legacy-peer-deps --no-save --optional 2>&1 | head -20 || echo "Optional deps install completed with warnings" && \
    echo "Verifying native modules..." && \
    (test -f node_modules/@vscode/spdlog/build/Release/spdlog.node || \
     test -f node_modules/@vscode/spdlog/build/spdlog.node || \
     echo "Warning: spdlog.node not found") && \
    (test -f node_modules/node-pty/build/Release/pty.node || \
     test -f node_modules/node-pty/build/Debug/pty.node || \
     echo "Warning: pty.node not found") && \
    (test -d node_modules/@parcel/watcher-linux-x64-glibc || \
     test -d node_modules/@parcel/watcher || \
     echo "Warning: @parcel/watcher prebuild not found")
USER openvscode

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:3000/healthz || curl -f http://localhost:3000/ || exit 1

WORKDIR /home/openvscode/workspace

CMD ["node", "/opt/openvscode-server/out/server-main.js", \
     "--host", "0.0.0.0", \
     "--port", "3000", \
     "--without-connection-token"]
