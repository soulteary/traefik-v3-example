# Traefik v3.x 快速上手示例

本项目旨在演示如何快速上手 Traefik v3.x：包含服务动态接入、配置证书等核心功能。

如果你觉得这个例子有帮到你，欢迎点赞✨（star），如果你希望收到这个项目的更新推送，可以点击关注 👀（watch）并选择适合自己的关注模式。

## 功能特性

- ✅ **服务动态接入**：基于 Docker 标签自动发现和配置服务
- ✅ **多种证书配置**：支持 ACME 自动申请证书和本地证书两种方式
- ✅ **HTTP/3 支持**：启用 HTTP/3 (QUIC) 协议支持
- ✅ **Dashboard 界面**：内置 Traefik Dashboard 可视化界面
- ✅ **HTTPS 重定向**：自动将 HTTP 请求重定向到 HTTPS
- ✅ **GZIP 压缩**：自动启用响应内容压缩
- ✅ **健康检查**：内置健康检查机制
- ✅ **生产就绪**：关闭匿名数据收集和版本检查，适合生产环境

## 项目结构

```
traefik-v3-example/
├── config/                    # Traefik 配置文件目录
│   ├── certs.toml            # 证书配置（本地证书路径）
│   └── tls.toml              # TLS 选项配置（加密套件等）
├── scripts/                   # 工具脚本目录
│   ├── generate-certs.sh     # 生成自签名证书脚本
│   └── prepare-network.sh    # 创建 Docker 网络脚本
├── ssl/                       # 证书存储目录
│   ├── acme.json             # ACME 证书存储文件（ACME 模式）
│   └── example.com.conf      # 证书生成配置文件示例
├── docker-compose.yml         # 基础配置（需要环境变量）
├── docker-compose.acme.yml    # ACME 自动申请证书配置
├── docker-compose.local-certs.yml  # 使用本地证书配置
├── docker-compose.flare.yml   # Flare 服务接入示例
├── docker-compose.make-cert.yml    # 证书生成工具
└── README.md                  # 本文档
```

## 快速开始

### 前置要求

- Docker 20.10+
- Docker Compose 2.0+
- 基本的 Linux/Unix 命令行知识

### 环境变量配置

在使用 `docker-compose.yml` 之前，需要配置以下环境变量。你可以创建 `.env` 文件或直接导出环境变量：

```bash
# 服务配置
SERVICE_NAME=traefik
DOCKER_IMAGE=traefik:v3.0
SERVICE_HTTP_PORT=80
SERVICE_HTTPS_PORT=443
SERVICE_DOMAIN=traefik.example.com

# DNS 配置（用于 ACME 证书）
DNS_MAIN=example.com
DNS_LIST=*.example.com

# ACME 配置（如果使用 ACME 模式）
ACME_EMAIL=your-email@example.com
ACME_PROVIDER=cloudflare
CF_DNS_API_TOKEN=your-cloudflare-api-token
```

### 步骤 1：准备 Docker 网络

Traefik 需要创建一个专用的 Docker 网络：

```bash
./scripts/prepare-network.sh
```

或者手动创建：

```bash
docker network create traefik
```

### 步骤 2：选择启动方式

根据你的需求选择不同的配置方式：

#### 方式一：使用本地证书（适合测试环境）

1. 生成自签名证书：

```bash
./scripts/generate-certs.sh
```

或者使用 Docker 容器生成：

```bash
docker-compose -f docker-compose.make-cert.yml up
```

2. 启动 Traefik：

```bash
docker-compose -f docker-compose.local-certs.yml up -d
```

#### 方式二：使用 ACME 自动申请证书（适合生产环境）

1. 配置环境变量（特别是 `ACME_EMAIL` 和 `CF_DNS_API_TOKEN`）
2. 启动 Traefik：

```bash
docker-compose -f docker-compose.acme.yml up -d
```

#### 方式三：使用基础配置（需要完整环境变量）

```bash
docker-compose up -d
```

### 步骤 3：访问 Dashboard

启动成功后，访问 Traefik Dashboard：

- HTTPS: `https://traefik.example.com/dashboard/`
- API: `https://traefik.example.com/api/`

> 注意：请将 `traefik.example.com` 替换为你配置的实际域名，并确保 DNS 解析正确。

## 配置说明

### Docker Compose 文件说明

| 文件 | 用途 | 说明 |
|------|------|------|
| `docker-compose.yml` | 基础配置 | 需要完整的环境变量配置，支持 ACME 和本地证书 |
| `docker-compose.acme.yml` | ACME 证书配置 | 使用 Let's Encrypt 自动申请证书（需要 DNS API Token） |
| `docker-compose.local-certs.yml` | 本地证书配置 | 使用本地自签名证书，适合测试环境 |
| `docker-compose.flare.yml` | 服务示例 | Flare 服务接入 Traefik 的完整示例 |
| `docker-compose.make-cert.yml` | 证书生成工具 | 使用 certs-maker 容器生成自签名证书 |

### 配置文件说明

#### `config/certs.toml`

配置本地证书路径，Traefik 会自动加载此目录下的证书：

```toml
[tls.stores.default.defaultCertificate]
certFile = "/data/ssl/example.com.pem.crt"
keyFile = "/data/ssl/example.com.pem.key"

[[tls.certificates]]
certFile = "/data/ssl/example.com.pem.crt"
keyFile = "/data/ssl/example.com.pem.key"
```

#### `config/tls.toml`

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

### 脚本说明

#### `scripts/prepare-network.sh`

创建 Traefik 专用的 Docker 网络。如果网络已存在，脚本会跳过创建。

#### `scripts/generate-certs.sh`

生成自签名证书，支持通配符域名（如 `*.example.com`）。生成的证书会保存在 `ssl/` 目录下。

## 使用示例

### 示例 1：接入新服务（参考 Flare 示例）

以 `docker-compose.flare.yml` 为例，展示如何将服务接入 Traefik：

```yaml
services:
  flare:
    image: soulteary/flare:0.5.1
    networks:
      - traefik
    labels:
      # 启用 Traefik
      - "traefik.enable=true"
      - "traefik.docker.network=traefik"
      
      # HTTP 路由（自动重定向到 HTTPS）
      - "traefik.http.routers.flare-http.entrypoints=http"
      - "traefik.http.routers.flare-http.middlewares=redir-https"
      - "traefik.http.routers.flare-http.rule=Host(`flare.example.com`)"
      - "traefik.http.routers.flare-http.service=noop@internal"
      
      # HTTPS 路由
      - "traefik.http.routers.flare-https.entrypoints=https"
      - "traefik.http.routers.flare-https.tls=true"
      - "traefik.http.routers.flare-https.middlewares=gzip"
      - "traefik.http.routers.flare-https.rule=Host(`flare.example.com`)"
      
      # 服务配置
      - "traefik.http.services.flare-backend.loadbalancer.server.scheme=http"
      - "traefik.http.services.flare-backend.loadbalancer.server.port=5005"
```

关键标签说明：

- `traefik.enable=true`：启用 Traefik 服务发现
- `traefik.docker.network=traefik`：指定 Docker 网络
- `traefik.http.routers.*.rule`：路由规则（基于域名、路径等）
- `traefik.http.routers.*.entrypoints`：指定入口点（http/https）
- `traefik.http.routers.*.tls`：启用 TLS
- `traefik.http.services.*.loadbalancer.server.port`：后端服务端口

### 示例 2：使用本地证书

1. 生成证书：

```bash
./scripts/generate-certs.sh
```

2. 确保 `config/certs.toml` 中的证书路径正确
3. 启动服务：

```bash
docker-compose -f docker-compose.local-certs.yml up -d
```

### 示例 3：使用 ACME 自动申请证书

1. 配置 Cloudflare DNS API Token（或其他支持的 DNS 提供商）
2. 设置环境变量：

```bash
export ACME_EMAIL=your-email@example.com
export ACME_PROVIDER=cloudflare
export CF_DNS_API_TOKEN=your-token
```

3. 启动服务：

```bash
docker-compose -f docker-compose.acme.yml up -d
```

Traefik 会自动通过 DNS Challenge 申请证书。

## 常见问题

### Q: 如何查看 Traefik 日志？

```bash
docker logs -f traefik
```

### Q: 证书申请失败怎么办？

- 检查 DNS API Token 是否正确
- 确认域名 DNS 解析正常
- 查看 Traefik 日志排查具体错误
- 检查防火墙是否允许 DNS 查询

### Q: 如何更新 Traefik 配置？

修改配置文件后，Traefik 会自动重新加载（已启用 `watch` 模式）。如果修改了 Docker Compose 配置，需要重启服务：

```bash
docker-compose restart traefik
```

### Q: 如何添加多个域名？

在环境变量中配置 `DNS_LIST`，使用逗号分隔：

```bash
DNS_LIST=*.example.com,*.test.com,example.com
```

或在服务标签中使用数组语法：

```yaml
- "traefik.http.routers.service.tls.domains[0].main=example.com"
- "traefik.http.routers.service.tls.domains[0].sans=*.example.com,test.com"
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

或通过环境变量控制访问权限。

## 相关资源

### 完整使用方法

- [Docker 环境下使用 Traefik 3 的最佳实践：快速上手](https://soulteary.com/2024/08/04/best-practices-for-traefik-3-in-docker-getting-started-quickly.html)

### 相关项目

- [Traefik](https://github.com/traefik/traefik) - 云原生反向代理和负载均衡器
- [certs-maker](https://github.com/soulteary/certs-maker) - 证书生成工具
- [docker-flare](https://github.com/soulteary/docker-flare) - Flare 服务 Docker 镜像

### 官方文档

- [Traefik 官方文档](https://doc.traefik.io/traefik/)
- [Traefik Docker Provider](https://doc.traefik.io/traefik/providers/docker/)
- [Traefik ACME 配置](https://doc.traefik.io/traefik/https/acme/)

## 许可证

详见 [LICENSE](LICENSE) 文件。
