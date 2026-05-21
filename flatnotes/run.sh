#!/bin/bash
# Flatnotes 笔记服务启动脚本
# 配置目录: /data/homepage/flatnotes

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONTAINER_NAME="flatnotes"
NETWORK_NAME="caddy_default"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查网络是否存在
check_network() {
    if ! docker network ls --format '{{.Name}}' | grep -q "^${NETWORK_NAME}$"; then
        log_error "网络 ${NETWORK_NAME} 不存在，请先启动 Caddy"
        log_info "运行: cd /data/homepage/caddy && docker compose up -d"
        exit 1
    fi
}

# 停止容器
stop_container() {
    if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        log_info "停止容器: ${CONTAINER_NAME}"
        docker stop ${CONTAINER_NAME} 2>/dev/null || true
        docker rm ${CONTAINER_NAME} 2>/dev/null || true
    fi
}

# 启动容器
start_container() {
    check_network
    log_info "启动容器: ${CONTAINER_NAME}"
    
    cd ${SCRIPT_DIR}
    docker compose up -d
    
    sleep 3
    
    if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        log_info "Flatnotes 服务运行中"
        log_info "访问地址: https://note.akali.xyz"
        docker logs --tail 10 ${CONTAINER_NAME}
    else
        log_error "容器启动失败"
        docker logs ${CONTAINER_NAME}
        exit 1
    fi
}

# 查看日志
logs() {
    docker logs -f ${CONTAINER_NAME}
}

# 拉取最新镜像
pull() {
    log_info "拉取最新镜像"
    cd ${SCRIPT_DIR}
    docker compose pull
}

# 备份笔记
backup() {
    if [ -f "${SCRIPT_DIR}/git-backup.sh" ]; then
        log_info "执行 Git 备份"
        ${SCRIPT_DIR}/git-backup.sh
    else
        log_warn "备份脚本不存在: ${SCRIPT_DIR}/git-backup.sh"
    fi
}

# 帮助信息
usage() {
    echo "用法: $0 {start|stop|restart|logs|pull|update|backup|status}"
    echo ""
    echo "命令:"
    echo "  start   - 启动服务"
    echo "  stop    - 停止服务"
    echo "  restart - 重启服务"
    echo "  logs    - 查看日志 (实时)"
    echo "  pull    - 拉取最新镜像"
    echo "  update  - 拉取镜像并重启"
    echo "  backup  - 执行 Git 备份"
    echo "  status  - 查看服务状态"
}

case "$1" in
    start)
        start_container
        ;;
    stop)
        stop_container
        log_info "容器已停止"
        ;;
    restart)
        stop_container
        start_container
        ;;
    logs)
        logs
        ;;
    pull)
        pull
        ;;
    update)
        pull
        stop_container
        start_container
        ;;
    backup)
        backup
        ;;
    status)
        docker ps --filter name=${CONTAINER_NAME} --format "table {{.Names}}\t{{.Status}}\t{{.Networks}}"
        ;;
    *)
        if [ -z "$1" ]; then
            start_container
        else
            usage
            exit 1
        fi
        ;;
esac