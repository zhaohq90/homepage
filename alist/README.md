# Alist 文件列表服务

> 支持多种存储源的文件列表程序，提供 Web 界面管理文件

## 基本信息

| 属性 | 值 |
|------|-----|
| 容器名 | alist |
| 镜像 | xhofe/alist:latest |
| 端口 | 5244 |
| 域名 | [alist.akali.xyz](https://alist.akali.xyz) |

## 目录结构

```
alist/
├── docker-compose.yml  # Docker Compose 配置
├── run.sh              # 启动脚本
└── data/               # 数据目录
    ├── config.json     # 配置文件
    ├── data/           # 数据库等
    └── temp/           # 临时文件
```

## 挂载目录

| 容器路径 | 主机路径 | 说明 |
|----------|----------|------|
| /opt/alist/data | ./data | 数据目录 |

## 登录信息

```
用户名: admin
密码:   Alist@2026
```

可通过 `run.sh password <新密码>` 修改密码。

## Docker 配置

```yaml
services:
  alist:
    image: xhofe/alist:latest
    container_name: alist
    restart: unless-stopped
    ports:
      - "5244:5244"    # 必须绑定 0.0.0.0
    volumes:
      - ./data:/opt/alist/data
    environment:
      - PUID=0
      - PGID=0
```

## 支持的存储源

Alist 支持多种存储后端：

- 本地存储
-阿里云盘
- 百度网盘
- 天翼云盘
- 115网盘
- Google Drive
- OneDrive
- S3/MinIO
- WebDAV
- 更多...

## 常用命令

```bash
# 启动
/data/homepage/alist/run.sh start

# 停止
/data/homepage/alist/run.sh stop

# 重启
/data/homepage/alist/run.sh restart

# 查看日志
/data/homepage/alist/run.sh logs

# 查看状态
/data/homepage/alist/run.sh status

# 更新镜像
/data/homepage/alist/run.sh update

# 设置密码
/data/homepage/alist/run.sh password <新密码>

# 生成随机密码
/data/homepage/alist/run.sh random
```

## 配置步骤

1. 启动服务后访问 `https://alist.akali.xyz`
2. 使用 admin/Alist@2026 登录
3. 在「设置」→「存储」添加存储源
4. 配置存储路径和访问权限

## 注意事项

- 首次登录后建议修改默认密码
- 添加存储源时注意配置正确的根路径

## 相关链接

- 官方文档: https://alist.nn.ci/
- GitHub: https://github.com/AlistGo/alist