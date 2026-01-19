# Traefik Local Certificate Configuration

[English](README.md) | [中文](README.zh.md)

This is the Traefik configuration using local certificates, suitable for testing environments. Uses self-signed certificates or self-managed certificate files.

## Features

- ✅ **Local Certificate Support**: Uses local certificate files, no external certificate service required
- ✅ **Quick Deployment**: Suitable for testing and development environments
- ✅ **HTTP/3 Support**: Enable HTTP/3 (QUIC) protocol support
- ✅ **Dashboard Interface**: Built-in Traefik Dashboard visualization interface
- ✅ **HTTPS Redirect**: Automatically redirect HTTP requests to HTTPS

## Environment Variables Configuration

Before using this configuration, you need to configure the following environment variables in `local-certs/.env`:

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
- Local certificates generated (refer to `../../traefik-make-local-certs/`)

### Step 1: Generate Certificates

Use the certificate generation tool to generate self-signed certificates:

```bash
docker compose -f traefik-make-local-certs/docker-compose.yml up
docker compose -f traefik-make-local-certs/docker-compose.yml down --remove-orphans
```

> Tip: To customize the domain name, you can modify the `CERT_DNS` environment variable in `traefik-make-local-certs/.env`, for example: `CERT_DNS=yourdomain.com,*.yourdomain.com`

The generated certificates will be saved in `../../ssl/` directory.

### Step 2: Configure Certificate Paths

Ensure the certificate paths in `./config/certs.toml` are correct:

```toml
[tls.stores.default.defaultCertificate]
certFile = "/data/ssl/example.com.pem.crt"
keyFile = "/data/ssl/example.com.pem.key"

[[tls.certificates]]
certFile = "/data/ssl/example.com.pem.crt"
keyFile = "/data/ssl/example.com.pem.key"
```

> Note: Please replace `example.com` with your actual domain name.

### Step 3: Start Service

```bash
docker compose -f traefik/local-certs/docker-compose.yml up -d
```

### Step 4: Access Dashboard

After successful startup, access the Traefik Dashboard:

- HTTPS: `https://traefik.example.com/dashboard/`
- API: `https://traefik.example.com/api/`

> Note: Since self-signed certificates are used, browsers will display security warnings, which is normal. In testing environments, you can click "Continue" or "Proceed to site".

## Configuration Guide

### Certificate File Format

Traefik supports PEM format certificate files:

- Certificate file: `.pem.crt` or `.crt`
- Private key file: `.pem.key` or `.key`

### Certificate Configuration

Certificate configuration is in `./config/certs.toml` file:

1. **Default Certificate**: Set the default certificate to use
2. **Certificate List**: Configure all certificates to use

### Differences from ACME Configuration

Main differences from `acme/` configuration:

- **No ACME Configuration**: Does not include ACME certificate resolver configuration
- **No DNS API Token**: Does not require DNS API Token configuration
- **Uses Local Certificates**: Loads certificates from local file system

## Usage Examples

### Using Self-Signed Certificates

1. Generate certificates (refer to `../../traefik-make-local-certs/`)
2. Configure `./config/certs.toml`
3. Start service

### Using Your Own Certificates

If you have your own certificate files:

1. Copy certificate files to `../../ssl/` directory
2. Ensure file names are `domain.pem.crt` and `domain.pem.key`
3. Update paths in `./config/certs.toml`
4. Start service

### Configure Local Certificates for Service

In your service's Docker Compose file, no special configuration is needed, Traefik will automatically use the configured default certificate:

```yaml
labels:
  - "traefik.http.routers.your-service.tls=true"
  - "traefik.http.routers.your-service.rule=Host(`your-service.example.com`)"
```

## FAQ

### Q: Browser shows certificate insecure warning?

This is normal because self-signed certificates are used. In testing environments:

1. Click "Advanced" or "高级"
2. Click "Continue" or "继续访问"

### Q: How to generate certificates?

Refer to the certificate generation tool in `../../traefik-make-local-certs/` directory.

### Q: Where should certificate files be placed?

Certificate files should be placed in `../../ssl/` directory, which is mounted by the Traefik container.

### Q: How to update certificates?

1. Copy new certificate files to `../../ssl/` directory
2. Restart Traefik service:

```bash
docker compose -f traefik/local-certs/docker-compose.yml restart traefik
```

### Q: Can I use multiple certificates?

Yes, add multiple certificate configurations in `./config/certs.toml`:

```toml
[[tls.certificates]]
certFile = "/data/ssl/example.com.pem.crt"
keyFile = "/data/ssl/example.com.pem.key"

[[tls.certificates]]
certFile = "/data/ssl/test.com.pem.crt"
keyFile = "/data/ssl/test.com.pem.key"
```

### Q: How to switch to ACME mode?

If you need to switch to ACME automatic certificate issuance, please use `../../traefik/acme/` configuration.

## Related Resources

- [Traefik TLS Configuration Documentation](https://doc.traefik.io/traefik/https/tls/)
- [Certificate Generation Tool](../traefik-make-local-certs/)
