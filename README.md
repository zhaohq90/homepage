# Homepage 服务架构

## 设计原则

每个目录是一个独立的服务单元，具备以下特点：

- **独立启停**：各服务可单独启动/停止，互不影响
- **无依赖**：服务间通过网络通信（宿主机端口），不依赖 Docker 网络
- **统一入口**：Caddy 作为所有服务的反向代理和 HTTPS 终结点

## 目录结构

```
/data/homepage/
├── caddy/           # 反向代理服务（统一入口）
│   ├── Caddyfile        # 主配置
│   ├── docker-compose.yml
│   └── sites/           # 域名配置（每个域名一个文件）
│       ├── home.caddyfile   # home.akali.xyz
│       └── note.caddyfile   # note.akali.xyz
├── flatnotes/       # Flatnotes 笔记服务
│   ├── docker-compose.yml
│   ├── .env
│   ├── data/
│   └── run.sh
├── homepage/        # Homepage 仪表盘服务
│   ├── config/
│   └── run.sh
└── README.md
```

---

## 网络架构

### 核心原则

```
┌─────────────────────────────────────────────────────────────────┐
│                         重要规则（强制）                          │
│                                                                  │
│  1. 服务必须绑定 0.0.0.0（所有接口），不能绑定 127.0.0.1          │
│  2. Caddy 必须使用 host.docker.internal 转发到宿主机端口          │
│  3. 服务不加入 caddy 网络，保持独立                               │
│                                                                  │
│  原因：                                                          │
│  - host.docker.internal 解析到 Docker 网关 172.17.0.1            │
│  - 127.0.0.1 只允许宿主机本地访问，容器无法连接                   │
│  - 0.0.0.0 允许所有来源访问，包括 Docker 网关                     │
└─────────────────────────────────────────────────────────────────┘
```

### 架构图

```
┌─────────────────────────────────────────────────────────────────────┐
│                          VPS (公网 IP)                               │
│                                                                      │
│   ┌──────────────────┐                                              │
│   │     Internet     │                                              │
│   │   (HTTPS :443)   │                                              │
│   └────────┬─────────┘                                              │
│            │                                                         │
│            ▼                                                         │
│   ┌──────────────────┐         host.docker.internal                 │
│   │      Caddy       │──────────────────────► 172.17.0.1 (网关)     │
│   │    (Docker)      │                                              │
│   │                  │                                              │
│   │  自动 HTTPS      │                                              │
│   │  SSL 证书管理    │                                              │
│   └──────────────────┘                                              │
│            │                                                         │
│            │ 转发规则                                                │
│            ├─────────────────────────────────────────────┐          │
│            │                                             │          │
│            ▼                                             ▼          │
│   ┌──────────────────┐                         ┌──────────────────┐ │
│   │ home.akali.xyz   │ ─────► 0.0.0.0:3000    │ Homepage 服务    │ │
│   └──────────────────┘                         │ (Docker/非Docker)│ │
│                                                └──────────────────┘ │
│   ┌──────────────────┐                         ┌──────────────────┐ │
│   │ note.akali.xyz   │ ─────► 0.0.0.0:8080    │ Flatnotes 服务   │ │
│   └──────────────────┘                         │ (Docker/非Docker)│ │
│                                                └──────────────────┘ │
│                                                                      │
│   ┌──────────────────┐                         ┌──────────────────┐ │
│   │ 新服务域名       │ ─────► 0.0.0.0:XXXX    │ 新服务           │ │
│   └──────────────────┘                         │ (任意方式启动)   │ │
│                                                └──────────────────┘ │
│                                                                      │
│   【关键】：所有服务监听 0.0.0.0:端口，不监听 127.0.0.1              │
└─────────────────────────────────────────────────────────────────────┘
```

### 网络流向详解

```
用户请求 ──► Caddy容器(:443) ──► host.docker.internal ──► 172.17.0.1(Docker网关)
                                                                    │
                                                                    ▼
                                                            宿主机 0.0.0.0:端口
                                                                    │
                                                                    ▼
                                                            目标服务进程
```

| 组件 | 网络位置 | 说明 |
|------|----------|------|
| Caddy | Docker 容器 (caddy_default 网络) | 统一入口，自动 HTTPS |
| host.docker.internal | 172.17.0.1 | Docker 网关 IP，通过 extra_hosts 配置 |
| 后端服务 | 宿主机 (独立网络) | 监听 0.0.0.0，不加入任何 Docker 网络 |

---

## 配置规范

### Docker 服务配置（强制）

```yaml
services:
  myservice:
    image: xxx
    container_name: myservice
    restart: unless-stopped
    ports:
      # 必须绑定 0.0.0.0，不能用 127.0.0.1
      - "8080:8080"        # ✓ 正确
      # - "127.0.0.1:8080:8080"  # ✗ 错误！Caddy 无法访问
```

### 非 Docker 服务配置

```bash
# 服务必须监听 0.0.0.0，不能只监听 127.0.0.1
# Node.js 示例
app.listen(3000, '0.0.0.0')  # ✓ 正确
# app.listen(3000, '127.0.0.1')  # ✗ 错误！

# Python 示例
app.run(host='0.0.0.0', port=8080)  # ✓ 正确
# app.run(host='127.0.0.1', port=8080)  # ✗ 错误！

# Go 示例
http.ListenAndServe("0.0.0.0:8080", nil)  # ✓ 正确
```

### Caddy 站点配置

```caddy
# sites/myservice.caddyfile
myservice.akali.xyz {
    # 必须使用 host.docker.internal，不能用容器名
    reverse_proxy host.docker.internal:8080
    
    # 可选：上传大小限制
    request_body {
        max_size 20MB
    }
    
    # 可选：日志
    log {
        output file /var/log/caddy/myservice.log
    }
}
```

---

## Caddy 配置

### 主配置 (Caddyfile)

```caddy
{
    email admin@akali.xyz
}

import sites/*.caddyfile
```

### 已配置域名

| 域名 | 宿主机端口 | 服务 | 配置文件 |
|------|------------|------|----------|
| home.akali.xyz | 3000 | Homepage | sites/home.caddyfile |
| note.akali.xyz | 8080 | Flatnotes | sites/note.caddyfile |

### Caddy docker-compose.yml

```yaml
services:
  caddy:
    image: caddy:latest
    container_name: caddy
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile
      - ./sites:/etc/caddy/sites    # 必须挂载 sites 目录
      - caddy_data:/data
      - caddy_config:/config
      - caddy_logs:/var/log/caddy
    extra_hosts:
      - "host.docker.internal:host-gateway"  # 必须配置！

volumes:
  caddy_data:
  caddy_config:
  caddy_logs:
```

---

## 添加新服务

### 步骤

1. **创建服务目录**
   ```bash
   mkdir /data/homepage/myservice
   ```

2. **配置服务端口绑定**
   - Docker 服务：`ports: "端口:端口"`（不加 127.0.0.1）
   - 非 Docker 服务：监听 `0.0.0.0:端口`

3. **创建 run.sh**
   ```bash
   chmod +x /data/homepage/myservice/run.sh
   ```

4. **添加 Caddy 配置**
   ```bash
   # 创建站点配置
   vim /data/homepage/caddy/sites/myservice.caddyfile
   
   # 内容示例：
   myservice.akali.xyz {
       reverse_proxy host.docker.internal:端口号
   }
   ```

5. **重载 Caddy**
   ```bash
   docker exec caddy caddy reload --config /etc/caddy/Caddyfile
   ```

---

## 常用命令

### Caddy 管理

```bash
# 启动
cd /data/homepage/caddy && docker compose up -d

# 重载配置（不中断服务）
docker exec caddy caddy reload --config /etc/caddy/Caddyfile

# 查看日志
docker logs caddy -f

# 查看已加载的域名
docker exec caddy caddy list-modules
```

### 服务管理

```bash
# Homepage
/data/homepage/homepage/run.sh start
/data/homepage/homepage/run.sh stop
/data/homepage/homepage/run.sh logs

# Flatnotes
/data/homepage/flatnotes/run.sh start
/data/homepage/flatnotes/run.sh stop
/data/homepage/flatnotes/run.sh logs
```

### 状态检查

```bash
# 查看所有服务
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# 测试域名访问
curl -s -o /dev/null -w "%{http_code}" https://home.akali.xyz/
curl -s -o /dev/null -w "%{http_code}" https://note.akali.xyz/

# 测试宿主机端口
curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:3000/
curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8080/
```

---

## 故障排查

### 常见问题

| 问题 | 原因 | 解决方案 |
|------|------|----------|
| 域名返回 502 | 服务绑定 127.0.0.1 | 改为绑定 0.0.0.0 |
| 域名返回 502 | 服务未启动 | 启动对应服务 |
| 域名无法解析 | DNS 未配置 | 添加 A 记录到 VPS IP |
| SSL 证书失败 | 域名未正确解析 | 检查 DNS 配置 |
| 配置不生效 | sites 目录未挂载 | 添加 `./sites:/etc/caddy/sites` |

### 排查步骤

```bash
# 1. 检查 Caddy 日志
docker logs caddy --tail 20

# 2. 检查服务是否运行
docker ps | grep 服务名

# 3. 测试宿主机端口
curl http://127.0.0.1:端口/

# 4. 测试容器能否访问宿主机
docker exec caddy wget -q -O /dev/null http://host.docker.internal:端口/

# 5. 检查服务端口绑定
docker inspect 服务名 --format '{{json .HostConfig.PortBindings}}'
```

---

## 部署记录

- 部署时间: 2026-05-22
- 最后更新: 2026-05-22
- 架构版本: v2 (独立网络模式)