#!/bin/bash

# MySQL 配置
MYSQL_USER="root"
MYSQL_PASSWORD="199078lemon"
MYSQL_HOST="localhost"
MYSQL_PORT="3306"

# OSS 配置
OSS_BUCKET="oss://yezi0001"
OSS_BASE_PATH="/backup"

# 本地临时目录
LOCAL_TMP_DIR="/data/mysql_backup"

# 日志文件
LOG_FILE="/var/log/mysql_oss_backup.log"

# 数据库列表配置文件（脚本所在目录下的 databases.conf）
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DB_LIST_FILE="${SCRIPT_DIR}/databases.conf"

# 创建临时目录
mkdir -p "$LOCAL_TMP_DIR"

# 获取当前日期
YEAR=$(date +%Y)
MONTH=$(date +%m)
DAY=$(date +%d)

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# 检查依赖
command -v mysqldump >/dev/null 2>&1 || { log "[ERROR] mysqldump not found!"; exit 1; }
command -v ossutil >/dev/null 2>&1 || { log "[ERROR] ossutil not found!"; exit 1; }

# 检查数据库列表文件
if [ ! -f "$DB_LIST_FILE" ]; then
    log "[ERROR] 数据库列表文件不存在: $DB_LIST_FILE"
    exit 1
fi

log "========== 备份任务开始 =========="

# 统计
SUCCESS_COUNT=0
FAIL_COUNT=0

# 逐行读取数据库名（跳过空行和 # 注释行）
while IFS= read -r DB_NAME; do
    # 去除首尾空白
    DB_NAME=$(echo "$DB_NAME" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    # 跳过空行和注释行
    [ -z "$DB_NAME" ] && continue
    [[ "$DB_NAME" =~ ^# ]] && continue

    log "--- 处理数据库: $DB_NAME ---"

    FILENAME="${DB_NAME}-${YEAR}-${MONTH}-${DAY}.sql"
    LOCAL_FILE="${LOCAL_TMP_DIR}/${FILENAME}"
    OSS_REMOTE_PATH="${OSS_BUCKET}${OSS_BASE_PATH}/${YEAR}-${MONTH}/${DB_NAME}/${FILENAME}"

    # 检查数据库是否存在
    if ! mysql --host="$MYSQL_HOST" --port="$MYSQL_PORT" --user="$MYSQL_USER" --password="$MYSQL_PASSWORD" \
         -e "SELECT 1" "$DB_NAME" >/dev/null 2>&1; then
        log "[WARN] 数据库 $DB_NAME 不存在或无法连接，跳过"
        FAIL_COUNT=$((FAIL_COUNT + 1))
        continue
    fi

    # 导出数据库
    log "导出 $DB_NAME → $LOCAL_FILE"
    mysqldump \
        --host="$MYSQL_HOST" \
        --port="$MYSQL_PORT" \
        --user="$MYSQL_USER" \
        --password="$MYSQL_PASSWORD" \
        --single-transaction \
        --routines \
        --triggers \
        "$DB_NAME" > "$LOCAL_FILE" 2>/tmp/mysqldump_err.log

    if [ $? -ne 0 ]; then
        ERR_MSG=$(cat /tmp/mysqldump_err.log 2>/dev/null | head -5)
        log "[ERROR] $DB_NAME 导出失败: $ERR_MSG"
        rm -f "$LOCAL_FILE" /tmp/mysqldump_err.log
        FAIL_COUNT=$((FAIL_COUNT + 1))
        continue
    fi

    # 上传到 OSS
    log "上传到 OSS: $OSS_REMOTE_PATH"
    ossutil cp "$LOCAL_FILE" "$OSS_REMOTE_PATH" >/tmp/ossutil_out.log 2>&1

    if [ $? -ne 0 ]; then
        log "[ERROR] $DB_NAME 上传 OSS 失败"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    else
        log "[OK] $DB_NAME 备份完成"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    fi

    # 清理临时文件和错误日志
    rm -f "$LOCAL_FILE" /tmp/mysqldump_err.log /tmp/ossutil_out.log

done < "$DB_LIST_FILE"

log "========== 备份任务结束: 成功 $SUCCESS_COUNT, 失败 $FAIL_COUNT =========="
