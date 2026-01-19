# Traefik 本地证书配置

[English](README.md) | [中文](README.zh.md)

这是使用本地证书的 Traefik 配置，适合测试环境使用。使用自签名证书或自己管理的证书文件。

## 功能特性

- ✅ **本地证书支持**：使用本地证书文件，无需外部证书服务
- ✅ **快速部署**：适合测试和开发环境
- ✅ **HTTP/3 支持**：启用 HTTP/3 (QUIC) 协议支持
- ✅ **Dashboard 界面**：内置 Traefik Dashboard 可视化界面
- ✅ **HTTPS 重定向**：自动将 HTTP 请求重定向到 HTTPS

## 环境变量配置

在使用此配置之前，需要在 `local-certs/.env` 文件中配置以下环境变量：

```bash
# 服务配置
SERVICE_NAME=traefik
DOCKER_IMAGE=ghcr.io/traefik/traefik:v3.6.7
SERVICE_HTTP_PORT=80
SERVICE_HTTPS_PORT=443
SERVICE_DOMAIN=traefik.example.com
```

## 快速开始

### 前置要求

- Docker 20.10+
- Docker Compose 2.0+
- 已创建 Traefik Docker 网络（运行 `../../scripts/prepare-network.sh`）
- 已生成本地证书（参考 `../../traefik-make-local-certs/`）

### 步骤 1：生成证书

使用证书生成工具生成自签名证书：

```bash
docker compose -f traefik-make-local-certs/docker-compose.yml up
docker compose -f traefik-make-local-certs/docker-compose.yml down --remove-orphans
```

> 提示：如需自定义域名，可以修改 `traefik-make-local-certs/.env` 中的 `CERT_DNS` 环境变量，例如：`CERT_DNS=yourdomain.com,*.yourdomain.com`

生成的证书会保存在 `../../ssl/` 目录下。

### 步骤 2：配置证书路径

确保 `./config/certs.toml` 中的证书路径正确：

```toml
[tls.stores.default.defaultCertificate]
certFile = "/data/ssl/example.com.pem.crt"
keyFile = "/data/ssl/example.com.pem.key"

[[tls.certificates]]
certFile = "/data/ssl/example.com.pem.crt"
keyFile = "/data/ssl/example.com.pem.key"
```

> 注意：请将 `example.com` 替换为你实际使用的域名。

### 步骤 3：启动服务

```bash
docker compose -f traefik/local-certs/docker-compose.yml up -d
```

### 步骤 4：访问 Dashboard

启动成功后，访问 Traefik Dashboard：

- HTTPS: `https://traefik.example.com/dashboard/`
- API: `https://traefik.example.com/api/`

> 注意：由于使用的是自签名证书，浏览器会显示安全警告，这是正常现象。在测试环境中可以点击"继续访问"。

## 配置说明

### 证书文件格式

Traefik 支持 PEM 格式的证书文件：

- 证书文件：`.pem.crt` 或 `.crt`
- 私钥文件：`.pem.key` 或 `.key`

### 证书配置

证书配置在 `./config/certs.toml` 文件中：

1. **默认证书**：设置默认使用的证书
2. **证书列表**：配置所有需要使用的证书

### 与 ACME 配置的区别

此配置与 `acme/` 配置的主要区别：

- **无 ACME 配置**：不包含 ACME 证书解析器配置
- **无 DNS API Token**：不需要配置 DNS API Token
- **使用本地证书**：从本地文件系统加载证书

## 使用示例

### 使用自签名证书

1. 生成证书（参考 `../../traefik-make-local-certs/`）
2. 配置 `./config/certs.toml`
3. 启动服务

### 使用自己的证书

如果你有自己的证书文件：

1. 将证书文件复制到 `../../ssl/` 目录
2. 确保文件名为 `域名.pem.crt` 和 `域名.pem.key`
3. 更新 `./config/certs.toml` 中的路径
4. 启动服务

### 为服务配置本地证书

在服务的 Docker Compose 文件中，不需要特殊配置，Traefik 会自动使用配置的默认证书：

```yaml
labels:
  - "traefik.http.routers.your-service.tls=true"
  - "traefik.http.routers.your-service.rule=Host(`your-service.example.com`)"
```

## 常见问题

### Q: 浏览器显示证书不安全警告？

这是正常现象，因为使用的是自签名证书。在测试环境中：

1. 点击"高级"或"Advanced"
2. 点击"继续访问"或"Proceed to site"

### Q: 如何生成证书？

参考 `../../traefik-make-local-certs/` 目录中的证书生成工具。

### Q: 证书文件应该放在哪里？

证书文件应该放在 `../../ssl/` 目录下，Traefik 容器会挂载此目录。

### Q: 如何更新证书？

1. 将新证书文件复制到 `../../ssl/` 目录
2. 重启 Traefik 服务：

```bash
docker compose -f traefik/local-certs/docker-compose.yml restart traefik
```

### Q: 可以使用多个证书吗？

可以，在 `./config/certs.toml` 中添加多个证书配置：

```toml
[[tls.certificates]]
certFile = "/data/ssl/example.com.pem.crt"
keyFile = "/data/ssl/example.com.pem.key"

[[tls.certificates]]
certFile = "/data/ssl/test.com.pem.crt"
keyFile = "/data/ssl/test.com.pem.key"
```

### Q: 如何切换到 ACME 模式？

如果需要切换到 ACME 自动申请证书，请使用 `../../traefik/acme/` 配置。

## 相关资源

- [Traefik TLS 配置文档](https://doc.traefik.io/traefik/https/tls/)
- [证书生成工具](../traefik-make-local-certs/)
