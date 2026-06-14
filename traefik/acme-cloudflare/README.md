# Traefik ACME Certificate Configuration (Cloudflare DNS)

[English](README.md) | [中文](README.zh.md)

This is a production-ready Traefik configuration that automatically issues and renews SSL certificates from Let's Encrypt through the **Cloudflare DNS (cloudflare)** DNS Challenge.

The design goal is simple: bringing a new service online should not require touching the Traefik configuration. Traefik only handles the entry point (service discovery, routing, TLS), while each business service declares its own domain, routing rules, and certificate requirements via Docker labels.

> Reference article: [Traefik on Cloudflare: Automatic Certificates and Service Onboarding](https://soulteary.com/tags/traefik.html)

## Features

- ✅ **Automatic Certificate Issuance**: Request Let's Encrypt certificates via Cloudflare DNS Challenge
- ✅ **Automatic Renewal**: Certificates are renewed automatically before expiration, no manual work required
- ✅ **Wildcard Certificates**: DNS Challenge supports `*.example.com` wildcard domains
- ✅ **Multiple Domains**: Supports multiple primary domains and subdomains
- ✅ **HTTP/3 Support**: HTTP/3 (QUIC) is enabled
- ✅ **Dashboard**: Built-in Traefik Dashboard
- ✅ **Decoupled Entry and Business**: New services onboard automatically, no Traefik config changes needed

## Why DNS Challenge + Cloudflare API Token

- **DNS Challenge supports wildcard certificates**: After issuing `*.yourdomain.ltd`, every subdomain such as `api.yourdomain.ltd`, `grafana.yourdomain.ltd`, `harbor.yourdomain.ltd` is served over HTTPS without re-issuing. It does not depend on a public port 80 and can be used for internal services.
- **Least-privilege API Token**: Automatic issuance needs permission to modify DNS records. Instead of using the Global API Key, create a dedicated API Token scoped to a single zone with only `Zone:Read` and `DNS:Edit` permissions. Even if the token leaks, the blast radius is limited to the authorized domain.

## Prerequisites

- Docker 20.10+ and Docker Compose 2.0+
- A Traefik external Docker network (`docker network create traefik`)
- The domain hosted on Cloudflare and resolved to the server, with ports 80 and 443 open in the security group
- A Cloudflare API Token with DNS edit permissions

## Step 1: Prepare the Cloudflare API Token

Open the Cloudflare dashboard and create a least-privilege API Token for Traefik:

1. Go to **My Profile → API Tokens → Create Token**
2. Choose **Create Custom Token** and configure permissions:
   - **Zone → Zone → Read**
   - **Zone → DNS → Edit**
3. Under **Zone Resources**, scope it to the target zone (avoid All zones)
4. Create the token and save it (shown only once)

Compared with the Global API Key, a custom API Token precisely limits permissions and scope. Even if it leaks, only the DNS records of the specified domain are affected.

## Step 2: Create the Docker Network

```bash
docker network create traefik
```

Any business service that wants to be exposed through Traefik only needs to join this network — no extra ports need to be published.

## Step 3: Configure Environment Variables

Configure the following variables in `.env`:

```bash
# Service configuration
SERVICE_NAME=traefik
DOCKER_IMAGE=ghcr.io/traefik/traefik:v3.7.5
SERVICE_HTTP_PORT=80
SERVICE_HTTPS_PORT=443
SERVICE_DOMAIN=traefik.example.com

# DNS configuration (for ACME certificates)
DNS_MAIN=example.com
DNS_LIST=*.example.com

# ACME configuration
ACME_EMAIL=your-email@example.com
ACME_PROVIDER=cloudflare

# Cloudflare DNS API
CF_DNS_API_TOKEN=your-cloudflare-api-token

# Optional: timezone
TZ=Asia/Shanghai
```

Key variables:

- `ACME_EMAIL`: Email for Let's Encrypt notifications
- `ACME_PROVIDER`: DNS provider, `cloudflare` for Cloudflare
- `CF_DNS_API_TOKEN`: The Cloudflare API Token created in Step 1
- `DNS_MAIN` / `DNS_LIST`: The primary domain and the wildcard (SANs) for the certificate

> Tip: If you use the legacy Cloudflare Global API Key, use `CF_API_EMAIL` + `CF_API_KEY` instead. The API Token (`CF_DNS_API_TOKEN`) is recommended for tighter permission control.

## Step 4: Start the Service

```bash
docker compose up -d
```

## Step 5: Check Certificate Status

```bash
# View Traefik logs
docker logs -f traefik

# Inspect container health
docker inspect traefik --format='{{json .State.Health}}'

# View the certificate file
ls -la ./ssl/acme.json
```

Once running, visit `https://traefik.example.com` to reach the Dashboard over HTTPS.

## Supported DNS Providers

This configuration uses Cloudflare (`cloudflare`) by default. Traefik supports many other providers:

- **Cloudflare** (`cloudflare`): requires `CF_DNS_API_TOKEN`
- **Aliyun** (`alidns`): requires `ALICLOUD_ACCESS_KEY` and `ALICLOUD_SECRET_KEY`
- **Tencent Cloud** (`tencentcloud`): requires `TENCENTCLOUD_SECRET_ID` and `TENCENTCLOUD_SECRET_KEY`
- **AWS Route53** (`route53`): requires AWS access keys
- See the [Traefik ACME documentation](https://doc.traefik.io/traefik/https/acme/#dnschallenge) for more

To switch providers, change `ACME_PROVIDER`, set the corresponding credential variables, and restart the service.

## Configuration Guide

### ACME Certificate Resolver

The resolver is named `cloudflare` and uses the DNS Challenge:

```yaml
- "--certificatesresolvers.cloudflare.acme.email=${ACME_EMAIL}"
- "--certificatesresolvers.cloudflare.acme.storage=/data/ssl/acme.json"
- "--certificatesresolvers.cloudflare.acme.dnsChallenge.resolvers=1.1.1.1:53,8.8.8.8:53"
- "--certificatesresolvers.cloudflare.acme.dnsChallenge.provider=${ACME_PROVIDER}"
- "--certificatesresolvers.cloudflare.acme.dnsChallenge.propagation.delayBeforeChecks=30"
```

`delayBeforeChecks` waits for DNS propagation before validation; the public `resolvers` (Cloudflare's `1.1.1.1` by default) are used to verify the TXT record.

### Certificate Storage

Certificate data is stored in `./ssl/acme.json` (mounted to `/data/ssl/acme.json` inside the container). It contains the issued certificates, private keys, and ACME account information.

**Important**: Keep `acme.json` safe, back it up regularly, and set its permissions to `600`.

### TLS Options

`config/tls.toml` is loaded via the file provider and pins minimum TLS version and cipher suites:

```toml
[tls.options.default]
minVersion = "VersionTLS12"
```

### Dashboard Domain

The Dashboard certificate domains come from `DNS_MAIN` and `DNS_LIST`:

```yaml
- "traefik.http.routers.traefik-dashboard-secure.tls.certresolver=cloudflare"
- "traefik.http.routers.traefik-dashboard-secure.tls.domains[0].main=${DNS_MAIN}"
- "traefik.http.routers.traefik-dashboard-secure.tls.domains[0].sans=${DNS_LIST}"
```

## Onboarding a Business Service

A business service declares its own domain and certificate. It does not require any change to the Traefik configuration — just join the `traefik` network and add labels:

```yaml
services:
  app:
    image: ghcr.io/traefik/whoami
    restart: unless-stopped
    expose:
      - 80
    labels:
      - "traefik.enable=true"
      - "traefik.docker.network=traefik"

      # Router
      - "traefik.http.routers.whoami.rule=Host(`whoami.yourdomain.ltd`)"
      - "traefik.http.routers.whoami.entrypoints=https"
      - "traefik.http.routers.whoami.tls=true"
      - "traefik.http.routers.whoami.tls.certresolver=cloudflare"

      # Wildcard certificate
      - "traefik.http.routers.whoami.tls.domains[0].main=yourdomain.ltd"
      - "traefik.http.routers.whoami.tls.domains[0].sans=*.yourdomain.ltd"

      - "traefik.http.services.whoami.loadbalancer.server.port=80"
    networks:
      - traefik

networks:
  traefik:
    external: true
```

Run `docker compose up -d`, then visit `https://whoami.yourdomain.ltd` to see the service served with a valid certificate.

## FAQ

### Certificate issuance failed, what should I check?

1. **API Token**: confirm `CF_DNS_API_TOKEN` is correct and has `Zone:Read` and `DNS:Edit` on the target zone.
2. **Domain ownership**: confirm the domain is managed by Cloudflare DNS and the token's Zone Resources cover it.
3. **Proxy status**: the DNS Challenge only edits TXT records and is unaffected by orange/grey cloud, but make sure other records point to the correct origin.
4. **Logs**: `docker logs -f traefik` and look for ACME-related errors.
5. **Network**: confirm the server can reach the Cloudflare API (`api.cloudflare.com`) and the public DNS resolvers.

### How long does issuance take?

- First issuance usually takes 1–3 minutes (DNS propagation included; Cloudflare is usually fast).
- Renewal happens automatically in the background.
- On failure, Traefik retries periodically.

### How do I view the issued certificates?

```bash
# View acme.json (requires jq)
cat ./ssl/acme.json | jq

# Or via the Traefik API
curl https://traefik.example.com/api/http/routers
```

### Can I use the Let's Encrypt staging environment?

Yes, add the CA server to the resolver:

```yaml
- "--certificatesresolvers.cloudflare.acme.caserver=https://acme-staging-v02.api.letsencrypt.org/directory"
```

**Note**: Staging certificates are not trusted by browsers; use them for testing only.

## Related Resources

- [Traefik ACME Documentation](https://doc.traefik.io/traefik/https/acme/)
- [Let's Encrypt Official Documentation](https://letsencrypt.org/)
- [Cloudflare API Token Documentation](https://developers.cloudflare.com/api/tokens/)
- [Cloudflare Create API Token Guide](https://developers.cloudflare.com/fundamentals/api/get-started/create-token/)
