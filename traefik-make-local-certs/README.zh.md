# 本地证书生成工具

[English](README.md) | [中文](README.zh.md)

这是一个使用 certs-maker 容器生成自签名证书的工具，用于测试环境。

## 功能特性

- ✅ **快速生成证书**：一键生成自签名证书
- ✅ **支持通配符域名**：支持 `*.example.com` 通配符域名
- ✅ **多域名支持**：支持多个域名和子域名
- ✅ **PEM 格式**：生成标准的 PEM 格式证书文件

## 环境变量配置

在使用此工具之前，需要在 `traefik-make-local-certs/.env` 文件中配置以下环境变量：

```bash
# 证书域名配置
CERT_DNS=example.com,*.example.com
```

## 快速开始

### 前置要求

- Docker 20.10+
- Docker Compose 2.0+

### 步骤 1：配置域名

在 `traefik-make-local-certs/.env` 中配置要生成的证书域名：

```bash
CERT_DNS=example.com,*.example.com
```

> 提示：可以配置多个域名，使用逗号分隔，例如：`CERT_DNS=example.com,*.example.com,test.com,*.test.com`

### 步骤 2：生成证书

运行证书生成工具：

```bash
docker compose -f traefik-make-local-certs/docker-compose.yml up
docker compose -f traefik-make-local-certs/docker-compose.yml down --remove-orphans
```

### 步骤 3：查看生成的证书

生成的证书文件会保存在 `../../ssl/` 目录下：

```bash
ls -la ../../ssl/
```

证书文件格式：
- 证书文件：`域名.pem.crt`
- 私钥文件：`域名.pem.key`

例如，如果配置了 `CERT_DNS=example.com,*.example.com`，会生成：
- `example.com.pem.crt`
- `example.com.pem.key`

## 配置说明

### Docker Compose 配置

此工具使用 `soulteary/certs-maker` 容器生成证书：

```yaml
services:
  certs-maker:
    image: soulteary/certs-maker:v3.8.0
    environment:
      - CERT_DNS=${CERT_DNS}
    volumes:
      - ../../ssl:/ssl
```

### 证书存储位置

证书文件保存在 `../../ssl/` 目录下，与 Traefik 配置共享同一目录。

### 证书格式

生成的证书为 PEM 格式：
- 证书文件：`.pem.crt`
- 私钥文件：`.pem.key`

## 使用示例

### 生成单个域名证书

```bash
# 配置 .env
CERT_DNS=example.com

# 生成证书
docker compose -f traefik-make-local-certs/docker-compose.yml up
docker compose -f traefik-make-local-certs/docker-compose.yml down --remove-orphans
```

### 生成通配符域名证书

```bash
# 配置 .env
CERT_DNS=*.example.com

# 生成证书
docker compose -f traefik-make-local-certs/docker-compose.yml up
docker compose -f traefik-make-local-certs/docker-compose.yml down --remove-orphans
```

### 生成多个域名证书

```bash
# 配置 .env
CERT_DNS=example.com,*.example.com,test.com

# 生成证书
docker compose -f traefik-make-local-certs/docker-compose.yml up
docker compose -f traefik-make-local-certs/docker-compose.yml down --remove-orphans
```

## 常见问题

### Q: 证书生成失败？

1. **检查域名格式**：
   - 确保域名格式正确
   - 通配符域名使用 `*.example.com` 格式

2. **检查目录权限**：
   - 确保 `../../ssl/` 目录存在
   - 确保有写入权限

3. **查看容器日志**：
   ```bash
   docker compose -f traefik-make-local-certs/docker-compose.yml logs
   ```

### Q: 如何重新生成证书？

直接运行生成命令即可，会覆盖现有证书：

```bash
docker compose -f traefik-make-local-certs/docker-compose.yml up
docker compose -f traefik-make-local-certs/docker-compose.yml down --remove-orphans
```

### Q: 证书有效期是多久？

默认生成的证书有效期为 365 天。如果需要自定义有效期，需要修改 certs-maker 的配置。

### Q: 生成的证书可以在生产环境使用吗？

**不建议**。自签名证书不受浏览器信任，仅适用于测试和开发环境。生产环境应使用：
- Let's Encrypt 等免费证书服务（参考 `../../traefik/acme/`）
- 商业证书
- 企业内网 CA 签发的证书

### Q: 如何查看证书信息？

使用 OpenSSL 查看证书信息：

```bash
# 查看证书信息
openssl x509 -in ../../ssl/example.com.pem.crt -text -noout

# 查看证书有效期
openssl x509 -in ../../ssl/example.com.pem.crt -noout -dates
```

### Q: 证书文件应该放在哪里？

证书文件会自动保存在 `../../ssl/` 目录下，Traefik 配置会自动加载此目录中的证书。

## 相关资源

- [certs-maker 项目](https://github.com/soulteary/certs-maker)
- [Traefik 本地证书配置](../traefik/local-certs/)
- [OpenSSL 文档](https://www.openssl.org/docs/)
