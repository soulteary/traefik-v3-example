# OwlMail 邮件测试服务示例

[English](README.md) | [中文](README.zh.md)

这是一个使用 OwlMail 邮件测试服务的完整示例。OwlMail 是一个用于开发和测试环境的 SMTP 服务器和 Web 界面，可以捕获和显示所有发送的邮件。它完全兼容 MailDev API，提供更好的性能和更丰富的功能。

## 功能特性

- ✅ **邮件捕获**：捕获所有发送的测试邮件
- ✅ **Web 界面**：通过 Traefik 暴露的 Web 界面查看邮件
- ✅ **SMTP 服务器**：提供 SMTP 服务器供应用程序连接
- ✅ **邮件持久化**：支持邮件数据持久化存储
- ✅ **HTTP Basic Auth**：可选配置保护 Web 界面
- ✅ **邮件转发**：支持转发邮件到真实的 SMTP 服务器
- ✅ **100% 兼容 MailDev API**：完全兼容 MailDev API

## 环境变量配置

在使用此配置之前，需要在 `owlmail/.env` 文件中配置以下环境变量：

```bash
# 服务配置
SERVICE_NAME=owlmail
SERVICE_PREFIX=owlmail
SERVICE_DOMAIN=mail.example.com
SERVICE_PORT=1080
DOCKER_IMAGE=ghcr.io/soulteary/owlmail:0.3.0

# SMTP 配置
SMTP_PORT=1025
SMTP_HOST=0.0.0.0

# 数据目录
DATA_DIR=./owlmail-data

# 健康检查和日志配置
HEALTH_CHECK_INTERVAL=10s
HEALTH_CHECK_TIMEOUT=3s
HEALTH_CHECK_RETRIES=3
LOG_MAX_SIZE=10m
LOG_MAX_FILE=3

# 可选配置
# MAILDEV_WEB_USER=admin          # HTTP Basic Auth 用户名
# MAILDEV_WEB_PASS=password123    # HTTP Basic Auth 密码
# MAILDEV_VERBOSE=false            # 日志级别（normal, verbose, silent）
# MAILDEV_MAIL_DIRECTORY=/data/mails  # 邮件存储目录（已通过 volumes 配置）
```

## 快速开始

### 前置要求

- Docker 20.10+
- Docker Compose 2.0+
- Traefik 服务已启动（参考 `../../traefik/`）
- 已创建 Traefik Docker 网络

### 步骤 1：配置环境变量

在 `owlmail/.env` 中配置域名：

```bash
SERVICE_DOMAIN=mail.example.com
```

### 步骤 2：确保 DNS 解析正确

确保域名 DNS 解析正确（`mail.example.com`）

### 步骤 3：启动服务

```bash
docker compose -f traefik-app-examples/owlmail/docker-compose.yml up -d
```

### 步骤 4：访问和使用

1. **Web 界面**：
   - 访问 `https://mail.example.com` 查看所有捕获的邮件

2. **SMTP 服务器**：
   - SMTP 服务器地址：`localhost:1025`
   - 供应用程序连接发送测试邮件

## 配置说明

### Docker Compose 配置

此配置包含以下主要特性：

1. **端口配置**：
   - SMTP 端口（1025）：直接暴露，供应用程序连接
   - Web 端口（1080）：通过 Traefik 暴露，支持 HTTPS

2. **邮件存储**：
   - 邮件数据持久化存储在 `./owlmail-data` 目录
   - 通过 volumes 挂载到容器

3. **Traefik 集成**：
   - Web 界面通过 Traefik 暴露
   - 支持 HTTPS 和自动重定向

### 配置应用程序使用 OwlMail SMTP

在你的应用程序中配置以下环境变量：

```bash
# 环境变量示例
SMTP_HOST=localhost
SMTP_PORT=1025
SMTP_USER=  # 可选，如果启用了 SMTP 认证
SMTP_PASS=  # 可选，如果启用了 SMTP 认证
```

### 邮件持久化

邮件数据会保存在 `./owlmail-data` 目录中，即使容器重启也不会丢失。

### HTTP Basic Auth（可选）

如果需要保护 Web 界面，取消注释环境变量：

```bash
MAILDEV_WEB_USER=admin
MAILDEV_WEB_PASS=password123
```

### 邮件转发（可选）

可以配置邮件转发到真实的 SMTP 服务器：

```bash
# 转发配置示例
MAILDEV_OUTGOING_HOST=smtp.example.com
MAILDEV_OUTGOING_PORT=587
MAILDEV_OUTGOING_USER=your-email@example.com
MAILDEV_OUTGOING_PASS=your-password
MAILDEV_OUTGOING_SECURE=true
```

## 使用示例

### 发送测试邮件

使用命令行工具发送测试邮件：

```bash
# 使用 telnet
telnet localhost 1025

# 发送邮件
HELO localhost
MAIL FROM: test@example.com
RCPT TO: recipient@example.com
DATA
Subject: Test Email
This is a test email.
.
QUIT
```

### 使用应用程序发送邮件

在应用程序中配置 SMTP 设置：

```python
# Python 示例
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

### 查看邮件

访问 Web 界面 `https://mail.example.com` 查看所有捕获的邮件。

## 常见问题

### Q: SMTP 服务器无法连接？

1. **检查端口是否暴露**：
   ```bash
   docker ps | grep owlmail
   ```

2. **检查防火墙**：
   - 确认防火墙允许 1025 端口
   - 确认端口没有被其他服务占用

3. **检查服务日志**：
   ```bash
   docker logs owlmail
   ```

### Q: Web 界面无法访问？

1. **检查 Traefik 配置**：
   - 确认服务在 `traefik` 网络中
   - 确认域名 DNS 解析正确

2. **检查 Traefik 日志**：
   ```bash
   docker logs traefik
   ```

### Q: 邮件数据丢失？

邮件数据存储在 `./owlmail-data` 目录中。如果数据丢失：

1. 检查目录是否存在
2. 检查目录权限
3. 检查 volumes 配置是否正确

### Q: 如何清空邮件数据？

删除数据目录并重启服务：

```bash
rm -rf ./owlmail-data
docker compose -f traefik-app-examples/owlmail/docker-compose.yml restart owlmail
```

### Q: 如何配置邮件转发？

在 `.env` 文件中配置转发相关环境变量：

```bash
MAILDEV_OUTGOING_HOST=smtp.example.com
MAILDEV_OUTGOING_PORT=587
MAILDEV_OUTGOING_USER=your-email@example.com
MAILDEV_OUTGOING_PASS=your-password
MAILDEV_OUTGOING_SECURE=true
```

然后重启服务。

## 相关资源

- [OwlMail 项目](https://github.com/soulteary/owlmail)
- [MailDev API 文档](https://github.com/maildev/maildev)
- [Traefik 服务发现文档](https://doc.traefik.io/traefik/providers/docker/)
