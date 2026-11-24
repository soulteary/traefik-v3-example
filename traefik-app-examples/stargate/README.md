# Stargate Forward Auth Service Example

[English](README.md) | [中文](README.zh.md)

This is a complete example of using Stargate Forward Auth service to protect backend services. Stargate is a lightweight Forward Auth service that can serve as a unified authentication entry point to protect multiple backend services.

## Features

- ✅ **Unified Authentication Entry**: Provides unified authentication entry for multiple backend services
- ✅ **Forward Auth Middleware**: Protect services through Traefik Forward Auth middleware
- ✅ **Cross-Domain Session Sharing**: Supports cross-domain session sharing (via Cookie domain configuration)
- ✅ **Multiple Password Encryption**: Supports plaintext for development and bcrypt for production
- ✅ **Protected Service Example**: Includes complete protected service demonstration

## Environment Variables Configuration

Before using this configuration, you need to configure the following environment variables in `stargate/.env`:

```bash
# Stargate service configuration
STARGATE_SERVICE_NAME=stargate
STARGATE_PREFIX=stargate
STARGATE_DOMAIN=auth.example.com
STARGATE_PORT=8080
STARGATE_DOCKER_IMAGE=ghcr.io/soulteary/stargate:1.8.0

# Protected service configuration
PROTECTED_SERVICE_NAME=protected-service
PROTECTED_PREFIX=protected
PROTECTED_DOMAIN=protected.example.com
PROTECTED_PORT=80
PROTECTED_DOCKER_IMAGE=ghcr.io/traefik/whoami:v1.12.0

# Authentication configuration
AUTH_HOST=auth.example.com
PASSWORDS=plaintext:test123|admin456
SESSION_EXCHANGE_SECRET=
TRUSTED_PROXIES=
CALLBACK_ALLOWED_HOSTS=protected.example.com

# Optional configuration
LANGUAGE=zh
LOGIN_PAGE_TITLE=Login
LOGIN_PAGE_FOOTER_TEXT=Please enter password
USER_HEADER_NAME=X-User
# COOKIE_DOMAIN=.example.com  # For cross-domain session sharing
# DEBUG=false

# Health check and logging configuration
HEALTH_CHECK_INTERVAL=10s
HEALTH_CHECK_TIMEOUT=3s
HEALTH_CHECK_RETRIES=3
LOG_MAX_SIZE=10m
LOG_MAX_FILE=3
```

## Quick Start

### Prerequisites

- Docker 20.10+
- Docker Compose 2.0+
- Traefik service started (refer to `../../traefik/`)
- Traefik Docker network created

### Step 1: Configure Environment Variables

Configure in `stargate/.env`:

1. **Authentication Service Domain**: `AUTH_HOST` and `STARGATE_DOMAIN`
2. **Protected Service Domain**: `PROTECTED_DOMAIN`
3. **Password Configuration**: `PASSWORDS` (format: `algorithm:password1|password2|password3`)

4. **Session exchange secret**: Generate a fresh value with `openssl rand -hex 32` and save it as `SESSION_EXCHANGE_SECRET`.
5. **Trusted proxy network**: Run `docker network inspect traefik --format '{{range .IPAM.Config}}{{println .Subnet}}{{end}}'` and set `TRUSTED_PROXIES` to the actual proxy subnet.
6. **Allowed callback hosts**: Keep `CALLBACK_ALLOWED_HOSTS` aligned with `PROTECTED_DOMAIN`.

Stargate 1.8.0 listens on port 8080 in this example. It needs trusted proxy configuration to accept forwarded HTTPS metadata and return users to the application after login. Compose checks the two required values before starting. The container health check uses its bundled `wget` against `/healthz`.

### Step 2: Ensure DNS Resolution is Correct

Ensure the following domains have correct DNS resolution:
- `auth.example.com` (Stargate authentication service)
- `protected.example.com` (protected service)

### Step 3: Start Service

```bash
docker compose -f traefik-app-examples/stargate/docker-compose.yml up -d
```

### Step 4: Access Service

1. **Access Protected Service**:
   - First access to `https://protected.example.com` will be redirected to login page

2. **Login Page**:
   - Login page: `https://auth.example.com/_login?callback=https://protected.example.com`
   - Enter configured password (e.g., `test123` or `admin456`) to complete login

3. **After Successful Login**:
   - Will automatically redirect back to protected service
   - Subsequent access does not require login again (based on Cookie session)

## Configuration Guide

### Stargate Service Configuration

Stargate service is configured with Forward Auth middleware for use by other services:

```yaml
# Define Forward Auth middleware (for use by other services)
# Note: The actual configuration uses ${STARGATE_SERVICE_NAME} variable (default value is stargate)
- "traefik.http.middlewares.stargate-auth.forwardauth.address=http://${STARGATE_SERVICE_NAME}:${STARGATE_PORT}/_auth"
- "traefik.http.middlewares.stargate-auth.forwardauth.authResponseHeaders=X-User"
- "traefik.http.middlewares.stargate-auth.forwardauth.authResponseHeadersRegex=^(X-Forwarded-.*|X-Auth-.*)$"
- "traefik.http.middlewares.stargate-auth.forwardauth.trustForwardHeader=true"
```

### Protected Service Configuration

Protected services enable authentication through `stargate-auth` middleware:

```yaml
# HTTPS route - Use Stargate authentication middleware
- "traefik.http.routers.protected-https.middlewares=gzip,stargate-auth"
```

### Password Configuration Format

Stargate 1.8.0 accepts `plaintext` and `bcrypt`. Replace older MD5/SHA512 configurations before upgrading. Single-quote bcrypt values in `.env` so Compose preserves their dollar signs:

```bash
# Plaintext password (testing environment)
PASSWORDS=plaintext:test123|admin456

# Bcrypt encryption (recommended for production)
PASSWORDS='bcrypt:$2a$10$...'

```

### Cross-Domain Session Sharing

If you need to share sessions across multiple subdomains, configure `COOKIE_DOMAIN`:

```bash
COOKIE_DOMAIN=.example.com
```

This way, `auth.example.com` and `protected.example.com` can share login status.

## Usage Examples

### Enable Stargate Authentication for Other Services

Add `stargate-auth` middleware to the service's Traefik labels:

```yaml
labels:
  - "traefik.http.routers.your-service.middlewares=gzip,stargate-auth"
```

### Customize Login Page

You can customize the login page through environment variables:

```bash
LANGUAGE=zh                    # Language (zh/en)
LOGIN_PAGE_TITLE=Login         # Login page title
LOGIN_PAGE_FOOTER_TEXT=Please enter password  # Login page footer text
```

### Debug Mode

Enable debug mode to view detailed logs:

```bash
DEBUG=true
```

## FAQ

### Q: Still redirected to login page after login?

1. **Check Cookie Domain Configuration**:
   - If using multiple subdomains, ensure `COOKIE_DOMAIN` is configured
   - Ensure Cookie domain format is correct (e.g., `.example.com`)

2. **Check Browser Cookies**:
   - Open browser developer tools
   - Check if cookies are set
   - Confirm Cookie domain and path are correct

3. **Check Stargate Logs**:
   ```bash
   docker logs stargate
   ```

### Q: How to add more passwords?

Use `|` to separate multiple passwords in `PASSWORDS` environment variable:

```bash
PASSWORDS=plaintext:test123|admin456|user789
```

### Q: How to generate Bcrypt hash?

You can use online tools or command-line tools to generate Bcrypt hash:

```bash
# Using htpasswd (requires apache2-utils)
htpasswd -nbBC 10 "" yourpassword | cut -d: -f2

# Or use online tools
# https://bcrypt-generator.com/
```

### Q: How to disable authentication?

Remove `stargate-auth` middleware:

```yaml
# Before
- "traefik.http.routers.service.middlewares=gzip,stargate-auth"

# After
- "traefik.http.routers.service.middlewares=gzip"
```

### Q: What password encryption algorithms are supported?

Stargate supports the following encryption algorithms:
- `plaintext`: Plaintext (testing environment only)
- `bcrypt`: Bcrypt encryption (recommended for production)

## Related Resources

- [Stargate Project](https://github.com/soulteary/stargate)
- [Traefik Forward Auth Documentation](https://doc.traefik.io/traefik/middlewares/http/forwardauth/)
- [Traefik Middleware Documentation](https://doc.traefik.io/traefik/middlewares/overview/)
