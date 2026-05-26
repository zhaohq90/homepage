# MySQL 数据库备份脚本

将多个 MySQL 数据库导出并通过 `ossutil` 上传至阿里云 OSS，实现定时自动备份。

## 功能

- 从配置文件 `databases.conf` 读取要备份的数据库列表（每行一个库名）
- 使用 `mysqldump` 导出每个数据库，包含存储过程和触发器
- 备份前检查数据库是否存在，不存在的库记录告警并跳过，不影响其他库
- 上传至阿里云 OSS，路径为：`backup/YYYY-MM/数据库名/数据库名-YYYY-MM-DD.sql`
- 带时间戳日志，输出到 `/var/log/mysql_oss_backup.log`

## 配置

### 数据库列表 — `databases.conf`

每行一个数据库名，`#` 开头的行为注释：

```
# 我的业务数据库
test
myapp
```

### 脚本顶部的连接参数

| 变量 | 说明 | 默认值 |
|------|------|--------|
| `MYSQL_USER` | 数据库用户名 | `root` |
| `MYSQL_PASSWORD` | 数据库密码 | — |
| `MYSQL_HOST` | 数据库地址 | `localhost` |
| `OSS_BUCKET` | OSS Bucket | `oss://yezi0001` |
| `OSS_BASE_PATH` | OSS 存储路径 | `/backup` |

## 依赖

- `mysqldump`（mysql-client）
- `ossutil`（阿里云 OSS 命令行工具，配置文件 `~/.ossutilconfig`）

## 使用方式

### 手动执行

```bash
bash /data/homepage/mysql-backup/backup_to_oss.sh
```

### 添加定时任务（每天凌晨 2 点执行）

```bash
crontab -e
```

添加以下行：

```
0 2 * * * /data/homepage/mysql-backup/backup_to_oss.sh
```

### 新增备份数据库

编辑 `databases.conf`，添加一行数据库名即可，下次执行时自动纳入备份。

### 查看日志

```bash
tail -f /var/log/mysql_oss_backup.log
```
