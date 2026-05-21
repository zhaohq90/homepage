# Caddy 反向代理服务

> 统一的 HTTPS 入口，为所有服务提供反向代理和自动 SSL 证书管理

## 基本信息

| 属性 | 值 |
|------|-----|
| 容器名 | caddy |
| 镜像 | caddy:latest |
| 端口 | 80, 443 |
| 域名 | *.akali.xyz (统一入口) |

## 目录结构

```
caddy/
├── Caddyfile           # 主配置文件
├── docker-compose.yml  # Docker Compose 配置
└── sites/              # 域名配置目录
    ├── home.caddyfile  # home.akali.xyz 配置
    ├── note.caddyfile  # note.akali.xyz 配置
    └── file.caddyfile  # file.akali.xyz 配置
```

## 挂载目录

| 容器路径 | 主机路径 | 说明 |
|----------|----------|------|
| /etc/caddy/Caddyfile | ./Caddyfile | 主配置 |
| /etc/caddy/sites | ./sites | 域名配置目录 |
| /data | caddy_data (卷) | Caddy 数据 |
| /config | caddy_config (卷) | Caddy 配置 |
| /var/log/caddy | caddy_logs (卷) | 日志目录 |

## 配置要点

### 主配置 (Caddyfile)

```caddy
{
    email admin@akali.xyz
}

import sites/*.caddyfile
```

### 关键配置 (docker-compose.yml)

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
      - ./sites:/etc/caddy/sites    # 必须挂载
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

## 常用命令

```bash
# 启动
cd /data/homepage/caddy && docker compose up -d

# 停止
cd /data/homepage/caddy && docker compose down

# 重载配置（不中断服务）
docker exec caddy caddy reload --config /etc/caddy/Caddyfile

# 查看日志
docker logs caddy -f

# 查看特定站点日志
docker exec caddy cat /var/log/caddy/home.log
```

## 添加新域名

1. 在 `sites/` 目录创建新配置文件：
```bash
vim /data/homepage/caddy/sites/newsite.caddyfile
```

2. 配置内容：
```caddy
newsite.akali.xyz {
    reverse_proxy host.docker.internal:端口
    
    log {
        output file /var/log/caddy/newsite.log
    }
}
```

3. 重载配置：
```bash
docker exec caddy caddy reload --config /etc/caddy/Caddyfile
```

4. 添加 DNS 解析：`newsite.akali.xyz` → VPS IP

## 注意事项

- **必须挂载 sites 目录**：否则 `import sites/*.caddyfile` 无法生效
- **必须配置 extra_hosts**：否则 `host.docker.internal` 无法解析
- SSL 证书自动申请，首次访问可能需要等待证书生成