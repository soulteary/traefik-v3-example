# Traefik v3.x Quick Start Example

[English](README.md) | [中文](README.zh.md)

![Traefik v3.x Quick Start Example](.github/assets/banner.jpg)

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
├── scripts/                   # Utility scripts directory
│   └── prepare-network.sh    # Docker network creation script
├── traefik/                   # Traefik service configurations
│   ├── base/                 # Base configuration (requires environment variables)
│   ├── acme/                 # ACME automatic certificate configuration
│   └── local-certs/          # Local certificate configuration
├── traefik-make-local-certs/  # Certificate generation tool
├── traefik-app-examples/     # Application integration examples
│   ├── flare/                # Flare service integration example
│   ├── stargate/             # Stargate Forward Auth service example
│   └── owlmail/              # OwlMail email testing service example
├── README.md                  # This document (English)
└── README.zh.md               # This document (Chinese)
```

## Quick Start

### Prerequisites

- Docker 20.10+
- Docker Compose 2.0+
- Basic Linux/Unix command line knowledge

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

1. **Generate Self-Signed Certificates**:
   - Refer to [Certificate Generation Tool Documentation](traefik-make-local-certs/README.md)

2. **Start Traefik**:
   - Refer to [Local Certificate Configuration Documentation](traefik/local-certs/README.md)

#### Method 2: Use ACME Automatic Certificate (Suitable for Production)

1. **Configure ACME**:
   - Alibaba Cloud DNS: Refer to [ACME Alibaba Cloud Documentation](traefik/acme-aliyun/README.md)
   - Cloudflare DNS: Refer to [ACME Cloudflare Documentation](traefik/acme-cloudflare/README.md)

2. **Start Traefik**:
   - Alibaba Cloud DNS: Refer to [ACME Alibaba Cloud Documentation](traefik/acme-aliyun/README.md)
   - Cloudflare DNS: Refer to [ACME Cloudflare Documentation](traefik/acme-cloudflare/README.md)

#### Method 3: Use Base Configuration (Requires Complete Environment Variables)

- Refer to [Base Configuration Documentation](traefik/base/README.md)

### Step 3: Access Dashboard

After successful startup, access the Traefik Dashboard:

- HTTPS: `https://traefik.example.com/dashboard/`
- API: `https://traefik.example.com/api/`

> Note: Please replace `traefik.example.com` with your actual configured domain name and ensure DNS resolution is correct.

## Detailed Documentation

### Traefik Configuration

- **[Base Configuration](traefik/base/README.md)**: Requires complete environment variable configuration, supports both ACME and local certificates
- **[ACME Certificate Configuration (Alibaba Cloud DNS)](traefik/acme-aliyun/README.md)**: Uses Let's Encrypt automatic certificate issuance via Alibaba Cloud DNS
- **[ACME Certificate Configuration (Cloudflare DNS)](traefik/acme-cloudflare/README.md)**: Uses Let's Encrypt automatic certificate issuance via Cloudflare DNS
- **[Local Certificate Configuration](traefik/local-certs/README.md)**: Uses local self-signed certificates, suitable for testing environments

### Tools and Examples

- **[Certificate Generation Tool](traefik-make-local-certs/README.md)**: Uses certs-maker container to generate self-signed certificates
- **[Flare Service Example](traefik-app-examples/flare/README.md)**: Complete example of Flare service integration with Traefik
- **[Stargate Forward Auth Example](traefik-app-examples/stargate/README.md)**: Stargate authentication service integration example, includes protected service demonstration
- **[OwlMail Email Testing Service Example](traefik-app-examples/owlmail/README.md)**: OwlMail email testing service integration example, supports SMTP and Web interface

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
