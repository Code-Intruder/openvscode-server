# OpenVSCode Server - Docker Deployment Guide

## Quick Start

### Build the Image

```bash
docker build -t openvscode-server:latest .
```

Build time: ~20-30 minutes (depending on your machine)

### Run with Docker

**Without authentication** (development only):
```bash
docker run -it --init -p 3000:3000 \
  -v "$(pwd)/workspace:/home/openvscode/workspace:cached" \
  openvscode-server:latest
```

**With authentication** (recommended):
```bash
docker run -it --init -p 3000:3000 \
  -v "$(pwd)/workspace:/home/openvscode/workspace:cached" \
  openvscode-server:latest \
  node /home/openvscode/server/out/server-main.js \
  --host 0.0.0.0 \
  --port 3000 \
  --connection-token YOUR_SECRET_TOKEN
```

Access: `http://localhost:3000/?tkn=YOUR_SECRET_TOKEN`

### Run with Docker Compose

```bash
# Copy environment template
cp .env.example .env

# Edit .env and set your CONNECTION_TOKEN
nano .env

# Start services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

## Production Deployment

### 1. Generate Secure Token

```bash
openssl rand -hex 32
```

### 2. Configure Environment

```bash
# Create .env file
cat > .env << EOF
CONNECTION_TOKEN=$(openssl rand -hex 32)
PORT=3000
HOST=0.0.0.0
EOF
```

### 3. Deploy with HTTPS (Recommended)

Use a reverse proxy like Nginx or Caddy:

**Nginx Example** (`nginx.conf`):
```nginx
server {
    listen 80;
    server_name vscode.example.com;

    # Redirect to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name vscode.example.com;

    ssl_certificate /etc/ssl/certs/cert.pem;
    ssl_certificate_key /etc/ssl/private/key.pem;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 86400;
    }
}
```

**Caddy Example** (`Caddyfile`):
```caddy
vscode.example.com {
    reverse_proxy localhost:3000
}
```

### 4. Docker Compose Production

```yaml
version: '3.8'

services:
  openvscode:
    image: openvscode-server:latest
    restart: always
    ports:
      - "127.0.0.1:3000:3000"  # Bind to localhost only
    volumes:
      - ./workspace:/home/openvscode/workspace
      - openvscode-data:/home/openvscode/.openvscode-server
    environment:
      - CONNECTION_TOKEN=${CONNECTION_TOKEN}
    command:
      - node
      - /home/openvscode/server/out/server-main.js
      - --host
      - 0.0.0.0
      - --port
      - "3000"
      - --connection-token
      - ${CONNECTION_TOKEN}
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 4G

volumes:
  openvscode-data:
```

## Installing Extensions

### Method 1: CLI (while container is running)

```bash
docker exec -it openvscode-server \
  node /home/openvscode/server/out/server-main.js \
  --install-extension ms-python.python
```

### Method 2: From UI

Access the Extensions panel in the web interface and install from Open VSX.

### Method 3: Pre-install in Dockerfile

Modify the Dockerfile before the final `CMD`:

```dockerfile
# Install extensions as openvscode user
RUN node /home/openvscode/server/out/server-main.js \
    --install-extension ms-python.python \
    --install-extension dbaeumer.vscode-eslint
```

## Volumes and Persistence

- **`./workspace`** - Your project files
- **`openvscode-extensions`** - Installed extensions and settings (persistent)

To backup your extensions and settings:
```bash
docker run --rm -v openvscode-extensions:/data \
  -v $(pwd):/backup alpine \
  tar czf /backup/vscode-data-backup.tar.gz -C /data .
```

## Monitoring and Logs

### View logs
```bash
docker logs -f openvscode-server
```

### Check health
```bash
docker inspect --format='{{.State.Health.Status}}' openvscode-server
```

### Resource usage
```bash
docker stats openvscode-server
```

## Troubleshooting

### Container won't start
```bash
# Check logs
docker logs openvscode-server

# Check if port is in use
netstat -tuln | grep 3000
```

### Out of memory
Increase memory limits in docker-compose.yml or:
```bash
docker run --memory=4g ...
```

### Permission issues
Make sure the workspace directory has correct permissions:
```bash
chmod -R 755 workspace/
```

## Security Best Practices

1. **Always use connection tokens** in production
2. **Use HTTPS** with a reverse proxy
3. **Limit network exposure** - bind to localhost and use reverse proxy
4. **Keep image updated** - rebuild regularly for security patches
5. **Use resource limits** to prevent DoS
6. **Regular backups** of workspace and settings

## Clean Up

```bash
# Stop and remove container
docker-compose down

# Remove volumes (WARNING: deletes all data)
docker-compose down -v

# Remove image
docker rmi openvscode-server:latest
```

## Support

- OpenVSCode Server: https://github.com/gitpod-io/openvscode-server
- VS Code Issues: https://github.com/microsoft/vscode/issues

