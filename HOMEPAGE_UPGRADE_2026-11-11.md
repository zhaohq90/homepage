# Homepage 服务升级记录

- 升级日期：2026-11-11
- 升级时间：16:21:48 ～ 16:21:52（UTC+08:00）
- 服务：`homepage`（服务仪表盘）
- 版本：`v1.13.1` → `v2.7.0`
- 升级范围：仅 `homepage` 容器，其他容器和宿主机进程未操作

## 1. 升级目标

将 Homepage 从官方 `v1.13.1` 升级到最新稳定版 `v2.7.0`，保持现有配置、端口、挂载和 Docker 集成不变。

## 2. 升级前状态

| 项目 | 值 |
|---|---|
| 容器名 | `homepage` |
| 容器状态 | `Up 5 months (healthy)` |
| 本地镜像标签 | `homepage:local` |
| 实际镜像版本 | `v1.13.1` |
| 旧镜像 ID | `sha256:d3ab993a116ddb4965aa2762af3ac1fb484f6ad853cf785705e6cc1e0aca33d8` |
| 端口 | `0.0.0.0:3000 -> 3000/tcp` |
| 配置挂载 | `/data/homepage/homepage/config -> /app/config` |
| Docker Socket | `/var/run/docker.sock -> /var/run/docker.sock`（只读） |
| 环境变量 | `HOMEPAGE_ALLOWED_HOSTS=*` |
| 重启策略 | `unless-stopped` |
| 启动方式 | `/data/homepage/homepage/run.sh` 中的 `docker run` |
| 配置 git 状态 | 工作区干净 |

升级前运行的容器：

```text
homepage    Up 5 months (healthy)
alist       Up 5 months
caddy       Up 5 months
flatnotes   Up 5 months (healthy)
postgres    Up 5 months
redis       Up 5 months
```

宿主机 Java 进程：

```text
PID 2569749
/usr/bin/java -Xms512m -Xmx512m -jar /root/projects/greenwich/spring-boot-mybatis-hikaricp/target/green.jar --server.port=8081 --spring.profiles.active=hk2
```

## 3. 变更内容

### 3.1 镜像

| 项目 | 值 |
|---|---|
| 新镜像 | `ghcr.io/gethomepage/homepage:v2.7.0` |
| 镜像标签版本 | `v2.7.0` |
| 镜像创建时间 | `2026-10-23T15:10:48.129Z` |
| 镜像 revision | `2e5f10134ae3961bb936d3e7c441f9a1f4a4bf4f` |
| Manifest digest | `sha256:19c5c09184458a41b7b5915e71463a39f36cd33540f41bdbed008791b8182d5f` |
| 新镜像 ID | `sha256:0193309878fc07a9016fc8bb36a54206bc1b1d17226049d7e0250bceef2d4078` |
| 基础环境 | Node.js `24.22.1`，Next.js `16.4.1` |

本地标签调整：

```text
homepage:local          -> 新镜像 0193309878fc（v2.7.0）
homepage:local-v1.13.1  -> 旧镜像 d3ab993a116d（保留用于回滚）
```

### 3.2 容器

| 项目 | 值 |
|---|---|
| 新容器 ID | `09f36543d3a036a65d9c39c07c230f5175fa1b912fd8b9de5aa205add15d554d` |
| 启动时间 | `2026-11-11T16:21:48+08:00` |
| 健康状态 | `healthy` |
| 镜像版本标签 | `v2.7.0` |
| 端口 | `0.0.0.0:3000 -> 3000/tcp` |
| 配置挂载 | `/data/homepage/homepage/config -> /app/config` |
| Docker Socket | `/var/run/docker.sock -> /var/run/docker.sock`（只读） |
| 环境变量 | `HOMEPAGE_ALLOWED_HOSTS=*` |
| 重启策略 | `unless-stopped` |

容器运行参数与升级前一致，仅镜像版本发生变化。

### 3.3 配置文件

配置文件未修改：

- `homepage/config/settings.yaml`
- `homepage/config/services.yaml`
- `homepage/config/bookmarks.yaml`
- `homepage/config/widgets.yaml`
- `homepage/config/docker.yaml`
- `homepage/config/kubernetes.yaml`
- `homepage/config/proxmox.yaml`
- `homepage/config/custom.js`
- `homepage/config/custom.css`

v2.0.0 的破坏性变更只有新增可选登录认证，默认关闭。本次未启用认证，现有配置键在 v2.7.0 中仍然有效。

### 3.4 备份

| 项目 | 路径 |
|---|---|
| 配置备份 | `/root/homepage-config-backup-2026-11-11.tar.gz`（4.7 KB） |
| 旧镜像回滚标签 | `homepage:local-v1.13.1` |
| 升级前容器配置快照 | `/tmp/homepage-container-before-upgrade.json` |

## 4. 执行步骤

```bash
# 1. 备份配置
cd /data/homepage
tar czf /root/homepage-config-backup-2026-11-11.tar.gz homepage/config

# 2. 保留旧镜像回滚标签
docker tag homepage:local homepage:local-v1.13.1

# 3. 拉取新镜像
docker pull ghcr.io/gethomepage/homepage:v2.7.0

# 4. 确认镜像版本
docker image inspect ghcr.io/gethomepage/homepage:v2.7.0 \
  --format '{{index .Config.Labels "org.opencontainers.image.version"}}'
# 输出：v2.7.0

# 5. 切换本地标签
docker tag ghcr.io/gethomepage/homepage:v2.7.0 homepage:local

# 6. 仅重建 homepage 容器
/data/homepage/homepage/run.sh restart
```

`run.sh restart` 的实际动作：

```text
docker stop homepage
docker rm homepage
docker run -d --name homepage --restart unless-stopped \
  -p 3000:3000 \
  -v /data/homepage/homepage/config:/app/config \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  -e HOMEPAGE_ALLOWED_HOSTS="*" \
  homepage:local
```

该脚本只操作名为 `homepage` 的容器，没有执行 `docker compose down`、全量重启、`docker prune` 或源码构建。

## 5. 验证结果

### 5.1 容器与镜像

| 检查项 | 结果 |
|---|---|
| 容器状态 | `Up (healthy)` |
| 镜像版本标签 | `v2.7.0` |
| 健康检查 | `healthy` |
| 重启策略 | `unless-stopped` |

### 5.2 应用接口

| 检查项 | 请求 | 结果 |
|---|---|---|
| 健康检查 | `GET /api/healthcheck` | `200` |
| 首页 | `GET /` | `200`，HTML 66,012 字节 |
| 服务列表 | `GET /api/services` | `200`，1,898 字节 |
| 书签列表 | `GET /api/bookmarks` | `200`，459 字节 |
| 组件配置 | `GET /api/widgets` | `200`，162 字节 |
| 配置哈希 | `GET /api/hash` | `200` |
| CPU 资源 | `GET /api/widgets/resources?type=cpu` | `200` |
| 内存资源 | `GET /api/widgets/resources?type=memory` | `200` |
| 磁盘资源 | `GET /api/widgets/resources?type=disk&target=/` | `200` |
| 运行时间 | `GET /api/widgets/resources?type=uptime` | `200` |

首页 HTML 中包含以下服务分组和条目：

```text
服务仪表板
Caddy
Alist
Flatnotes
MySQL 备份
Cloud Mail
Telegram 下载器
```

### 5.3 Docker 集成

`GET /api/docker/statuses?server=my-docker` 返回 `200`：

```json
{
  "statuses": {
    "homepage": {"status": "running", "health": "healthy"},
    "alist": {"status": "running"},
    "caddy": {"status": "running"},
    "flatnotes": {"status": "running", "health": "healthy"}
  }
}
```

Docker Socket 只读挂载正常，仪表盘可以继续读取容器状态。

### 5.4 反向代理

| 检查项 | 结果 |
|---|---|
| Caddy 容器 | `Up 5 months`，未重启 |
| `https://home.akali.xyz/` | `401`，`server: Caddy`，`www-authenticate: Basic realm="restricted"` |

Caddy 的 Basic Auth 正常工作。由于没有使用登录凭据，本次未做带认证的 Caddy 到 Homepage 端到端页面访问；已验证 Caddy 容器运行正常、本机 `3000` 端口应用正常，反向代理配置未修改。

### 5.5 其他服务未受影响

| 服务 | 升级后状态 |
|---|---|
| `alist` | `Up 5 months` |
| `caddy` | `Up 5 months` |
| `flatnotes` | `Up 5 months (healthy)` |
| `postgres` | `Up 5 months` |
| `redis` | `Up 5 months` |
| Java 进程 | PID `2569749`，运行时长 `41-22:26:14`，未重启 |

### 5.6 日志

升级后容器日志：

```text
Skipping ownership changes for /app/config
Skipping ownership changes for /app/config/logs
/app/.next already owned by correct UID/GID or running as root, skipping chown
▲ Next.js 16.4.1
- Local:         http://[::1]:3000
- Network:       http://[::]:3000
✓ Ready in 0ms
✓ Running next.config took 3ms
```

未出现新的错误日志。`config/logs/homepage.log` 中仍有 2026-08-14 的外部探测记录（`169.254.169.254`、`debug`、`actuator`、`.aws` 等），属于升级前已存在的问题。

### 5.7 验证限制

当前环境没有可用的浏览器或无头浏览器，因此未做截图级页面渲染验证。已通过服务端 HTML、各 API 接口、Docker 状态接口和健康检查完成功能验证。

## 6. 回滚方案

如需回滚到 `v1.13.1`：

```bash
docker tag homepage:local-v1.13.1 homepage:local
/data/homepage/homepage/run.sh restart
```

如果配置也需要恢复：

```bash
tar xzf /root/homepage-config-backup-2026-11-11.tar.gz -C /data/homepage
```

## 7. 后续建议

1. `run.sh` 固定使用 `:latest`，版本不可复现。建议后续改为固定版本标签，例如 `ghcr.io/gethomepage/homepage:v2.7.0`。
2. `run.sh rebuild` 会从 `/root/projects/homepage` 构建旧源码，并覆盖 `homepage:local` 标签。当前部署不使用源码构建，请避免执行 `build` 或 `rebuild`。
3. `3000` 端口当前发布在 `0.0.0.0`，且 `HOMEPAGE_ALLOWED_HOSTS=*`，可以绕过 Caddy 直接访问 Homepage。本次升级未改变该暴露面，建议后续单独评估网络层限制或启用 v2 自带认证。
4. 磁盘使用率约 84%，当前剩余约 7.9 GB。旧镜像仍保留用于回滚，确认稳定后可按需清理 `homepage:local-v1.13.1`。
