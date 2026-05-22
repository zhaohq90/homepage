#!/bin/bash
# Alist 文件列表服务启动脚本
# 配置目录: /data/homepage/alist

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONTAINER_NAME="alist"
PORT=5244

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
    log_info "启动容器: ${CONTAINER_NAME}"
    log_info "端口: ${PORT}"
    
    cd ${SCRIPT_DIR}
    docker compose up -d
    
    sleep 3
    
    if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        log_info "Alist 服务运行中"
        log_info "访问地址: https://alist.akali.xyz"
        log_info "本地地址: http://127.0.0.1:${PORT}"
        docker logs --tail 10 ${CONTAINER_NAME}
    else
        log_error "容器启动失败"
        docker logs ${CONTAINER_NAME}
        exit 1
    fi
}

# 设置管理员密码
set_password() {
    local password="$1"
    if [ -z "$password" ]; then
        log_error "请提供密码: $0 password <新密码>"
        exit 1
    fi
    log_info "设置管理员密码"
    docker exec ${CONTAINER_NAME} ./alist admin set "$password"
    log_info "密码已更新: admin / $password"
}

# 获取随机密码
get_password() {
    log_info "获取管理员密码"
    docker exec ${CONTAINER_NAME} ./alist admin random
}

# 查看日志
logs() {
    docker logs -f ${CONTAINER_NAME}
}

# 拉取最新镜像
pull() {
    log_info "拉取最新镜像"
    docker pull xhofe/alist:latest
}

# 帮助信息
usage() {
    echo "用法: $0 {start|stop|restart|logs|pull|update|status|password <密码>|random}"
    echo ""
    echo "命令:"
    echo "  start       - 启动服务"
    echo "  stop        - 停止服务"
    echo "  restart     - 重启服务"
    echo "  logs        - 查看日志 (实时)"
    echo "  pull        - 拉取最新镜像"
    echo "  update      - 拉取镜像并重启"
    echo "  status      - 查看服务状态"
    echo "  password    - 设置管理员密码"
    echo "  random      - 生成随机管理员密码"
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
    status)
        docker ps --filter name=${CONTAINER_NAME} --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        ;;
    password)
        set_password "$2"
        ;;
    random)
        get_password
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