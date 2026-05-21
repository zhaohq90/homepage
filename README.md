# Homepage 服务架构

## 设计原则

每个目录是一个独立的服务单元，具备以下特点：

- **独立启停**：各服务可单独启动/停止，互不影响
- **无依赖**：服务间通过网络通信（宿主机端口），不依赖 Docker 网络
- **统一入口**：Caddy 作为所有服务的反向代理和 HTTPS 终结点

## 目录结构

```
homepage/
├── caddy/           # 反向代理服务（统一入口）
│   ├── Caddyfile
│   ├── docker-compose.yml
│   ├── run.sh
│   └── sites/       # 域名配置（每个域名一个文件）
│       ├── note.caddyfile
│       └── home.caddyfile
├── flatnotes/       # Flatnotes 笔记服务
├── homepage/        # Homepage 仪表盘服务
└── ...
```

## Caddy 反向代理

### 配置结构

采用多文件结构管理域名，避免误操作：

```
caddy/
├── Caddyfile          # 主配置，导入 sites/*.caddyfile
└── sites/
    ├── note.caddyfile # note.akali.xyz 配置
    └── home.caddyfile # home.akali.xyz 配置
```

新增域名时只需在 `sites/` 目录下创建新文件，无需修改其他配置。

### 已配置域名

| 域名 | 转发端口 | 服务 |
|------|----------|------|
| note.akali.xyz | 8080 | Flatnotes |
| home.akali.xyz | 3000 | Homepage |

### 宿主机访问

容器通过 `host.docker.internal` 访问宿主机端口：

```yaml
extra_hosts:
  - "host.docker.internal:host-gateway"
```

```caddy
reverse_proxy host.docker.internal:8080
```

### 常用命令

```bash
# 重载配置（不中断服务）
cd /data/homepage/caddy && docker compose exec caddy caddy reload --config /etc/caddy/Caddyfile

# 查看日志
docker compose -f /data/homepage/caddy/docker-compose.yml logs -f
```

## 添加新服务

1. 创建独立目录（如 `myservice/`）
2. 编写 `docker-compose.yml`，暴露端口到宿主机
3. 编写 `run.sh` 启动脚本
4. 在 `caddy/sites/` 下创建域名配置文件
5. 重载 Caddy 配置