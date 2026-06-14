# Traefik ACME 证书配置（Cloudflare DNS）

[English](README.md) | [中文](README.zh.md)

这是一套面向生产环境的 Traefik 配置，通过 **Cloudflare DNS（cloudflare）** 的 DNS Challenge，自动从 Let's Encrypt 申请并续签 SSL 证书。

设计目标很简单：新服务上线不需要修改 Traefik 配置。Traefik 只负责入口（服务发现、路由转发、TLS 管理），而每个业务服务通过 Docker 标签自己声明域名、路由规则和证书需求。

> 参考文章：[Traefik Cloudflare 使用方案：自动证书与服务接入](https://soulteary.com/tags/traefik.html)

## 功能特性

- ✅ **自动证书申请**：通过 Cloudflare DNS Challenge 自动申请 Let's Encrypt 证书
- ✅ **证书自动续期**：证书到期前自动续签，无需人工维护
- ✅ **支持通配符证书**：DNS Challenge 支持 `*.example.com` 通配符域名
- ✅ **多域名支持**：支持多个主域名和子域名
- ✅ **HTTP/3 支持**：启用 HTTP/3 (QUIC) 协议
- ✅ **Dashboard 界面**：内置 Traefik Dashboard 可视化界面
- ✅ **入口与业务解耦**：新服务自动接入，无需改动 Traefik 配置

## 为什么选择 DNS Challenge + Cloudflare API Token

- **DNS Challenge 支持通配符证书**：申请 `*.yourdomain.ltd` 之后，`api.yourdomain.ltd`、`grafana.yourdomain.ltd`、`harbor.yourdomain.ltd` 等子域名都可以直接通过 HTTPS 访问，新增服务无需重新申请证书。同时它不依赖公网 80 端口，也可用于内网服务。
- **最小权限 API Token**：自动签发证书需要修改 DNS 记录的权限。这里不建议使用 Global API Key，而是创建一个仅对目标 Zone 拥有 `Zone:Read` 和 `DNS:Edit` 权限的独立 API Token。即使 Token 泄露，影响范围也仅限于授权的域名。

## 前置要求

- Docker 20.10+ 和 Docker Compose 2.0+
- 已创建 Traefik 外部 Docker 网络（`docker network create traefik`）
- 域名已托管在 Cloudflare，并解析到服务器，安全组开放 80、443 端口
- 一个具备 DNS 编辑权限的 Cloudflare API Token

## 步骤 1：准备 Cloudflare API Token

打开 Cloudflare 控制台，为 Traefik 创建一个最小权限的 API Token：

1. 进入 **My Profile → API Tokens → Create Token**
2. 选择 **Create Custom Token**，配置权限：
   - **Zone → Zone → Read**
   - **Zone → DNS → Edit**
3. 在 **Zone Resources** 中限定到目标域名所在的 Zone（不建议选 All zones）
4. 创建后保存好生成的 Token（只显示一次）

相比 Global API Key，自定义 API Token 可以精确限定权限和作用域，即使泄露也只影响指定域名的 DNS 记录。

## 步骤 2：创建 Docker 网络

```bash
docker network create traefik
```

之后任何想通过 Traefik 提供服务的业务容器，只需加入这个网络即可被自动发现，无需额外暴露端口。

## 步骤 3：配置环境变量

在 `.env` 文件中配置以下变量：

```bash
# 服务配置
SERVICE_NAME=traefik
DOCKER_IMAGE=ghcr.io/traefik/traefik:v3.7.5
SERVICE_HTTP_PORT=80
SERVICE_HTTPS_PORT=443
SERVICE_DOMAIN=traefik.example.com

# DNS 配置（用于 ACME 证书）
DNS_MAIN=example.com
DNS_LIST=*.example.com

# ACME 配置
ACME_EMAIL=your-email@example.com
ACME_PROVIDER=cloudflare

# Cloudflare DNS API
CF_DNS_API_TOKEN=your-cloudflare-api-token

# 可选：时区
TZ=Asia/Shanghai
```

关键变量说明：

- `ACME_EMAIL`：用于 Let's Encrypt 通知的邮箱
- `ACME_PROVIDER`：DNS 提供商，Cloudflare 填 `cloudflare`
- `CF_DNS_API_TOKEN`：步骤 1 创建的 Cloudflare API Token
- `DNS_MAIN` / `DNS_LIST`：证书的主域名与通配符（SANs）

> 提示：如果你使用的是 Cloudflare 旧版 Global API Key，则需改用 `CF_API_EMAIL` + `CF_API_KEY` 两个变量。推荐使用 API Token（`CF_DNS_API_TOKEN`），权限更可控。

## 步骤 4：启动服务

```bash
docker compose up -d
```

## 步骤 5：查看证书状态

```bash
# 查看 Traefik 日志
docker logs -f traefik

# 检查容器健康状态
docker inspect traefik --format='{{json .State.Health}}'

# 查看证书文件
ls -la ./ssl/acme.json
```

服务正常运行后，访问 `https://traefik.example.com` 即可通过 HTTPS 打开 Dashboard。

## 支持的 DNS 提供商

此配置默认使用 Cloudflare（`cloudflare`）。Traefik 也支持其他多种提供商：

- **Cloudflare** (`cloudflare`)：需要 `CF_DNS_API_TOKEN`
- **Aliyun** (`alidns`)：需要 `ALICLOUD_ACCESS_KEY` 和 `ALICLOUD_SECRET_KEY`
- **Tencent Cloud** (`tencentcloud`)：需要 `TENCENTCLOUD_SECRET_ID` 和 `TENCENTCLOUD_SECRET_KEY`
- **AWS Route53** (`route53`)：需要 AWS 访问密钥
- 更多提供商请参考 [Traefik ACME 文档](https://doc.traefik.io/traefik/https/acme/#dnschallenge)

切换提供商时，修改 `ACME_PROVIDER`、配置对应的密钥变量，然后重启服务即可。

## 配置说明

### ACME 证书解析器

解析器命名为 `cloudflare`，使用 DNS Challenge 方式：

```yaml
- "--certificatesresolvers.cloudflare.acme.email=${ACME_EMAIL}"
- "--certificatesresolvers.cloudflare.acme.storage=/data/ssl/acme.json"
- "--certificatesresolvers.cloudflare.acme.dnsChallenge.resolvers=1.1.1.1:53,8.8.8.8:53"
- "--certificatesresolvers.cloudflare.acme.dnsChallenge.provider=${ACME_PROVIDER}"
- "--certificatesresolvers.cloudflare.acme.dnsChallenge.propagation.delayBeforeChecks=30"
```

`delayBeforeChecks` 用于在校验前等待 DNS 记录生效；这里的公共 `resolvers` 默认填了 Cloudflare 的 `1.1.1.1`，用于校验 TXT 记录。

### 证书存储

证书数据存储在 `./ssl/acme.json`（在容器内挂载为 `/data/ssl/acme.json`），其中包含已申请的证书、私钥和 ACME 账户信息。

**重要**：请妥善保管 `acme.json`，定期备份，并将其权限设置为 `600`。

### TLS 选项

`config/tls.toml` 通过 file provider 加载，用于固定最低 TLS 版本和加密套件：

```toml
[tls.options.default]
minVersion = "VersionTLS12"
```

### Dashboard 域名

Dashboard 的证书域名来自 `DNS_MAIN` 和 `DNS_LIST`：

```yaml
- "traefik.http.routers.traefik-dashboard-secure.tls.certresolver=cloudflare"
- "traefik.http.routers.traefik-dashboard-secure.tls.domains[0].main=${DNS_MAIN}"
- "traefik.http.routers.traefik-dashboard-secure.tls.domains[0].sans=${DNS_LIST}"
```

## 接入业务服务

业务服务自己声明域名和证书，不需要改动 Traefik 配置——只要加入 `traefik` 网络并添加标签即可：

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

      # 路由
      - "traefik.http.routers.whoami.rule=Host(`whoami.yourdomain.ltd`)"
      - "traefik.http.routers.whoami.entrypoints=https"
      - "traefik.http.routers.whoami.tls=true"
      - "traefik.http.routers.whoami.tls.certresolver=cloudflare"

      # 通配符证书
      - "traefik.http.routers.whoami.tls.domains[0].main=yourdomain.ltd"
      - "traefik.http.routers.whoami.tls.domains[0].sans=*.yourdomain.ltd"

      - "traefik.http.services.whoami.loadbalancer.server.port=80"
    networks:
      - traefik

networks:
  traefik:
    external: true
```

执行 `docker compose up -d`，然后访问 `https://whoami.yourdomain.ltd`，即可看到使用有效证书的服务页面。

## 常见问题

### 证书申请失败怎么办？

1. **API Token**：确认 `CF_DNS_API_TOKEN` 正确，且 Token 具备目标 Zone 的 `Zone:Read` 与 `DNS:Edit` 权限。
2. **域名归属**：确认域名由 Cloudflare DNS 托管，且 Token 的 Zone Resources 覆盖该域名。
3. **代理状态**：DNS Challenge 仅修改 TXT 记录，不受橙云/灰云影响；但解析记录建议指向正确的源站地址。
4. **日志**：执行 `docker logs -f traefik`，查找 ACME 相关错误。
5. **网络**：确认服务器可以访问 Cloudflare API（`api.cloudflare.com`）和公共 DNS 解析器。

### 证书申请需要多长时间？

- 首次申请通常需要 1-3 分钟（含 DNS 生效时间，Cloudflare 通常很快）。
- 续期在后台自动进行。
- 申请失败时，Traefik 会定期重试。

### 如何查看已申请的证书？

```bash
# 查看 acme.json 文件（需要 jq 工具）
cat ./ssl/acme.json | jq

# 或使用 Traefik API
curl https://traefik.example.com/api/http/routers
```

### 可以使用 Let's Encrypt 测试环境吗？

可以，在解析器配置中添加 CA 服务器：

```yaml
- "--certificatesresolvers.cloudflare.acme.caserver=https://acme-staging-v02.api.letsencrypt.org/directory"
```

**注意**：测试环境颁发的证书不受浏览器信任，仅用于测试。

## 相关资源

- [Traefik ACME 配置文档](https://doc.traefik.io/traefik/https/acme/)
- [Let's Encrypt 官方文档](https://letsencrypt.org/)
- [Cloudflare API Token 文档](https://developers.cloudflare.com/api/tokens/)
- [Cloudflare 创建 API Token 指南](https://developers.cloudflare.com/fundamentals/api/get-started/create-token/)
