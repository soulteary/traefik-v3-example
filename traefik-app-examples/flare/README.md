# Flare Service Integration with Traefik Example

[English](README.md) | [中文](README.zh.md)

This is a complete example of integrating Flare service with Traefik, demonstrating how to integrate services with Traefik reverse proxy through Docker labels.

## Features

- ✅ **Automatic Service Discovery**: Automatic service discovery and configuration through Docker labels
- ✅ **HTTPS Support**: Automatically enable HTTPS and TLS
- ✅ **HTTP Redirect**: Automatically redirect HTTP requests to HTTPS
- ✅ **GZIP Compression**: Automatically enable response content compression
- ✅ **Domain Routing**: Route based on domain names

## Environment Variables Configuration

Before using this configuration, you need to configure the following environment variables in `flare/.env`:

```bash
# Service configuration
SERVICE_NAME=flare
SERVICE_PREFIX=flare
SERVICE_DOMAIN=flare.example.com
SERVICE_PORT=5005
DOCKER_IMAGE=soulteary/flare:0.5.1
```

## Quick Start

### Prerequisites

- Docker 20.10+
- Docker Compose 2.0+
- Traefik service started (refer to `../../traefik/`)
- Traefik Docker network created

### Start Service

```bash
docker compose -f traefik-app-examples/flare/docker-compose.yml up -d
```

### Access Service

After successful startup, access the Flare service:

- HTTPS: `https://flare.example.com`
- HTTP: `http://flare.example.com` (automatically redirects to HTTPS)

> Note: Please replace `flare.example.com` with your actual configured domain name and ensure DNS resolution is correct.

## Configuration Guide

### Docker Compose Configuration

This configuration demonstrates how to integrate services with Traefik through Docker labels:

```yaml
labels:
  # Enable Traefik service discovery
  - "traefik.enable=true"
  - "traefik.docker.network=traefik"
  
  # HTTP route (automatically redirects to HTTPS)
  - "traefik.http.routers.flare-http.entrypoints=http"
  - "traefik.http.routers.flare-http.middlewares=redir-https"
  - "traefik.http.routers.flare-http.rule=Host(`flare.example.com`)"
  - "traefik.http.routers.flare-http.service=noop@internal"
  
  # HTTPS route
  - "traefik.http.routers.flare-https.entrypoints=https"
  - "traefik.http.routers.flare-https.tls=true"
  - "traefik.http.routers.flare-https.middlewares=gzip"
  - "traefik.http.routers.flare-https.rule=Host(`flare.example.com`)"
  
  # Service configuration
  - "traefik.http.services.flare-backend.loadbalancer.server.scheme=http"
  - "traefik.http.services.flare-backend.loadbalancer.server.port=5005"
```

### Key Label Descriptions

- `traefik.enable=true`: Enable Traefik service discovery
- `traefik.docker.network=traefik`: Specify Docker network
- `traefik.http.routers.*.rule`: Routing rules (based on domain, path, etc.)
- `traefik.http.routers.*.entrypoints`: Specify entry points (http/https)
- `traefik.http.routers.*.tls`: Enable TLS
- `traefik.http.services.*.loadbalancer.server.port`: Backend service port

## Usage Examples

### Integrate New Service

Refer to this configuration, you can easily integrate other services with Traefik:

1. **Copy Configuration Structure**: Copy the `docker-compose.yml` file
2. **Modify Service Configuration**:
   - Modify image name
   - Modify service port
   - Modify domain name
3. **Configure Environment Variables**: Set corresponding environment variables in `.env` file
4. **Start Service**: Use `docker compose up -d` to start

### Customize Routing Rules

You can modify routing rules as needed:

```yaml
# Path-based routing
- "traefik.http.routers.service.rule=Host(`example.com`) && PathPrefix(`/api`)"

# Multiple domains
- "traefik.http.routers.service.rule=Host(`example.com`) || Host(`www.example.com`)"

# Path prefix-based
- "traefik.http.routers.service.rule=PathPrefix(`/app`)"
```

### Add Middlewares

You can add custom middlewares:

```yaml
# Add authentication middleware
- "traefik.http.routers.service.middlewares=gzip,auth"

# Add rate limiting middleware
- "traefik.http.routers.service.middlewares=gzip,ratelimit"
```

## FAQ

### Q: Service cannot be accessed?

1. **Check Service Status**:
   ```bash
   docker ps | grep flare
   ```

2. **Check Traefik Logs**:
   ```bash
   docker logs traefik
   ```

3. **Check Service Logs**:
   ```bash
   docker logs flare
   ```

4. **Confirm Network Connection**:
   - Confirm service is in `traefik` network
   - Confirm domain DNS resolution is correct

### Q: How to view Traefik routing configuration?

Access Traefik Dashboard:

```bash
https://traefik.example.com/dashboard/
```

In the Dashboard, you can view:
- All routing configurations
- Service status
- Middleware configurations

### Q: How to modify service port?

1. Modify `SERVICE_PORT` in `.env` file
2. Modify port configuration in `docker-compose.yml`
3. Restart service

### Q: How to add multiple domains?

Use `||` to connect multiple domains in routing rules:

```yaml
- "traefik.http.routers.service.rule=Host(`example.com`) || Host(`www.example.com`)"
```

### Q: How to disable HTTPS redirect?

Remove HTTP route configuration, only keep HTTPS route:

```yaml
# Remove these labels
# - "traefik.http.routers.service-http.entrypoints=http"
# - "traefik.http.routers.service-http.middlewares=redir-https"
```

## Related Resources

- [Flare Project](https://github.com/soulteary/docker-flare)
- [Traefik Docker Provider Documentation](https://doc.traefik.io/traefik/providers/docker/)
- [Traefik Routing Configuration Documentation](https://doc.traefik.io/traefik/routing/routers/)
