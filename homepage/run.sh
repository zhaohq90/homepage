#!/bin/bash
# Homepage 服务启动脚本
# 源码: /root/projects/homepage
# 配置: /data/homepage/homepage/config

set -e

IMAGE_NAME="homepage"
IMAGE_TAG="local"
CONTAINER_NAME="homepage"
CONFIG_DIR="/data/homepage/homepage/config"
SOURCE_DIR="/root/projects/homepage"
PORT=3000

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

# 停止并删除现有容器
stop_container() {
    if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        log_info "停止并删除现有容器: ${CONTAINER_NAME}"
        docker stop ${CONTAINER_NAME} 2>/dev/null || true
        docker rm ${CONTAINER_NAME} 2>/dev/null || true
    fi
}

# 构建镜像
build_image() {
    log_info "构建镜像: ${IMAGE_NAME}:${IMAGE_TAG}"
    log_info "源码目录: ${SOURCE_DIR}"
    
    cd ${SOURCE_DIR}
    
    docker build \
        --build-arg BUILDTIME=$(date -u +%Y-%m-%dT%H:%M:%SZ) \
        --build-arg VERSION=local \
        --build-arg REVISION=local \
        -t ${IMAGE_NAME}:${IMAGE_TAG} \
        -f Dockerfile \
        .
    
    log_info "镜像构建完成"
}

# 使用官方镜像
pull_image() {
    log_info "拉取官方镜像: ghcr.io/gethomepage/homepage:latest"
    docker pull ghcr.io/gethomepage/homepage:latest
    docker tag ghcr.io/gethomepage/homepage:latest ${IMAGE_NAME}:${IMAGE_TAG}
}

# 启动容器
start_container() {
    log_info "启动容器: ${CONTAINER_NAME}"
    log_info "配置目录: ${CONFIG_DIR}"
    log_info "端口映射: ${PORT}:3000"
    
    # 检查配置目录是否存在
    if [ ! -d "${CONFIG_DIR}" ]; then
        log_error "配置目录不存在: ${CONFIG_DIR}"
        exit 1
    fi
    
    docker run -d \
        --name ${CONTAINER_NAME} \
        --restart unless-stopped \
        -p ${PORT}:3000 \
        -v ${CONFIG_DIR}:/app/config \
        -v /var/run/docker.sock:/var/run/docker.sock:ro \
        -e HOMEPAGE_ALLOWED_HOSTS="*" \
        ${IMAGE_NAME}:${IMAGE_TAG}
    
    log_info "容器已启动"
    
    # 等待服务就绪
    sleep 3
    
    # 检查服务状态
    if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        log_info "Homepage 服务运行中"
        log_info "访问地址: http://localhost:${PORT}"
        docker logs --tail 20 ${CONTAINER_NAME}
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

# 帮助信息
usage() {
    echo "用法: $0 {build|pull|start|stop|restart|logs|rebuild}"
    echo ""
    echo "命令:"
    echo "  build   - 从源码构建镜像"
    echo "  pull    - 拉取官方镜像"
    echo "  start   - 启动容器"
    echo "  stop    - 停止容器"
    echo "  restart - 重启容器"
    echo "  logs    - 查看日志"
    echo "  rebuild - 重新构建并启动"
    echo ""
    echo "快速启动:"
    echo "  $0 pull    # 使用官方镜像"
    echo "  $0 build   # 从源码构建"
}

case "$1" in
    build)
        build_image
        ;;
    pull)
        pull_image
        ;;
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
    rebuild)
        stop_container
        build_image
        start_container
        ;;
    *)
        if [ -z "$1" ]; then
            # 默认：拉取官方镜像并启动
            stop_container
            pull_image
            start_container
        else
            usage
            exit 1
        fi
        ;;
esac