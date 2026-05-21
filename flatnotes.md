# Flatnotes 笔记服务

> 基于 Markdown 的轻量级笔记系统，支持实时搜索和 Git 自动备份

## 基本信息

| 属性 | 值 |
|------|-----|
| 容器名 | flatnotes |
| 镜像 | dullage/flatnotes:latest |
| 端口 | 8080 |
| 域名 | [note.akali.xyz](https://note.akali.xyz) |

## 目录结构

```
flatnotes/
├── docker-compose.yml  # Docker Compose 配置
├── .env                 # 环境变量（密码等）
├── run.sh              # 启动脚本
├── git-backup.sh       # Git 自动备份脚本
└── data/               # 数据目录
    ├── notes/          # 笔记文件 (.md)
    ├── attachments/    # 图片附件
    └── flatnotes.db    # 索引数据库
```

## 挂载目录

| 容器路径 | 主机路径 | 说明 |
|----------|----------|------|
| /data | ./data | 数据目录（笔记、附件） |

## 环境变量 (.env)

```bash
FLATNOTES_AUTH_TYPE=password
FLATNOTES_USERNAME=admin
FLATNOTES_PASSWORD=<加密密码>
FLATNOTES_SECRET_KEY=<32字节密钥>
PUID=0
PGID=0
```

## 登录信息

```
用户名: admin
密码:   见 .env 文件
```

## Docker 配置

```yaml
services:
  flatnotes:
    image: dullage/flatnotes:latest
    container_name: flatnotes
    restart: unless-stopped
    ports:
      - "8080:8080"    # 必须绑定 0.0.0.0
    env_file:
      - .env
    volumes:
      - ./data:/data
```

## 备份机制

### Git 自动备份

- 脚本: `git-backup.sh`
- 频率: 每 5 分钟 (通过 crontab)
- 日志: `backup.log`

### 查看备份历史

```bash
cd /data/homepage/flatnotes/data && git log --oneline -10
```

### 手动备份

```bash
/data/homepage/flatnotes/git-backup.sh
```

## 常用命令

```bash
# 启动
/data/homepage/flatnotes/run.sh start

# 停止
/data/homepage/flatnotes/run.sh stop

# 重启
/data/homepage/flatnotes/run.sh restart

# 查看日志
/data/homepage/flatnotes/run.sh logs

# 查看状态
/data/homepage/flatnotes/run.sh status

# 更新镜像
/data/homepage/flatnotes/run.sh update

# 执行备份
/data/homepage/flatnotes/run.sh backup
```

## 特性

- **无数据库**: 笔记存储为 `.md` 文件
- **实时搜索**: 基于 flatnotes.db 索引
- **图片上传**: 拖拽/粘贴上传到 attachments/
- **Git 版本控制**: 所有变更自动提交
- **自动 HTTPS**: 通过 Caddy 代理

## 相关链接

- 官方文档: https://github.com/dullage/flatnotes
- 原部署文档: /root/projects/flatnotes/README.md