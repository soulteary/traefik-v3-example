# Stargate Forward Auth 服务示例

[English](README.md) | [中文](README.zh.md)

这是一个使用 Stargate Forward Auth 服务保护后端服务的完整示例。Stargate 是一个轻量级的 Forward Auth 服务，可以作为统一的认证入口保护多个后端服务。

## 功能特性

- ✅ **统一认证入口**：为多个后端服务提供统一的认证入口
- ✅ **Forward Auth 中间件**：通过 Traefik Forward Auth 中间件保护服务
- ✅ **跨域会话共享**：支持跨域会话共享（通过 Cookie 域名配置）
- ✅ **多种密码加密**：支持 plaintext、bcrypt、md5、sha512 等加密算法
- ✅ **受保护服务示例**：包含完整的受保护服务演示

## 环境变量配置

在使用此配置之前，需要在 `stargate/.env` 文件中配置以下环境变量：

```bash
# Stargate 服务配置
STARGATE_SERVICE_NAME=stargate
STARGATE_PREFIX=stargate
STARGATE_DOMAIN=auth.example.com
STARGATE_PORT=8080
STARGATE_DOCKER_IMAGE=ghcr.io/soulteary/stargate:v0.2.0

# 受保护服务配置
PROTECTED_SERVICE_NAME=protected-service
PROTECTED_PREFIX=protected
PROTECTED_DOMAIN=protected.example.com
PROTECTED_PORT=80
PROTECTED_DOCKER_IMAGE=ghcr.io/traefik/whoami:v1.11

# 认证配置
AUTH_HOST=auth.example.com
PASSWORDS=plaintext:test123|admin456

# 可选配置
LANGUAGE=zh
LOGIN_PAGE_TITLE=登录
LOGIN_PAGE_FOOTER_TEXT=请输入密码
USER_HEADER_NAME=X-User
# COOKIE_DOMAIN=.example.com  # 用于跨域会话共享
# DEBUG=false

# 健康检查和日志配置
HEALTH_CHECK_INTERVAL=10s
HEALTH_CHECK_TIMEOUT=3s
HEALTH_CHECK_RETRIES=3
LOG_MAX_SIZE=10m
LOG_MAX_FILE=3
```

## 快速开始

### 前置要求

- Docker 20.10+
- Docker Compose 2.0+
- Traefik 服务已启动（参考 `../../traefik/`）
- 已创建 Traefik Docker 网络

### 步骤 1：配置环境变量

在 `stargate/.env` 中配置：

1. **认证服务域名**：`AUTH_HOST` 和 `STARGATE_DOMAIN`
2. **受保护服务域名**：`PROTECTED_DOMAIN`
3. **密码配置**：`PASSWORDS`（格式：`算法:密码1|密码2|密码3`）

### 步骤 2：确保 DNS 解析正确

确保以下域名 DNS 解析正确：
- `auth.example.com`（Stargate 认证服务）
- `protected.example.com`（受保护的服务）

### 步骤 3：启动服务

```bash
docker compose -f traefik-app-examples/stargate/docker-compose.yml up -d
```

### 步骤 4：访问服务

1. **访问受保护的服务**：
   - 首次访问 `https://protected.example.com` 会被重定向到登录页面

2. **登录页面**：
   - 登录页面：`https://auth.example.com/_login?callback=https://protected.example.com`
   - 输入配置的密码（例如：`test123` 或 `admin456`）完成登录

3. **登录成功后**：
   - 会自动跳转回受保护的服务
   - 后续访问无需再次登录（基于 Cookie 会话）

## 配置说明

### Stargate 服务配置

Stargate 服务配置了 Forward Auth 中间件，供其他服务使用：

```yaml
# 定义 Forward Auth 中间件（供其他服务使用）
# 注意：实际配置中使用 ${STARGATE_SERVICE_NAME} 变量（默认值为 stargate）
- "traefik.http.middlewares.stargate-auth.forwardauth.address=http://${STARGATE_SERVICE_NAME}/_auth"
- "traefik.http.middlewares.stargate-auth.forwardauth.authResponseHeaders=X-User"
- "traefik.http.middlewares.stargate-auth.forwardauth.authResponseHeadersRegex=X-Forwarded-.*"
- "traefik.http.middlewares.stargate-auth.forwardauth.trustForwardHeader=true"
```

### 受保护服务配置

受保护的服务通过 `stargate-auth` 中间件启用认证：

```yaml
# HTTPS 路由 - 使用 Stargate 认证中间件
- "traefik.http.routers.protected-https.middlewares=gzip,stargate-auth"
```

### 密码配置格式

支持多种密码加密算法：

```bash
# 明文密码（测试环境）
PASSWORDS=plaintext:test123|admin456

# Bcrypt 加密（生产环境推荐）
PASSWORDS=bcrypt:$2a$10$...

# MD5 加密
PASSWORDS=md5:5e884898da28047151d0e56f8dc6292773603d0d6aabbdd62a11ef721d1542d8

# SHA512 加密
PASSWORDS=sha512:ee26b0dd4af7e749aa1a8ee3c10ae9923f618980772e473f8819a5d4940e0db27ac185f8a0e1d5f84f88bc887fd67b143732c304cc5fa9ad8e6f57f50028a8
```

### 跨域会话共享

如果需要在多个子域名之间共享会话，配置 `COOKIE_DOMAIN`：

```bash
COOKIE_DOMAIN=.example.com
```

这样，`auth.example.com` 和 `protected.example.com` 可以共享登录状态。

## 使用示例

### 为其他服务启用 Stargate 认证

在服务的 Traefik 标签中添加 `stargate-auth` 中间件：

```yaml
labels:
  - "traefik.http.routers.your-service.middlewares=gzip,stargate-auth"
```

### 自定义登录页面

可以通过环境变量自定义登录页面：

```bash
LANGUAGE=zh                    # 语言（zh/en）
LOGIN_PAGE_TITLE=登录          # 登录页面标题
LOGIN_PAGE_FOOTER_TEXT=请输入密码  # 登录页面底部文本
```

### 调试模式

启用调试模式以查看详细日志：

```bash
DEBUG=true
```

## 常见问题

### Q: 登录后仍然被重定向到登录页面？

1. **检查 Cookie 域名配置**：
   - 如果使用多个子域名，确保配置了 `COOKIE_DOMAIN`
   - 确保 Cookie 域名格式正确（例如：`.example.com`）

2. **检查浏览器 Cookie**：
   - 打开浏览器开发者工具
   - 查看 Cookie 是否已设置
   - 确认 Cookie 域名和路径正确

3. **检查 Stargate 日志**：
   ```bash
   docker logs stargate
   ```

### Q: 如何添加更多密码？

在 `PASSWORDS` 环境变量中使用 `|` 分隔多个密码：

```bash
PASSWORDS=plaintext:test123|admin456|user789
```

### Q: 如何生成 Bcrypt 哈希？

可以使用在线工具或命令行工具生成 Bcrypt 哈希：

```bash
# 使用 htpasswd（需要安装 apache2-utils）
htpasswd -nbBC 10 "" yourpassword | cut -d: -f2

# 或使用在线工具
# https://bcrypt-generator.com/
```

### Q: 如何禁用认证？

移除 `stargate-auth` 中间件：

```yaml
# 修改前
- "traefik.http.routers.service.middlewares=gzip,stargate-auth"

# 修改后
- "traefik.http.routers.service.middlewares=gzip"
```

### Q: 支持哪些密码加密算法？

Stargate 支持以下加密算法：
- `plaintext`：明文（仅测试环境）
- `bcrypt`：Bcrypt 加密（推荐生产环境）
- `md5`：MD5 哈希
- `sha512`：SHA512 哈希

## 相关资源

- [Stargate 项目](https://github.com/soulteary/stargate)
- [Traefik Forward Auth 文档](https://doc.traefik.io/traefik/middlewares/http/forwardauth/)
- [Traefik 中间件文档](https://doc.traefik.io/traefik/middlewares/overview/)
