# Traefik 基础配置

[English](README.md) | [中文](README.zh.md)

这是 Traefik 的基础配置，需要完整的环境变量配置，支持 ACME 和本地证书两种方式。

## 功能特性

- ✅ **服务动态接入**：基于 Docker 标签自动发现和配置服务
- ✅ **多种证书配置**：支持 ACME 自动申请证书和本地证书两种方式
- ✅ **HTTP/3 支持**：启用 HTTP/3 (QUIC) 协议支持
- ✅ **Dashboard 界面**：内置 Traefik Dashboard 可视化界面
- ✅ **HTTPS 重定向**：自动将 HTTP 请求重定向到 HTTPS
- ✅ **GZIP 压缩**：自动启用响应内容压缩
- ✅ **健康检查**：内置健康检查机制
- ✅ **生产就绪**：关闭匿名数据收集和版本检查，适合生产环境

## 环境变量配置

在使用此配置之前，需要在 `base/.env` 文件中配置以下环境变量：

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

### 启动服务

```bash
docker compose -f traefik/base/docker-compose.yml up -d
```

### 访问 Dashboard

启动成功后，访问 Traefik Dashboard：

- HTTPS: `https://traefik.example.com/dashboard/`
- API: `https://traefik.example.com/api/`

> 注意：请将 `traefik.example.com` 替换为你配置的实际域名，并确保 DNS 解析正确。

## 配置说明

### Docker Compose 配置

此配置包含以下主要特性：

1. **端口配置**：
   - HTTP 端口（默认 80）：用于 HTTP 请求，自动重定向到 HTTPS
   - HTTPS 端口（默认 443）：支持 TCP 和 UDP（用于 HTTP/3）

2. **证书配置**：
   - 支持本地证书（需要配置 `./config/certs.toml`）

3. **中间件**：
   - `gzip`：GZIP 压缩中间件
   - `redir-https`：HTTP 到 HTTPS 重定向中间件

4. **服务发现**：
   - 基于 Docker 标签自动发现服务
   - 默认不暴露所有容器，需要显式启用 `traefik.enable=true`

### 配置文件说明

#### `./config/certs.toml`

如果使用本地证书，需要配置证书路径：

```toml
[tls.stores.default.defaultCertificate]
certFile = "/data/ssl/example.com.pem.crt"
keyFile = "/data/ssl/example.com.pem.key"

[[tls.certificates]]
certFile = "/data/ssl/example.com.pem.crt"
keyFile = "/data/ssl/example.com.pem.key"
```

#### `./config/tls.toml`

配置 TLS 选项，包括支持的 TLS 版本和加密套件：

```toml
[tls.options.default]
minVersion = "VersionTLS12"
sniStrict = false
cipherSuites = [
  "TLS_AES_128_GCM_SHA256",
  "TLS_AES_256_GCM_SHA384",
  # ... 更多加密套件
]
```

## 使用本地证书

如果使用本地证书，需要：

1. 生成证书（参考 `../../traefik-make-local-certs/`）
2. 配置 `./config/certs.toml` 中的证书路径
3. 启动服务

## 常见问题

### Q: 如何查看 Traefik 日志？

```bash
docker logs -f traefik
```

### Q: 如何更新 Traefik 配置？

修改配置文件后，Traefik 会自动重新加载（已启用 `watch` 模式）。如果修改了 Docker Compose 配置，需要重启服务：

```bash
docker compose -f traefik/base/docker-compose.yml restart traefik
```

### Q: 如何添加多个域名？

在环境变量中配置 `DNS_LIST`，使用逗号分隔：

```bash
DNS_LIST=*.example.com,*.test.com,example.com
```

### Q: HTTP/3 不工作？

- 确保端口同时开放 TCP 和 UDP（443）
- 检查防火墙是否允许 UDP 443 端口
- 某些网络环境可能不支持 QUIC 协议

### Q: 如何禁用 Dashboard？

移除或注释掉以下标签：

```yaml
# - "--api.dashboard=true"
```

## 相关资源

- [Traefik 官方文档](https://doc.traefik.io/traefik/)
- [Traefik Docker Provider](https://doc.traefik.io/traefik/providers/docker/)
