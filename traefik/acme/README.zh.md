# Traefik ACME 证书配置

[English](README.md) | [中文](README.zh.md)

这是使用 ACME 自动申请证书的 Traefik 配置，适合生产环境使用。Traefik 会自动通过 DNS Challenge 从 Let's Encrypt 申请证书。

## 功能特性

- ✅ **自动证书申请**：通过 DNS Challenge 自动申请 Let's Encrypt 证书
- ✅ **证书自动续期**：证书到期前自动续期
- ✅ **支持通配符证书**：支持 `*.example.com` 通配符域名
- ✅ **多域名支持**：支持多个域名和子域名
- ✅ **HTTP/3 支持**：启用 HTTP/3 (QUIC) 协议支持
- ✅ **Dashboard 界面**：内置 Traefik Dashboard 可视化界面

## 环境变量配置

在使用此配置之前，需要在 `acme/.env` 文件中配置以下环境变量：

```bash
# 服务配置
SERVICE_NAME=traefik
DOCKER_IMAGE=ghcr.io/traefik/traefik:v3.6.7
SERVICE_HTTP_PORT=80
SERVICE_HTTPS_PORT=443
SERVICE_DOMAIN=traefik.example.com

# DNS 配置（用于 ACME 证书）
DNS_MAIN=example.com
DNS_LIST=*.example.com

# ACME 配置（必需）
ACME_EMAIL=your-email@example.com
ACME_PROVIDER=cloudflare
CF_DNS_API_TOKEN=your-cloudflare-api-token
```

## 支持的 DNS 提供商

Traefik 支持多种 DNS 提供商，常用的包括：

- **Cloudflare** (`cloudflare`)：需要 `CF_DNS_API_TOKEN`
- **Aliyun** (`alidns`)：需要 `ALICLOUD_ACCESS_KEY` 和 `ALICLOUD_SECRET_KEY`
- **Tencent Cloud** (`tencentcloud`)：需要 `TENCENTCLOUD_SECRET_ID` 和 `TENCENTCLOUD_SECRET_KEY`
- **AWS Route53** (`route53`)：需要 AWS 访问密钥
- 更多提供商请参考 [Traefik ACME 文档](https://doc.traefik.io/traefik/https/acme/#dnschallenge)

## 快速开始

### 前置要求

- Docker 20.10+
- Docker Compose 2.0+
- 已创建 Traefik Docker 网络（运行 `../../scripts/prepare-network.sh`）
- 配置了 DNS API Token（例如 Cloudflare）

### 步骤 1：配置 DNS API Token

#### Cloudflare 配置示例

1. 登录 Cloudflare 控制台
2. 进入 "My Profile" > "API Tokens"
3. 创建新的 API Token，权限包括：
   - Zone: Zone:Read
   - Zone: DNS:Edit
4. 将 Token 配置到环境变量中：

```bash
export CF_DNS_API_TOKEN=your-cloudflare-api-token
```

### 步骤 2：配置环境变量

在 `acme/.env` 文件中配置所有必需的环境变量，特别是：

- `ACME_EMAIL`：用于 Let's Encrypt 通知的邮箱
- `ACME_PROVIDER`：DNS 提供商（例如 `cloudflare`）
- `CF_DNS_API_TOKEN`：DNS API Token（根据提供商不同，变量名可能不同）

### 步骤 3：启动服务

```bash
docker compose -f traefik/acme/docker-compose.yml up -d
```

### 步骤 4：查看证书申请状态

```bash
# 查看 Traefik 日志
docker logs -f traefik

# 查看证书文件
ls -la ../../ssl/acme.json
```

## 配置说明

### ACME 证书解析器配置

此配置使用 DNS Challenge 方式申请证书，主要配置包括：

```yaml
- "--certificatesresolvers.le.acme.email=${ACME_EMAIL}"
- "--certificatesresolvers.le.acme.storage=/data/ssl/acme.json"
- "--certificatesresolvers.le.acme.dnsChallenge.resolvers=1.1.1.1:53,8.8.8.8:53"
- "--certificatesresolvers.le.acme.dnsChallenge.provider=${ACME_PROVIDER}"
- "--certificatesresolvers.le.acme.dnsChallenge.propagation.delayBeforeChecks=30"
```

### 证书存储

证书数据存储在 `../../ssl/acme.json` 文件中，此文件包含：

- 申请的证书
- 私钥
- ACME 账户信息

**重要**：请妥善保管 `acme.json` 文件，不要泄露或丢失。

### 域名配置

在服务标签中配置证书域名：

```yaml
- "traefik.http.routers.traefik-dashboard-secure.tls.certresolver=le"
- "traefik.http.routers.traefik-dashboard-secure.tls.domains[0].main=${DNS_MAIN}"
- "traefik.http.routers.traefik-dashboard-secure.tls.domains[0].sans=${DNS_LIST}"
```

## 使用示例

### 为服务配置 ACME 证书

在服务的 Docker Compose 文件中添加以下标签：

```yaml
labels:
  - "traefik.http.routers.your-service.tls.certresolver=le"
  - "traefik.http.routers.your-service.tls.domains[0].main=example.com"
  - "traefik.http.routers.your-service.tls.domains[0].sans=*.example.com"
```

### 添加多个域名

在环境变量中配置 `DNS_LIST`，使用逗号分隔：

```bash
DNS_LIST=*.example.com,*.test.com,example.com
```

或在服务标签中使用数组语法：

```yaml
- "traefik.http.routers.service.tls.domains[0].main=example.com"
- "traefik.http.routers.service.tls.domains[0].sans=*.example.com,test.com"
```

## 常见问题

### Q: 证书申请失败怎么办？

1. **检查 DNS API Token**：
   - 确认 Token 是否正确
   - 确认 Token 是否有足够的权限

2. **检查域名 DNS 解析**：
   - 确认域名 DNS 解析正常
   - 确认 DNS 提供商配置正确

3. **查看 Traefik 日志**：
   ```bash
   docker logs -f traefik
   ```
   查找 ACME 相关的错误信息

4. **检查防火墙**：
   - 确认防火墙允许 DNS 查询
   - 确认可以访问 DNS 提供商的 API

### Q: 证书申请需要多长时间？

- 首次申请通常需要 1-3 分钟
- 证书续期通常在后台自动进行
- 如果申请失败，Traefik 会定期重试

### Q: 如何查看已申请的证书？

```bash
# 查看 acme.json 文件（需要 jq 工具）
cat ../../ssl/acme.json | jq

# 或使用 Traefik API
curl https://traefik.example.com/api/http/routers
```

### Q: 证书存储在哪里？

证书存储在 `../../ssl/acme.json` 文件中。请确保：

- 定期备份此文件
- 不要删除或修改此文件
- 文件权限设置为 600（仅所有者可读写）

### Q: 如何切换到其他 DNS 提供商？

1. 修改 `ACME_PROVIDER` 环境变量
2. 配置对应的 API Token 环境变量（根据提供商不同，变量名可能不同）
3. 重启服务

### Q: 可以使用 Let's Encrypt 测试环境吗？

可以，在配置中添加：

```yaml
- "--certificatesresolvers.le.acme.caserver=https://acme-staging-v02.api.letsencrypt.org/directory"
```

**注意**：测试环境颁发的证书不受浏览器信任，仅用于测试。

## 相关资源

- [Traefik ACME 配置文档](https://doc.traefik.io/traefik/https/acme/)
- [Let's Encrypt 官方文档](https://letsencrypt.org/)
- [Cloudflare API Token 文档](https://developers.cloudflare.com/api/tokens/)
