#!/bin/bash
# Flatnotes Git 自动备份脚本
# 每 5 分钟检查变更并提交到主仓库

PROJECT_DIR="/root/projects/flatnotes"
LOG_FILE="/root/projects/flatnotes/backup.log"

cd "$PROJECT_DIR" || exit 1

# 检查是否有变更
if git diff --quiet && git diff --cached --quiet; then
    # 无变更，静默退出
    exit 0
fi

# 有变更，提交
git add -A
COMMIT_MSG="Auto-backup: $(date +%Y-%m-%d_%H:%M:%S)"
git commit -m "$COMMIT_MSG"

# 推送
git push

echo "$(date '+%Y-%m-%d %H:%M:%S') $COMMIT_MSG" >> "$LOG_FILE"
