# Traefik Base Configuration

[English](README.md) | [中文](README.zh.md)

This is the base configuration for Traefik, which requires complete environment variable configuration and supports both ACME and local certificates.

## Features

- ✅ **Dynamic Service Integration**: Automatic service discovery and configuration based on Docker labels
- ✅ **Multiple Certificate Configurations**: Support for both ACME automatic certificate issuance and local certificates
- ✅ **HTTP/3 Support**: Enable HTTP/3 (QUIC) protocol support
- ✅ **Dashboard Interface**: Built-in Traefik Dashboard visualization interface
- ✅ **HTTPS Redirect**: Automatically redirect HTTP requests to HTTPS
- ✅ **GZIP Compression**: Automatically enable response content compression
- ✅ **Health Checks**: Built-in health check mechanism
- ✅ **Production Ready**: Anonymous data collection and version checking disabled, suitable for production environments

## Environment Variables Configuration

Before using this configuration, you need to configure the following environment variables in `base/.env`:

```bash
# Service configuration
SERVICE_NAME=traefik
DOCKER_IMAGE=ghcr.io/traefik/traefik:v3.6.7
SERVICE_HTTP_PORT=80
SERVICE_HTTPS_PORT=443
SERVICE_DOMAIN=traefik.example.com
```

## Quick Start

### Prerequisites

- Docker 20.10+
- Docker Compose 2.0+
- Traefik Docker network created (run `../../scripts/prepare-network.sh`)

### Start Service

```bash
docker compose -f traefik/base/docker-compose.yml up -d
```

### Access Dashboard

After successful startup, access the Traefik Dashboard:

- HTTPS: `https://traefik.example.com/dashboard/`
- API: `https://traefik.example.com/api/`

> Note: Please replace `traefik.example.com` with your actual configured domain name and ensure DNS resolution is correct.

## Configuration Guide

### Docker Compose Configuration

This configuration includes the following main features:

1. **Port Configuration**:
   - HTTP port (default 80): For HTTP requests, automatically redirects to HTTPS
   - HTTPS port (default 443): Supports both TCP and UDP (for HTTP/3)

2. **Certificate Configuration**:
   - Supports local certificates (requires `./config/certs.toml` configuration)

3. **Middlewares**:
   - `gzip`: GZIP compression middleware
   - `redir-https`: HTTP to HTTPS redirect middleware

4. **Service Discovery**:
   - Automatic service discovery based on Docker labels
   - By default, not all containers are exposed, need to explicitly enable `traefik.enable=true`

### Configuration Files Description

#### `./config/certs.toml`

If using local certificates, you need to configure certificate paths:

```toml
[tls.stores.default.defaultCertificate]
certFile = "/data/ssl/example.com.pem.crt"
keyFile = "/data/ssl/example.com.pem.key"

[[tls.certificates]]
certFile = "/data/ssl/example.com.pem.crt"
keyFile = "/data/ssl/example.com.pem.key"
```

#### `./config/tls.toml`

Configure TLS options, including supported TLS versions and cipher suites:

```toml
[tls.options.default]
minVersion = "VersionTLS12"
sniStrict = false
cipherSuites = [
  "TLS_AES_128_GCM_SHA256",
  "TLS_AES_256_GCM_SHA384",
  # ... more cipher suites
]
```

## Using Local Certificates

If using local certificates, you need to:

1. Generate certificates (refer to `../../traefik-make-local-certs/`)
2. Configure certificate paths in `./config/certs.toml`
3. Start the service

## FAQ

### Q: How to view Traefik logs?

```bash
docker logs -f traefik
```

### Q: How to update Traefik configuration?

After modifying configuration files, Traefik will automatically reload (watch mode is enabled). If you modified Docker Compose configuration, you need to restart the service:

```bash
docker compose -f traefik/base/docker-compose.yml restart traefik
```

### Q: How to add multiple domains?

Configure `DNS_LIST` in environment variables, separated by commas:

```bash
DNS_LIST=*.example.com,*.test.com,example.com
```

### Q: HTTP/3 not working?

- Ensure both TCP and UDP ports (443) are open
- Check if the firewall allows UDP port 443
- Some network environments may not support QUIC protocol

### Q: How to disable Dashboard?

Remove or comment out the following label:

```yaml
# - "--api.dashboard=true"
```

## Related Resources

- [Traefik Official Documentation](https://doc.traefik.io/traefik/)
- [Traefik Docker Provider](https://doc.traefik.io/traefik/providers/docker/)
