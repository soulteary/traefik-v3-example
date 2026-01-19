# Traefik ACME Certificate Configuration

[English](README.md) | [中文](README.zh.md)

This is the Traefik configuration using ACME automatic certificate issuance, suitable for production environments. Traefik will automatically request certificates from Let's Encrypt through DNS Challenge.

## Features

- ✅ **Automatic Certificate Issuance**: Automatically request Let's Encrypt certificates through DNS Challenge
- ✅ **Automatic Certificate Renewal**: Automatically renew certificates before expiration
- ✅ **Wildcard Certificate Support**: Supports `*.example.com` wildcard domains
- ✅ **Multiple Domain Support**: Supports multiple domains and subdomains
- ✅ **HTTP/3 Support**: Enable HTTP/3 (QUIC) protocol support
- ✅ **Dashboard Interface**: Built-in Traefik Dashboard visualization interface

## Environment Variables Configuration

Before using this configuration, you need to configure the following environment variables in `acme/.env`:

```bash
# Service configuration
SERVICE_NAME=traefik
DOCKER_IMAGE=ghcr.io/traefik/traefik:v3.6.7
SERVICE_HTTP_PORT=80
SERVICE_HTTPS_PORT=443
SERVICE_DOMAIN=traefik.example.com

# DNS configuration (for ACME certificates)
DNS_MAIN=example.com
DNS_LIST=*.example.com

# ACME configuration (required)
ACME_EMAIL=your-email@example.com
ACME_PROVIDER=cloudflare
CF_DNS_API_TOKEN=your-cloudflare-api-token
```

## Supported DNS Providers

Traefik supports multiple DNS providers, commonly used ones include:

- **Cloudflare** (`cloudflare`): Requires `CF_DNS_API_TOKEN`
- **Aliyun** (`alidns`): Requires `ALICLOUD_ACCESS_KEY` and `ALICLOUD_SECRET_KEY`
- **Tencent Cloud** (`tencentcloud`): Requires `TENCENTCLOUD_SECRET_ID` and `TENCENTCLOUD_SECRET_KEY`
- **AWS Route53** (`route53`): Requires AWS access keys
- For more providers, refer to [Traefik ACME Documentation](https://doc.traefik.io/traefik/https/acme/#dnschallenge)

## Quick Start

### Prerequisites

- Docker 20.10+
- Docker Compose 2.0+
- Traefik Docker network created (run `../../scripts/prepare-network.sh`)
- DNS API Token configured (e.g., Cloudflare)

### Step 1: Configure DNS API Token

#### Cloudflare Configuration Example

1. Log in to Cloudflare console
2. Go to "My Profile" > "API Tokens"
3. Create a new API Token with permissions:
   - Zone: Zone:Read
   - Zone: DNS:Edit
4. Configure the Token in environment variables:

```bash
export CF_DNS_API_TOKEN=your-cloudflare-api-token
```

### Step 2: Configure Environment Variables

Configure all required environment variables in `acme/.env`, especially:

- `ACME_EMAIL`: Email for Let's Encrypt notifications
- `ACME_PROVIDER`: DNS provider (e.g., `cloudflare`)
- `CF_DNS_API_TOKEN`: DNS API Token (variable name may differ depending on provider)

### Step 3: Start Service

```bash
docker compose -f traefik/acme/docker-compose.yml up -d
```

### Step 4: Check Certificate Application Status

```bash
# View Traefik logs
docker logs -f traefik

# View certificate file
ls -la ../../ssl/acme.json
```

## Configuration Guide

### ACME Certificate Resolver Configuration

This configuration uses DNS Challenge to request certificates, main configurations include:

```yaml
- "--certificatesresolvers.le.acme.email=${ACME_EMAIL}"
- "--certificatesresolvers.le.acme.storage=/data/ssl/acme.json"
- "--certificatesresolvers.le.acme.dnsChallenge.resolvers=1.1.1.1:53,8.8.8.8:53"
- "--certificatesresolvers.le.acme.dnsChallenge.provider=${ACME_PROVIDER}"
- "--certificatesresolvers.le.acme.dnsChallenge.propagation.delayBeforeChecks=30"
```

### Certificate Storage

Certificate data is stored in `../../ssl/acme.json` file, which contains:

- Requested certificates
- Private keys
- ACME account information

**Important**: Please keep the `acme.json` file safe, do not leak or lose it.

### Domain Configuration

Configure certificate domains in service labels:

```yaml
- "traefik.http.routers.traefik-dashboard-secure.tls.certresolver=le"
- "traefik.http.routers.traefik-dashboard-secure.tls.domains[0].main=${DNS_MAIN}"
- "traefik.http.routers.traefik-dashboard-secure.tls.domains[0].sans=${DNS_LIST}"
```

## Usage Examples

### Configure ACME Certificate for Service

Add the following labels to your service's Docker Compose file:

```yaml
labels:
  - "traefik.http.routers.your-service.tls.certresolver=le"
  - "traefik.http.routers.your-service.tls.domains[0].main=example.com"
  - "traefik.http.routers.your-service.tls.domains[0].sans=*.example.com"
```

### Add Multiple Domains

Configure `DNS_LIST` in environment variables, separated by commas:

```bash
DNS_LIST=*.example.com,*.test.com,example.com
```

Or use array syntax in service labels:

```yaml
- "traefik.http.routers.service.tls.domains[0].main=example.com"
- "traefik.http.routers.service.tls.domains[0].sans=*.example.com,test.com"
```

## FAQ

### Q: What to do if certificate application fails?

1. **Check DNS API Token**:
   - Confirm the Token is correct
   - Confirm the Token has sufficient permissions

2. **Check Domain DNS Resolution**:
   - Confirm domain DNS resolution is normal
   - Confirm DNS provider configuration is correct

3. **View Traefik Logs**:
   ```bash
   docker logs -f traefik
   ```
   Look for ACME-related error messages

4. **Check Firewall**:
   - Confirm firewall allows DNS queries
   - Confirm access to DNS provider's API

### Q: How long does certificate application take?

- First application usually takes 1-3 minutes
- Certificate renewal usually happens automatically in the background
- If application fails, Traefik will retry periodically

### Q: How to view requested certificates?

```bash
# View acme.json file (requires jq tool)
cat ../../ssl/acme.json | jq

# Or use Traefik API
curl https://traefik.example.com/api/http/routers
```

### Q: Where are certificates stored?

Certificates are stored in `../../ssl/acme.json` file. Please ensure:

- Regularly backup this file
- Do not delete or modify this file
- Set file permissions to 600 (read-write for owner only)

### Q: How to switch to another DNS provider?

1. Modify `ACME_PROVIDER` environment variable
2. Configure corresponding API Token environment variable (variable name may differ depending on provider)
3. Restart service

### Q: Can I use Let's Encrypt staging environment?

Yes, add to configuration:

```yaml
- "--certificatesresolvers.le.acme.caserver=https://acme-staging-v02.api.letsencrypt.org/directory"
```

**Note**: Certificates issued by staging environment are not trusted by browsers, only for testing.

## Related Resources

- [Traefik ACME Configuration Documentation](https://doc.traefik.io/traefik/https/acme/)
- [Let's Encrypt Official Documentation](https://letsencrypt.org/)
- [Cloudflare API Token Documentation](https://developers.cloudflare.com/api/tokens/)
