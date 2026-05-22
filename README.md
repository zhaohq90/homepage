# Homepage 服务架构

统一的自托管服务部署方案，采用 Caddy 作为 HTTPS 入口，各服务独立运行。

## 设计原则

- **独立启停**：各服务单独启动/停止，互不影响
- **无依赖**：服务监听宿主机端口，不依赖 Docker 网络
- **统一入口**：Caddy 统一处理 HTTPS 和 SSL 证书

---

## 目录结构

```
/data/homepage/
├── caddy/               # 反向代理（统一入口）
│   ├── Caddyfile
│   ├── docker-compose.yml
│   └── sites/           # 域名配置
├── homepage/            # 服务仪表盘
│   ├── config/
│   └── run.sh
├── flatnotes/           # 笔记服务
│   ├── data/
│   ├── .env
│   └── run.sh
├── alist/               # 文件列表
│   ├── data/
│   └── run.sh
├── README.md            # 架构总览
├── caddy.md             # Caddy 详细文档
├── homepage.md          # Homepage 详细文档
├── flatnotes.md         # Flatnotes 详细文档
└── alist.md             # Alist 详细文档
```

---

## 网络架构

### 核心规则

```
┌─────────────────────────────────────────────────────────────────┐
│                         强制规则                                  │
│                                                                  │
│  1. 服务必须绑定 0.0.0.0（不能绑定 127.0.0.1）                     │
│  2. Caddy 使用 host.docker.internal 转发到宿主机端口              │
│  3. 服务不加入 caddy 网络，保持独立                               │
│                                                                  │
│  原因：host.docker.internal = 172.17.0.1 (Docker网关)            │
│        127.0.0.1 只允许宿主机本地访问，容器无法连接                 │
└─────────────────────────────────────────────────────────────────┘
```

### 架构图

```
┌─────────────────────────────────────────────────────────────────────┐
│                          VPS (公网)                                  │
│                                                                      │
│   ┌──────────────┐                                              │
│   │   Internet   │                                              │
│   │   HTTPS:443  │                                              │
│   └──────┬───────┘                                              │
│          │                                                         │
│          ▼                                                         │
│   ┌──────────────┐      host.docker.internal      ┌──────────────┐│
│   │    Caddy     │────────────────────────────────│ 172.17.0.1   ││
│   │  (Docker)    │                                │ Docker 网关  ││
│   │   自动 SSL   │                                └──────┬───────┘│
│   └──────┬───────┘                                       │        │
│          │                                               │        │
│          │ 转发规则                                      │        │
│          ├───────────────────────────────────────────────┤        │
│          │                                               │        │
│          ▼                                               ▼        │
│   ┌──────────────────┐                      ┌──────────────────┐│
│   │home.akali.xyz    │──► 0.0.0.0:3000     │ Homepage (仪表盘)││
│   └──────────────────┘                      └──────────────────┘│
│   ┌──────────────────┐                      ┌──────────────────┐│
│   │note.akali.xyz    │──► 0.0.0.0:8080     │ Flatnotes (笔记) ││
│   └──────────────────┘                      └──────────────────┘│
│   ┌──────────────────┐                      ┌──────────────────┐│
│   │alist.akali.xyz   │──► 0.0.0.0:5244     │ Alist (文件列表) ││
│   └──────────────────┘                      └──────────────────┘│
│                                                                      │
│   所有服务监听 0.0.0.0:端口，Caddy 通过网关转发                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 已部署服务

| 服务 | 作用 | 目录 | 文档 | 域名 |
|------|------|------|------|------|
| Caddy | 反向代理 / HTTPS 入口 | [caddy/](caddy/) | [caddy.md](caddy.md) | *.akali.xyz |
| Homepage | 服务仪表盘 | [homepage/](homepage/) | [homepage.md](homepage.md) | [home.akali.xyz](https://home.akali.xyz) |
| Flatnotes | Markdown 笔记 | [flatnotes/](flatnotes/) | [flatnotes.md](flatnotes.md) | [note.akali.xyz](https://note.akali.xyz) |
| Alist | 文件列表管理 | [alist/](alist/) | [alist.md](alist.md) | [alist.akali.xyz](https://alist.akali.xyz) |

---

## 添加新服务

1. **创建目录**: `mkdir /data/homepage/<服务名>`
2. **配置端口绑定**: `ports: "端口:端口"` (不加 127.0.0.1)
3. **创建启动脚本**: `run.sh`
4. **添加域名配置**: `caddy/sites/<服务名>.caddyfile`
5. **重载 Caddy**: `docker exec caddy caddy reload`
6. **配置 DNS**: 域名 → VPS IP
7. **创建服务文档**: `<服务名>.md`

---

## 常用命令

```bash
# 查看所有服务状态
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# 测试域名访问
curl -s -o /dev/null -w "%{http_code}" https://home.akali.xyz/
curl -s -o /dev/null -w "%{http_code}" https://note.akali.xyz/

# 重载 Caddy 配置
docker exec caddy caddy reload --config /etc/caddy/Caddyfile
```

---

## 部署记录

- 架构版本: v2
- 最后更新: 2026-05-22