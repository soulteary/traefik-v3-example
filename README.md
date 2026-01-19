# Traefik v3.x Quick Start Example

[English](README.md) | [中文](README.zh.md)

This project demonstrates how to quickly get started with Traefik v3.x, including dynamic service integration and certificate configuration.

If you find this example helpful, please give it a star ✨. If you want to receive updates about this project, you can click watch 👀 and choose your preferred notification mode.

## Features

- ✅ **Dynamic Service Integration**: Automatic service discovery and configuration based on Docker labels
- ✅ **Multiple Certificate Configurations**: Support for both ACME automatic certificate issuance and local certificates
- ✅ **HTTP/3 Support**: Enable HTTP/3 (QUIC) protocol support
- ✅ **Dashboard Interface**: Built-in Traefik Dashboard visualization interface
- ✅ **HTTPS Redirect**: Automatically redirect HTTP requests to HTTPS
- ✅ **GZIP Compression**: Automatically enable response content compression
- ✅ **Health Checks**: Built-in health check mechanism
- ✅ **Production Ready**: Anonymous data collection and version checking disabled, suitable for production environments

## Project Structure

```
traefik-v3-example/
├── config/                    # Traefik configuration directory
│   ├── certs.toml            # Certificate configuration (local certificate paths)
│   └── tls.toml              # TLS options configuration (cipher suites, etc.)
├── scripts/                   # Utility scripts directory
│   └── prepare-network.sh    # Docker network creation script
├── ssl/                       # Certificate storage directory
│   ├── acme.json             # ACME certificate storage file (ACME mode)
│   └── example.com.conf      # Certificate generation configuration example
├── docker-compose.yml         # Base configuration (requires environment variables)
├── docker-compose.acme.yml    # ACME automatic certificate configuration
├── docker-compose.local-certs.yml  # Local certificate configuration
├── docker-compose.flare.yml   # Flare service integration example
├── docker-compose.stargate.yml # Stargate Forward Auth service example
├── docker-compose.owlmail.yml  # OwlMail email testing service example
├── docker-compose.make-cert.yml    # Certificate generation tool
├── README.md                  # This document (English)
└── README.zh.md               # This document (Chinese)
```

## Quick Start

### Prerequisites

- Docker 20.10+
- Docker Compose 2.0+
- Basic Linux/Unix command line knowledge

### Environment Variables Configuration

Before using `docker-compose.yml`, you need to configure the following environment variables. You can create a `.env` file or export environment variables directly:

```bash
# Service configuration
SERVICE_NAME=traefik
DOCKER_IMAGE=traefik:v3.0
SERVICE_HTTP_PORT=80
SERVICE_HTTPS_PORT=443
SERVICE_DOMAIN=traefik.example.com

# DNS configuration (for ACME certificates)
DNS_MAIN=example.com
DNS_LIST=*.example.com

# ACME configuration (if using ACME mode)
ACME_EMAIL=your-email@example.com
ACME_PROVIDER=cloudflare
CF_DNS_API_TOKEN=your-cloudflare-api-token
```

### Step 1: Prepare Docker Network

Traefik requires a dedicated Docker network:

```bash
./scripts/prepare-network.sh
```

Or create it manually:

```bash
docker network create traefik
```

### Step 2: Choose Startup Method

Choose different configuration methods based on your needs:

#### Method 1: Use Local Certificates (Suitable for Testing)

1. Generate self-signed certificates:

```bash
docker compose -f docker-compose.make-cert.yml up
docker compose -f docker-compose.make-cert.yml down --remove-orphans
```

> Tip: To customize the domain name, you can modify the `CERT_DNS` environment variable in `docker-compose.make-cert.yml`, for example: `CERT_DNS=yourdomain.com,*.yourdomain.com`

The generated certificates will be saved in the `ssl/` directory.

2. Start Traefik:

```bash
docker-compose -f docker-compose.local-certs.yml up -d
```

#### Method 2: Use ACME Automatic Certificate (Suitable for Production)

1. Configure environment variables (especially `ACME_EMAIL` and `CF_DNS_API_TOKEN`)
2. Start Traefik:

```bash
docker-compose -f docker-compose.acme.yml up -d
```

#### Method 3: Use Base Configuration (Requires Complete Environment Variables)

```bash
docker-compose up -d
```

### Step 3: Access Dashboard

After successful startup, access the Traefik Dashboard:

- HTTPS: `https://traefik.example.com/dashboard/`
- API: `https://traefik.example.com/api/`

> Note: Please replace `traefik.example.com` with your actual configured domain name and ensure DNS resolution is correct.

## Configuration Guide

### Docker Compose Files Description

| File | Purpose | Description |
|------|---------|-------------|
| `docker-compose.yml` | Base configuration | Requires complete environment variable configuration, supports both ACME and local certificates |
| `docker-compose.acme.yml` | ACME certificate configuration | Uses Let's Encrypt automatic certificate issuance (requires DNS API Token) |
| `docker-compose.local-certs.yml` | Local certificate configuration | Uses local self-signed certificates, suitable for testing environments |
| `docker-compose.flare.yml` | Service example | Complete example of Flare service integration with Traefik |
| `docker-compose.stargate.yml` | Forward Auth example | Stargate authentication service integration example, includes protected service demonstration |
| `docker-compose.owlmail.yml` | Email testing service example | OwlMail email testing service integration example, supports SMTP and Web interface |
| `docker-compose.make-cert.yml` | Certificate generation tool | Uses certs-maker container to generate self-signed certificates |

### Configuration Files Description

#### `config/certs.toml`

Configure local certificate paths. Traefik will automatically load certificates from this directory:

```toml
[tls.stores.default.defaultCertificate]
certFile = "/data/ssl/example.com.pem.crt"
keyFile = "/data/ssl/example.com.pem.key"

[[tls.certificates]]
certFile = "/data/ssl/example.com.pem.crt"
keyFile = "/data/ssl/example.com.pem.key"
```

#### `config/tls.toml`

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

#### `docker-compose.make-cert.yml`

Uses certs-maker container to generate self-signed certificates. You can customize the domain name by modifying the `CERT_DNS` environment variable:

```yaml
services:
  certs-maker:
    image: soulteary/certs-maker:v3.8.0
    environment:
      - CERT_DNS=example.com,*.example.com  # Custom domain name, supports wildcards
    volumes:
      - ./ssl:/ssl
```

The generated certificate files will be saved in the `ssl/` directory in PEM format (`.pem.crt` and `.pem.key`).

### Scripts Description

#### `scripts/prepare-network.sh`

Creates a dedicated Docker network for Traefik. If the network already exists, the script will skip creation.

## Usage Examples

### Example 1: Integrate New Service (Reference Flare Example)

Using `docker-compose.flare.yml` as an example, demonstrating how to integrate a service with Traefik:

```yaml
services:
  flare:
    image: soulteary/flare:0.5.1
    networks:
      - traefik
    labels:
      # Enable Traefik
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

Key label descriptions:

- `traefik.enable=true`: Enable Traefik service discovery
- `traefik.docker.network=traefik`: Specify Docker network
- `traefik.http.routers.*.rule`: Routing rules (based on domain, path, etc.)
- `traefik.http.routers.*.entrypoints`: Specify entry points (http/https)
- `traefik.http.routers.*.tls`: Enable TLS
- `traefik.http.services.*.loadbalancer.server.port`: Backend service port

### Example 2: Use Local Certificates

1. Generate certificates:

```bash
docker compose -f docker-compose.make-cert.yml up
docker compose -f docker-compose.make-cert.yml down --remove-orphans
```

> Tip: To customize the domain name, you can modify the `CERT_DNS` environment variable in `docker-compose.make-cert.yml`.

2. Ensure the certificate paths in `config/certs.toml` are correct
3. Start the service:

```bash
docker-compose -f docker-compose.local-certs.yml up -d
```

### Example 3: Use ACME Automatic Certificate

1. Configure Cloudflare DNS API Token (or other supported DNS providers)
2. Set environment variables:

```bash
export ACME_EMAIL=your-email@example.com
export ACME_PROVIDER=cloudflare
export CF_DNS_API_TOKEN=your-token
```

3. Start the service:

```bash
docker-compose -f docker-compose.acme.yml up -d
```

Traefik will automatically request certificates through DNS Challenge.

### Example 4: Use Stargate Forward Auth to Protect Services

Stargate is a lightweight Forward Auth service that can serve as a unified authentication entry point to protect multiple backend services.

1. Modify the configuration in `docker-compose.stargate.yml`:

```yaml
environment:
  - AUTH_HOST=auth.example.com
  - PASSWORDS=plaintext:test123|admin456
```

2. Ensure DNS resolution is correct (`auth.example.com` and `protected.example.com`)

3. Start the service:

```bash
docker-compose -f docker-compose.stargate.yml up -d
```

4. Access protected services:

- First access to `https://protected.example.com` will be redirected to the login page
- Login page: `https://auth.example.com/_login?callback=https://protected.example.com`
- Enter the configured password (e.g., `test123` or `admin456`) to complete login
- After successful login, you will be automatically redirected back to the protected service

**Key Configuration Notes:**

- Stargate service is configured with Forward Auth middleware for use by other services
- Protected services enable authentication through the `stargate-auth` middleware
- Supports cross-domain session sharing (via `COOKIE_DOMAIN` configuration)
- Supports multiple password encryption algorithms (plaintext, bcrypt, md5, sha512)

**Enable Stargate Authentication for Other Services:**

Add the `stargate-auth` middleware to the service's Traefik labels:

```yaml
labels:
  - "traefik.http.routers.your-service.middlewares=gzip,stargate-auth"
```

For more information, see: [Stargate Project](https://github.com/soulteary/stargate)

### Example 5: Use OwlMail Email Testing Service

OwlMail is an SMTP server and Web interface for development and testing environments that can capture and display all sent emails. It is fully compatible with MailDev API, providing better performance and richer features.

1. Modify the domain configuration in `docker-compose.owlmail.yml`:

```yaml
labels:
  - "traefik.http.routers.owlmail-https.rule=Host(`mail.example.com`)"
```

2. Ensure DNS resolution is correct (`mail.example.com`)

3. Start the service:

```bash
docker-compose -f docker-compose.owlmail.yml up -d
```

4. Access and use:

- **Web Interface**: `https://mail.example.com` - View all captured emails
- **SMTP Server**: `localhost:1025` - For applications to connect and send test emails

**Configure Applications to Use OwlMail SMTP:**

```bash
# Environment variable example
SMTP_HOST=localhost
SMTP_PORT=1025
SMTP_USER=  # Optional, if SMTP authentication is enabled
SMTP_PASS=  # Optional, if SMTP authentication is enabled
```

**Optional Configuration:**

- **Email Persistence**: Email data will be saved in the `./owlmail-data` directory
- **HTTP Basic Auth**: Uncomment `MAILDEV_WEB_USER` and `MAILDEV_WEB_PASS` environment variables to protect the Web interface
- **Email Forwarding**: You can configure `MAILDEV_OUTGOING_*` environment variables to forward emails to a real SMTP server

**Key Features:**

- ✅ 100% compatible with MailDev API
- ✅ Supports email persistence storage
- ✅ Supports email forwarding and auto-forwarding
- ✅ Supports SMTP authentication and TLS
- ✅ Provides RESTful API and WebSocket support
- ✅ Supports batch operations and email export

For more information, see: [OwlMail Project](https://github.com/soulteary/owlmail)

## FAQ

### Q: How to view Traefik logs?

```bash
docker logs -f traefik
```

### Q: What to do if certificate application fails?

- Check if the DNS API Token is correct
- Confirm domain DNS resolution is normal
- Check Traefik logs to troubleshoot specific errors
- Check if the firewall allows DNS queries

### Q: How to update Traefik configuration?

After modifying configuration files, Traefik will automatically reload (watch mode is enabled). If you modified Docker Compose configuration, you need to restart the service:

```bash
docker-compose restart traefik
```

### Q: How to add multiple domains?

Configure `DNS_LIST` in environment variables, separated by commas:

```bash
DNS_LIST=*.example.com,*.test.com,example.com
```

Or use array syntax in service labels:

```yaml
- "traefik.http.routers.service.tls.domains[0].main=example.com"
- "traefik.http.routers.service.tls.domains[0].sans=*.example.com,test.com"
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

Or control access permissions through environment variables.

## Related Resources

### Complete Usage Guide

- [Best Practices for Traefik 3 in Docker: Quick Start](https://soulteary.com/2024/08/04/best-practices-for-traefik-3-in-docker-getting-started-quickly.html)

### Related Projects

- [Traefik](https://github.com/traefik/traefik) - Cloud-native reverse proxy and load balancer
- [certs-maker](https://github.com/soulteary/certs-maker) - Certificate generation tool
- [docker-flare](https://github.com/soulteary/docker-flare) - Flare service Docker image
- [Stargate](https://github.com/soulteary/stargate) - Lightweight Forward Auth authentication service
- [OwlMail](https://github.com/soulteary/owlmail) - Email development and testing tool, compatible with MailDev

### Official Documentation

- [Traefik Official Documentation](https://doc.traefik.io/traefik/)
- [Traefik Docker Provider](https://doc.traefik.io/traefik/providers/docker/)
- [Traefik ACME Configuration](https://doc.traefik.io/traefik/https/acme/)

## License

See the [LICENSE](LICENSE) file for details.
