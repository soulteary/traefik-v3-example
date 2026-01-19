# OwlMail Email Testing Service Example

[English](README.md) | [中文](README.zh.md)

This is a complete example of using OwlMail email testing service. OwlMail is an SMTP server and Web interface for development and testing environments that can capture and display all sent emails. It is fully compatible with MailDev API, providing better performance and richer features.

## Features

- ✅ **Email Capture**: Capture all sent test emails
- ✅ **Web Interface**: View emails through Web interface exposed via Traefik
- ✅ **SMTP Server**: Provides SMTP server for applications to connect
- ✅ **Email Persistence**: Supports email data persistence storage
- ✅ **HTTP Basic Auth**: Optional configuration to protect Web interface
- ✅ **Email Forwarding**: Supports forwarding emails to real SMTP server
- ✅ **100% Compatible with MailDev API**: Fully compatible with MailDev API

## Environment Variables Configuration

Before using this configuration, you need to configure the following environment variables in `owlmail/.env`:

```bash
# Service configuration
SERVICE_NAME=owlmail
SERVICE_PREFIX=owlmail
SERVICE_DOMAIN=mail.example.com
SERVICE_PORT=1080
DOCKER_IMAGE=ghcr.io/soulteary/owlmail:0.3.0

# SMTP configuration
SMTP_PORT=1025
SMTP_HOST=0.0.0.0

# Data directory
DATA_DIR=./owlmail-data

# Health check and logging configuration
HEALTH_CHECK_INTERVAL=10s
HEALTH_CHECK_TIMEOUT=3s
HEALTH_CHECK_RETRIES=3
LOG_MAX_SIZE=10m
LOG_MAX_FILE=3

# Optional configuration
# MAILDEV_WEB_USER=admin          # HTTP Basic Auth username
# MAILDEV_WEB_PASS=password123    # HTTP Basic Auth password
# MAILDEV_VERBOSE=false            # Log level (normal, verbose, silent)
# MAILDEV_MAIL_DIRECTORY=/data/mails  # Email storage directory (configured via volumes)
```

## Quick Start

### Prerequisites

- Docker 20.10+
- Docker Compose 2.0+
- Traefik service started (refer to `../../traefik/`)
- Traefik Docker network created

### Step 1: Configure Environment Variables

Configure domain in `owlmail/.env`:

```bash
SERVICE_DOMAIN=mail.example.com
```

### Step 2: Ensure DNS Resolution is Correct

Ensure domain DNS resolution is correct (`mail.example.com`)

### Step 3: Start Service

```bash
docker compose -f traefik-app-examples/owlmail/docker-compose.yml up -d
```

### Step 4: Access and Use

1. **Web Interface**:
   - Access `https://mail.example.com` to view all captured emails

2. **SMTP Server**:
   - SMTP server address: `localhost:1025`
   - For applications to connect and send test emails

## Configuration Guide

### Docker Compose Configuration

This configuration includes the following main features:

1. **Port Configuration**:
   - SMTP port (1025): Directly exposed for applications to connect
   - Web port (1080): Exposed via Traefik, supports HTTPS

2. **Email Storage**:
   - Email data is persistently stored in `./owlmail-data` directory
   - Mounted to container via volumes

3. **Traefik Integration**:
   - Web interface exposed via Traefik
   - Supports HTTPS and automatic redirect

### Configure Applications to Use OwlMail SMTP

Configure the following environment variables in your application:

```bash
# Environment variable example
SMTP_HOST=localhost
SMTP_PORT=1025
SMTP_USER=  # Optional, if SMTP authentication is enabled
SMTP_PASS=  # Optional, if SMTP authentication is enabled
```

### Email Persistence

Email data is saved in `./owlmail-data` directory and will not be lost even if the container restarts.

### HTTP Basic Auth (Optional)

If you need to protect the Web interface, uncomment environment variables:

```bash
MAILDEV_WEB_USER=admin
MAILDEV_WEB_PASS=password123
```

### Email Forwarding (Optional)

You can configure email forwarding to real SMTP server:

```bash
# Forwarding configuration example
MAILDEV_OUTGOING_HOST=smtp.example.com
MAILDEV_OUTGOING_PORT=587
MAILDEV_OUTGOING_USER=your-email@example.com
MAILDEV_OUTGOING_PASS=your-password
MAILDEV_OUTGOING_SECURE=true
```

## Usage Examples

### Send Test Email

Use command-line tools to send test emails:

```bash
# Using telnet
telnet localhost 1025

# Send email
HELO localhost
MAIL FROM: test@example.com
RCPT TO: recipient@example.com
DATA
Subject: Test Email
This is a test email.
.
QUIT
```

### Send Email from Application

Configure SMTP settings in your application:

```python
# Python example
import smtplib
from email.mime.text import MIMEText

msg = MIMEText('Test email body')
msg['Subject'] = 'Test Email'
msg['From'] = 'sender@example.com'
msg['To'] = 'recipient@example.com'

smtp = smtplib.SMTP('localhost', 1025)
smtp.send_message(msg)
smtp.quit()
```

### View Emails

Access Web interface `https://mail.example.com` to view all captured emails.

## FAQ

### Q: Cannot connect to SMTP server?

1. **Check if port is exposed**:
   ```bash
   docker ps | grep owlmail
   ```

2. **Check firewall**:
   - Confirm firewall allows port 1025
   - Confirm port is not occupied by other services

3. **Check service logs**:
   ```bash
   docker logs owlmail
   ```

### Q: Web interface cannot be accessed?

1. **Check Traefik configuration**:
   - Confirm service is in `traefik` network
   - Confirm domain DNS resolution is correct

2. **Check Traefik logs**:
   ```bash
   docker logs traefik
   ```

### Q: Email data lost?

Email data is stored in `./owlmail-data` directory. If data is lost:

1. Check if directory exists
2. Check directory permissions
3. Check if volumes configuration is correct

### Q: How to clear email data?

Delete data directory and restart service:

```bash
rm -rf ./owlmail-data
docker compose -f traefik-app-examples/owlmail/docker-compose.yml restart owlmail
```

### Q: How to configure email forwarding?

Configure forwarding-related environment variables in `.env` file:

```bash
MAILDEV_OUTGOING_HOST=smtp.example.com
MAILDEV_OUTGOING_PORT=587
MAILDEV_OUTGOING_USER=your-email@example.com
MAILDEV_OUTGOING_PASS=your-password
MAILDEV_OUTGOING_SECURE=true
```

Then restart the service.

## Related Resources

- [OwlMail Project](https://github.com/soulteary/owlmail)
- [MailDev API Documentation](https://github.com/maildev/maildev)
- [Traefik Service Discovery Documentation](https://doc.traefik.io/traefik/providers/docker/)
