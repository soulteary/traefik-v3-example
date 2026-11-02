# OwlMail 0.13.0 与 Traefik

[English](README.md) | [中文](README.zh.md)

本示例固定正式 OwlMail 0.13.0：SMTP 捕获开发邮件，Traefik 通过 HTTPS 提供 Web 界面。原生 REST 使用 `/api/v1`；可选 MailDev `/api` facade 不是 Socket.IO，也不保证所有客户端直接替换。见[当前兼容指南](https://github.com/soulteary/owlmail/blob/v0.13.0/docs/zh-CN/Comparison-and-Migration.md)。

## 配置与启动

编辑同目录 `.env`：

```sh
SERVICE_NAME=owlmail
SERVICE_PREFIX=owlmail
SERVICE_DOMAIN=mail.example.com
SERVICE_PORT=1080
DOCKER_IMAGE=ghcr.io/soulteary/owlmail:0.13.0
SMTP_PORT=1025
SMTP_HOST=0.0.0.0
DATA_DIR=./owlmail-data
```

先创建外部 `traefik` 网络、启动选定的 Traefik 配置，再从仓库根执行：

```sh
docker compose --env-file traefik-app-examples/owlmail/.env -f traefik-app-examples/owlmail/docker-compose.yml up -d
```

访问 `https://mail.example.com`，向配置的 SMTP 端口发送测试邮件。当前 SMTP 发布在全部宿主接口；共享或公网使用前通过防火墙/私网限制，或将宿主侧绑定 127.0.0.1。HTTPS 与 Web Basic Auth 不能保护 SMTP。未明确配置时保持出站转发关闭。

## 存储、配置与兼容

`${DATA_DIR}` 完整挂载到镜像实际使用的 `/app/mail`；健康检查使用 `owlmail healthcheck` 读取同一启动环境。目录须允许镜像 owlmail 用户读写。Compose `.env` 只用于插值，不会自动传入容器；启用 Web Basic Auth、浏览器来源或出站 SMTP 选项时须显式写入服务的 `environment`，详见[配置参考](https://github.com/soulteary/owlmail/blob/v0.13.0/docs/zh-CN/Configuration-Reference.md)，不要用 `*` 取消来源检查。

外部 HTTPS 与后端 origin 不同时，显式设置 `OWLMAIL_WEB_EXTERNAL_URL=https://mail.example.com`，按需添加最小允许来源。原生 `/api/v1/emails` 可检查捕获；SMTP-only、只读 MCP 与可选 MailDev facade 保留各自配置边界。

## 从 0.3.0 升级与回退

停止新 SMTP 流量和旧进程，备份实际邮件目录、外部存储、配置与原镜像摘要。旧示例挂载 `/data/mails` 却未启用该邮件目录：先检查原有效配置，替换前复制实际容器可写层邮件；仅新增正确挂载不会恢复已丢失或原本仅在内存中的邮件。

先在隔离数据副本上演练，并禁用真实下游地址。检查历史邮件/附件、新 SMTP 捕获、健康/就绪、HTTPS UI/API 与容器重建。持久 Relay 恢复可能继续待发送任务，投递仍为至少一次，中断窗口可能重复。阅读[0.13.0 升级及回退说明](https://github.com/soulteary/owlmail/blob/v0.13.0/docs/zh-CN/Release-0.13.0.md)。

回退先停新版，用旧镜像及对应升级前完整备份、外部状态恢复；重新启用出站前核对下游接受记录，另存并核对新增捕获邮件。两版本不得共享可写目录。常规清理用相同 env/file 参数执行 `docker compose down`，不删除数据或卷。
