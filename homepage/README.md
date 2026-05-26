# Homepage 仪表盘服务

> 自托管的服务仪表盘，展示各类服务状态和快捷入口

## 基本信息

| 属性 | 值 |
|------|-----|
| 容器名 | homepage |
| 镜像 | ghcr.io/gethomepage/homepage:latest |
| 端口 | 3000 |
| 域名 | [home.akali.xyz](https://home.akali.xyz) |

## 目录结构

```
homepage/
├── config/             # 配置目录
│   ├── bookmarks.yaml  # 书签配置
│   ├── docker.yaml     # Docker 集成配置
│   ├── kubernetes.yaml # Kubernetes 配置
│   ├── proxmox.yaml    # Proxmox 配置
│   ├── services.yaml   # 服务列表配置
│   ├── settings.yaml   # 全局设置
│   ├── widgets.yaml    # 组件配置
│   ├── custom.css      # 自定义样式
│   ├── custom.js       # 自定义脚本
│   └── logs/           # 日志目录
└── run.sh              # 启动脚本
```

## 挂载目录

| 容器路径 | 主机路径 | 说明 |
|----------|----------|------|
| /app/config | ./config | 配置目录 |
| /var/run/docker.sock | /var/run/docker.sock | Docker socket (只读) |

## Docker 配置

```yaml
# 通过 run.sh 启动，核心参数：
docker run -d \
    --name homepage \
    --restart unless-stopped \
    -p 3000:3000 \
    -v /data/homepage/homepage/config:/app/config \
    -v /var/run/docker.sock:/var/run/docker.sock:ro \
    -e HOMEPAGE_ALLOWED_HOSTS="*" \
    ghcr.io/gethomepage/homepage:latest
```

## 登录信息

Homepage 无需登录，直接访问。

## 配置说明

### settings.yaml

```yaml
title: 服务仪表板
theme: dark
color: slate
headerStyle: boxed
showStats: true
```

### services.yaml

定义展示的服务分组和状态检测。

## 常用命令

```bash
# 启动
/data/homepage/homepage/run.sh start

# 停止
/data/homepage/homepage/run.sh stop

# 重启
/data/homepage/homepage/run.sh restart

# 查看日志
/data/homepage/homepage/run.sh logs

# 查看状态
/data/homepage/homepage/run.sh status

# 从源码构建
/data/homepage/homepage/run.sh build
```

## 相关链接

- 官方文档: https://gethomepage.dev/
- GitHub: https://github.com/gethomepage/homepage