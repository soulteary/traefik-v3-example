# Local Certificate Generation Tool

[English](README.md) | [中文](README.zh.md)

This is a tool using certs-maker container to generate self-signed certificates for testing environments.

## Features

- ✅ **Quick Certificate Generation**: Generate self-signed certificates with one click
- ✅ **Wildcard Domain Support**: Supports `*.example.com` wildcard domains
- ✅ **Multiple Domain Support**: Supports multiple domains and subdomains
- ✅ **PEM Format**: Generates standard PEM format certificate files

## Environment Variables Configuration

Before using this tool, you need to configure the following environment variables in `traefik-make-local-certs/.env`:

```bash
# Certificate domain configuration
CERT_DNS=example.com,*.example.com
```

## Quick Start

### Prerequisites

- Docker 20.10+
- Docker Compose 2.0+

### Step 1: Configure Domain

Configure the domain name for certificate generation in `traefik-make-local-certs/.env`:

```bash
CERT_DNS=example.com,*.example.com
```

> Tip: You can configure multiple domains, separated by commas, for example: `CERT_DNS=example.com,*.example.com,test.com,*.test.com`

### Step 2: Generate Certificates

Run the certificate generation tool:

```bash
docker compose -f traefik-make-local-certs/docker-compose.yml up
docker compose -f traefik-make-local-certs/docker-compose.yml down --remove-orphans
```

### Step 3: View Generated Certificates

Generated certificate files will be saved in `../../ssl/` directory:

```bash
ls -la ../../ssl/
```

Certificate file format:
- Certificate file: `domain.pem.crt`
- Private key file: `domain.pem.key`

For example, if `CERT_DNS=example.com,*.example.com` is configured, it will generate:
- `example.com.pem.crt`
- `example.com.pem.key`

## Configuration Guide

### Docker Compose Configuration

This tool uses `soulteary/certs-maker` container to generate certificates:

```yaml
services:
  certs-maker:
    image: soulteary/certs-maker:v3.8.0
    environment:
      - CERT_DNS=${CERT_DNS}
    volumes:
      - ../../ssl:/ssl
```

### Certificate Storage Location

Certificate files are saved in `../../ssl/` directory, sharing the same directory with Traefik configuration.

### Certificate Format

Generated certificates are in PEM format:
- Certificate file: `.pem.crt`
- Private key file: `.pem.key`

## Usage Examples

### Generate Single Domain Certificate

```bash
# Configure .env
CERT_DNS=example.com

# Generate certificate
docker compose -f traefik-make-local-certs/docker-compose.yml up
docker compose -f traefik-make-local-certs/docker-compose.yml down --remove-orphans
```

### Generate Wildcard Domain Certificate

```bash
# Configure .env
CERT_DNS=*.example.com

# Generate certificate
docker compose -f traefik-make-local-certs/docker-compose.yml up
docker compose -f traefik-make-local-certs/docker-compose.yml down --remove-orphans
```

### Generate Multiple Domain Certificate

```bash
# Configure .env
CERT_DNS=example.com,*.example.com,test.com

# Generate certificate
docker compose -f traefik-make-local-certs/docker-compose.yml up
docker compose -f traefik-make-local-certs/docker-compose.yml down --remove-orphans
```

## FAQ

### Q: Certificate generation failed?

1. **Check Domain Format**:
   - Ensure domain format is correct
   - Wildcard domains use `*.example.com` format

2. **Check Directory Permissions**:
   - Ensure `../../ssl/` directory exists
   - Ensure write permissions

3. **View Container Logs**:
   ```bash
   docker compose -f traefik-make-local-certs/docker-compose.yml logs
   ```

### Q: How to regenerate certificates?

Simply run the generation command, it will overwrite existing certificates:

```bash
docker compose -f traefik-make-local-certs/docker-compose.yml up
docker compose -f traefik-make-local-certs/docker-compose.yml down --remove-orphans
```

### Q: What is the certificate validity period?

Default generated certificates are valid for 365 days. If you need to customize the validity period, you need to modify certs-maker configuration.

### Q: Can generated certificates be used in production?

**Not recommended**. Self-signed certificates are not trusted by browsers and are only suitable for testing and development environments. Production environments should use:
- Free certificate services like Let's Encrypt (refer to `../../traefik/acme/`)
- Commercial certificates
- Certificates issued by enterprise internal CA

### Q: How to view certificate information?

Use OpenSSL to view certificate information:

```bash
# View certificate information
openssl x509 -in ../../ssl/example.com.pem.crt -text -noout

# View certificate validity period
openssl x509 -in ../../ssl/example.com.pem.crt -noout -dates
```

### Q: Where should certificate files be placed?

Certificate files are automatically saved in `../../ssl/` directory, and Traefik configuration will automatically load certificates from this directory.

## Related Resources

- [certs-maker Project](https://github.com/soulteary/certs-maker)
- [Traefik Local Certificate Configuration](../traefik/local-certs/)
- [OpenSSL Documentation](https://www.openssl.org/docs/)
