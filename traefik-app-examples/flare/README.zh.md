# Flare 服务接入 Traefik 示例

[English](README.md) | [中文](README.zh.md)

这是一个完整的 Flare 服务接入 Traefik 的示例，展示了如何通过 Docker 标签将服务接入 Traefik 反向代理。

## 功能特性

- ✅ **自动服务发现**：通过 Docker 标签自动发现和配置服务
- ✅ **HTTPS 支持**：自动启用 HTTPS 和 TLS
- ✅ **HTTP 重定向**：自动将 HTTP 请求重定向到 HTTPS
- ✅ **GZIP 压缩**：自动启用响应内容压缩
- ✅ **域名路由**：基于域名进行路由

## 环境变量配置

在使用此配置之前，需要在 `flare/.env` 文件中配置以下环境变量：

```bash
# 服务配置
SERVICE_NAME=flare
SERVICE_PREFIX=flare
SERVICE_DOMAIN=flare.example.com
SERVICE_PORT=5005
DOCKER_IMAGE=soulteary/flare:0.5.1
```

## 快速开始

### 前置要求

- Docker 20.10+
- Docker Compose 2.0+
- Traefik 服务已启动（参考 `../../traefik/`）
- 已创建 Traefik Docker 网络

### 启动服务

```bash
docker compose -f traefik-app-examples/flare/docker-compose.yml up -d
```

### 访问服务

启动成功后，访问 Flare 服务：

- HTTPS: `https://flare.example.com`
- HTTP: `http://flare.example.com`（自动重定向到 HTTPS）

> 注意：请将 `flare.example.com` 替换为你配置的实际域名，并确保 DNS 解析正确。

## 配置说明

### Docker Compose 配置

此配置展示了如何通过 Docker 标签将服务接入 Traefik：

```yaml
labels:
  # 启用 Traefik 服务发现
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

### 关键标签说明

- `traefik.enable=true`：启用 Traefik 服务发现
- `traefik.docker.network=traefik`：指定 Docker 网络
- `traefik.http.routers.*.rule`：路由规则（基于域名、路径等）
- `traefik.http.routers.*.entrypoints`：指定入口点（http/https）
- `traefik.http.routers.*.tls`：启用 TLS
- `traefik.http.services.*.loadbalancer.server.port`：后端服务端口

## 使用示例

### 接入新服务

参考此配置，你可以轻松地将其他服务接入 Traefik：

1. **复制配置结构**：复制 `docker-compose.yml` 文件
2. **修改服务配置**：
   - 修改镜像名称
   - 修改服务端口
   - 修改域名
3. **配置环境变量**：在 `.env` 文件中设置相应的环境变量
4. **启动服务**：使用 `docker compose up -d` 启动

### 自定义路由规则

你可以根据需要修改路由规则：

```yaml
# 基于路径的路由
- "traefik.http.routers.service.rule=Host(`example.com`) && PathPrefix(`/api`)"

# 多个域名
- "traefik.http.routers.service.rule=Host(`example.com`) || Host(`www.example.com`)"

# 基于路径前缀
- "traefik.http.routers.service.rule=PathPrefix(`/app`)"
```

### 添加中间件

你可以添加自定义中间件：

```yaml
# 添加认证中间件
- "traefik.http.routers.service.middlewares=gzip,auth"

# 添加限流中间件
- "traefik.http.routers.service.middlewares=gzip,ratelimit"
```

## 常见问题

### Q: 服务无法访问？

1. **检查服务状态**：
   ```bash
   docker ps | grep flare
   ```

2. **检查 Traefik 日志**：
   ```bash
   docker logs traefik
   ```

3. **检查服务日志**：
   ```bash
   docker logs flare
   ```

4. **确认网络连接**：
   - 确认服务在 `traefik` 网络中
   - 确认域名 DNS 解析正确

### Q: 如何查看 Traefik 路由配置？

访问 Traefik Dashboard：

```bash
https://traefik.example.com/dashboard/
```

在 Dashboard 中可以查看：
- 所有路由配置
- 服务状态
- 中间件配置

### Q: 如何修改服务端口？

1. 修改 `.env` 文件中的 `SERVICE_PORT`
2. 修改 `docker-compose.yml` 中的端口配置
3. 重启服务

### Q: 如何添加多个域名？

在路由规则中使用 `||` 连接多个域名：

```yaml
- "traefik.http.routers.service.rule=Host(`example.com`) || Host(`www.example.com`)"
```

### Q: 如何禁用 HTTPS 重定向？

移除 HTTP 路由配置，只保留 HTTPS 路由：

```yaml
# 移除这些标签
# - "traefik.http.routers.service-http.entrypoints=http"
# - "traefik.http.routers.service-http.middlewares=redir-https"
```

## 相关资源

- [Flare 项目](https://github.com/soulteary/docker-flare)
- [Traefik Docker Provider 文档](https://doc.traefik.io/traefik/providers/docker/)
- [Traefik 路由配置文档](https://doc.traefik.io/traefik/routing/routers/)
