# Traefik ACME Certificate Configuration (Alibaba Cloud DNS)

[English](README.md) | [中文](README.zh.md)

This is a production-ready Traefik configuration that automatically issues and renews SSL certificates from Let's Encrypt through the **Alibaba Cloud DNS (alidns)** DNS Challenge.

The design goal is simple: bringing a new service online should not require touching the Traefik configuration. Traefik only handles the entry point (service discovery, routing, TLS), while each business service declares its own domain, routing rules, and certificate requirements via Docker labels.

> Reference article: [Traefik on Alibaba Cloud: Automatic Certificates and Service Onboarding](https://soulteary.com/2026/05/29/traefik-alibaba-cloud-auto-tls-and-service-routing.html)

## Features

- ✅ **Automatic Certificate Issuance**: Request Let's Encrypt certificates via Alibaba Cloud DNS Challenge
- ✅ **Automatic Renewal**: Certificates are renewed automatically before expiration, no manual work required
- ✅ **Wildcard Certificates**: DNS Challenge supports `*.example.com` wildcard domains
- ✅ **Multiple Domains**: Supports multiple primary domains and subdomains
- ✅ **HTTP/3 Support**: HTTP/3 (QUIC) is enabled
- ✅ **Dashboard**: Built-in Traefik Dashboard
- ✅ **Decoupled Entry and Business**: New services onboard automatically, no Traefik config changes needed

## Why DNS Challenge + Alibaba Cloud RAM

- **DNS Challenge supports wildcard certificates**: After issuing `*.yourdomain.ltd`, every subdomain such as `api.yourdomain.ltd`, `grafana.yourdomain.ltd`, `harbor.yourdomain.ltd` is served over HTTPS without re-issuing. It does not depend on a public port 80 and can be used for internal services.
- **Least-privilege RAM account**: Automatic issuance needs permission to modify DNS records. Instead of using the main account, create a dedicated RAM account that can only query domains and add/delete TXT records. Even if the key leaks, the blast radius stays minimal.

## Prerequisites

- Docker 20.10+ and Docker Compose 2.0+
- A Traefik external Docker network (`docker network create traefik`)
- The domain resolved to the server, with ports 80 and 443 open in the security group
- An Alibaba Cloud RAM account with DNS permissions (AccessKey ID / Secret)

## Step 1: Prepare the Alibaba Cloud RAM Account

Open the RAM console and create a dedicated account for Traefik. Disable console access and allow API access only, then save the `ACCESS KEY` and `ACCESS KEY SECRET`.

Create two policies and attach them to the account.

Policy 1 — global domain lookup (Traefik calls `DescribeDomains`, which requires `"Resource": "*"`):

```json
{
  "Version": "1",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["alidns:DescribeDomains"],
      "Resource": "*"
    }
  ]
}
```

Policy 2 — record edit for the specific domain:

```json
{
  "Version": "1",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "alidns:AddDomainRecord",
        "alidns:DeleteDomainRecord",
        "alidns:UpdateDomainRecord",
        "alidns:DescribeDomainRecords"
      ],
      "Resource": ["acs:alidns:*:*:domain/yourdomain.ltd"]
    }
  ]
}
```

Replace `yourdomain.ltd` with the domain you want Traefik to manage certificates for.

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
ACME_PROVIDER=alidns

# Alibaba Cloud DNS API
ALICLOUD_ACCESS_KEY=xxxxxxxxxxxxxxxx
ALICLOUD_SECRET_KEY=xxxxxxxxxxxxxxxx

# Optional: timezone
TZ=Asia/Shanghai
```

Key variables:

- `ACME_EMAIL`: Email for Let's Encrypt notifications
- `ACME_PROVIDER`: DNS provider, `alidns` for Alibaba Cloud
- `ALICLOUD_ACCESS_KEY` / `ALICLOUD_SECRET_KEY`: The RAM account AccessKey ID and Secret
- `DNS_MAIN` / `DNS_LIST`: The primary domain and the wildcard (SANs) for the certificate

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

This configuration uses Alibaba Cloud (`alidns`) by default. Traefik supports many other providers:

- **Aliyun** (`alidns`): requires `ALICLOUD_ACCESS_KEY` and `ALICLOUD_SECRET_KEY`
- **Cloudflare** (`cloudflare`): requires `CF_DNS_API_TOKEN`
- **Tencent Cloud** (`tencentcloud`): requires `TENCENTCLOUD_SECRET_ID` and `TENCENTCLOUD_SECRET_KEY`
- **AWS Route53** (`route53`): requires AWS access keys
- See the [Traefik ACME documentation](https://doc.traefik.io/traefik/https/acme/#dnschallenge) for more

To switch providers, change `ACME_PROVIDER`, set the corresponding credential variables, and restart the service.

## Configuration Guide

### ACME Certificate Resolver

The resolver is named `aliyun` and uses the DNS Challenge:

```yaml
- "--certificatesresolvers.aliyun.acme.email=${ACME_EMAIL}"
- "--certificatesresolvers.aliyun.acme.storage=/data/ssl/acme.json"
- "--certificatesresolvers.aliyun.acme.dnsChallenge.resolvers=1.1.1.1:53,8.8.8.8:53"
- "--certificatesresolvers.aliyun.acme.dnsChallenge.provider=${ACME_PROVIDER}"
- "--certificatesresolvers.aliyun.acme.dnsChallenge.propagation.delayBeforeChecks=30"
```

`delayBeforeChecks` waits for DNS propagation before validation; the public `resolvers` are used to verify the TXT record.

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
- "traefik.http.routers.traefik-dashboard-secure.tls.certresolver=aliyun"
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
      - "traefik.http.routers.whoami.tls.certresolver=aliyun"

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

1. **RAM credentials**: confirm `ALICLOUD_ACCESS_KEY` / `ALICLOUD_SECRET_KEY` are correct and the two policies are attached.
2. **Domain ownership**: confirm the domain is managed by Alibaba Cloud DNS and matches the policy resource.
3. **Logs**: `docker logs -f traefik` and look for ACME-related errors.
4. **Network**: confirm the server can reach the Alibaba Cloud API and the public DNS resolvers.

### How long does issuance take?

- First issuance usually takes 1–3 minutes (DNS propagation included).
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
- "--certificatesresolvers.aliyun.acme.caserver=https://acme-staging-v02.api.letsencrypt.org/directory"
```

**Note**: Staging certificates are not trusted by browsers; use them for testing only.

## Related Resources

- [Reference article (Chinese)](https://soulteary.com/2026/05/29/traefik-alibaba-cloud-auto-tls-and-service-routing.html)
- [Traefik ACME Documentation](https://doc.traefik.io/traefik/https/acme/)
- [Let's Encrypt Official Documentation](https://letsencrypt.org/)
- [Alibaba Cloud RAM Documentation](https://www.alibabacloud.com/help/en/ram/)
