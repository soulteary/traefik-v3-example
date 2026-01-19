# Traefik v3.x 快速上手示例

[English](README.md) | [中文](README.zh.md)

![Traefik v3.x Quick Start Example](.github/assets/banner.jpg)

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
├── scripts/                   # 工具脚本目录
│   └── prepare-network.sh    # 创建 Docker 网络脚本
├── traefik/                   # Traefik 服务配置目录
│   ├── base/                 # 基础配置（需要环境变量）
│   ├── acme/                 # ACME 自动申请证书配置
│   └── local-certs/          # 使用本地证书配置
├── traefik-make-local-certs/  # 证书生成工具
├── traefik-app-examples/     # 应用集成示例目录
│   ├── flare/                # Flare 服务接入示例
│   ├── stargate/             # Stargate Forward Auth 服务示例
│   └── owlmail/              # OwlMail 邮件测试服务示例
├── README.md                  # 本文档（英文）
└── README.zh.md               # 本文档（中文）
```

## 快速开始

### 前置要求

- Docker 20.10+
- Docker Compose 2.0+
- 基本的 Linux/Unix 命令行知识

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

1. **生成自签名证书**：
   - 参考 [证书生成工具文档](traefik-make-local-certs/README.zh.md)

2. **启动 Traefik**：
   - 参考 [本地证书配置文档](traefik/local-certs/README.zh.md)

#### 方式二：使用 ACME 自动申请证书（适合生产环境）

1. **配置 ACME**：
   - 参考 [ACME 配置文档](traefik/acme/README.zh.md)

2. **启动 Traefik**：
   - 参考 [ACME 配置文档](traefik/acme/README.zh.md)

#### 方式三：使用基础配置（需要完整环境变量）

- 参考 [基础配置文档](traefik/base/README.zh.md)

### 步骤 3：访问 Dashboard

启动成功后，访问 Traefik Dashboard：

- HTTPS: `https://traefik.example.com/dashboard/`
- API: `https://traefik.example.com/api/`

> 注意：请将 `traefik.example.com` 替换为你配置的实际域名，并确保 DNS 解析正确。

## 详细文档

### Traefik 配置

- **[基础配置](traefik/base/README.zh.md)**：需要完整的环境变量配置，支持 ACME 和本地证书
- **[ACME 证书配置](traefik/acme/README.zh.md)**：使用 Let's Encrypt 自动申请证书（需要 DNS API Token）
- **[本地证书配置](traefik/local-certs/README.zh.md)**：使用本地自签名证书，适合测试环境

### 工具和示例

- **[证书生成工具](traefik-make-local-certs/README.zh.md)**：使用 certs-maker 容器生成自签名证书
- **[Flare 服务示例](traefik-app-examples/flare/README.zh.md)**：Flare 服务接入 Traefik 的完整示例
- **[Stargate Forward Auth 示例](traefik-app-examples/stargate/README.zh.md)**：Stargate 认证服务集成示例，包含受保护服务演示
- **[OwlMail 邮件测试服务示例](traefik-app-examples/owlmail/README.zh.md)**：OwlMail 邮件测试服务集成示例，支持 SMTP 和 Web 界面

## 相关资源

### 完整使用方法

- [Docker 环境下使用 Traefik 3 的最佳实践：快速上手](https://soulteary.com/2024/08/04/best-practices-for-traefik-3-in-docker-getting-started-quickly.html)

### 相关项目

- [Traefik](https://github.com/traefik/traefik) - 云原生反向代理和负载均衡器
- [certs-maker](https://github.com/soulteary/certs-maker) - 证书生成工具
- [docker-flare](https://github.com/soulteary/docker-flare) - Flare 服务 Docker 镜像
- [Stargate](https://github.com/soulteary/stargate) - 轻量级 Forward Auth 认证服务
- [OwlMail](https://github.com/soulteary/owlmail) - 邮件开发和测试工具，兼容 MailDev

### 官方文档

- [Traefik 官方文档](https://doc.traefik.io/traefik/)
- [Traefik Docker Provider](https://doc.traefik.io/traefik/providers/docker/)
- [Traefik ACME 配置](https://doc.traefik.io/traefik/https/acme/)

## 许可证

详见 [LICENSE](LICENSE) 文件。
