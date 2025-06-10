#!/bin/bash

# Bhuang MCP Server SSE 一键部署脚本
# 作者: Bhuang
# 版本: 1.0.0

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置参数
REGISTRY="crpi-wzl2k45d0lxbiagj.cn-shenzhen.personal.cr.aliyuncs.com"
NAMESPACE="bhuang-repo"  # 您的阿里云命名空间
IMAGE_NAME="bhuang-mcp-server-sse"
VERSION="latest"
CONTAINER_NAME="bhuang-mcp-server"
PORT="8080"  # 主机端口
CONTAINER_PORT="9090"  # 容器内部端口

# 显示横幅
echo -e "${BLUE}"
echo "=================================================="
echo "   🚀 Bhuang MCP Server SSE 一键部署脚本"
echo "=================================================="
echo -e "${NC}"

# 函数：打印日志
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 函数：检查命令是否存在
check_command() {
    if ! command -v $1 &> /dev/null; then
        log_error "$1 命令未找到，请先安装 $1"
        exit 1
    fi
}

# 函数：停止并删除现有容器
stop_existing_container() {
    if docker ps -a | grep -q $CONTAINER_NAME; then
        log_warn "发现现有容器 $CONTAINER_NAME，正在停止并删除..."
        docker stop $CONTAINER_NAME >/dev/null 2>&1 || true
        docker rm $CONTAINER_NAME >/dev/null 2>&1 || true
        log_info "现有容器已清理"
    fi
}

# 函数：拉取镜像
pull_image() {
    local full_image="${REGISTRY}/${NAMESPACE}/${IMAGE_NAME}:${VERSION}"
    log_info "正在拉取镜像: $full_image"
    
    if ! docker pull $full_image; then
        log_error "镜像拉取失败，请检查："
        echo "  1. 网络连接是否正常"
        echo "  2. 镜像地址是否正确: $full_image"
        echo "  3. 是否已登录到镜像仓库: docker login $REGISTRY"
        exit 1
    fi
    
    log_info "镜像拉取成功"
}

# 函数：运行容器
run_container() {
    local full_image="${REGISTRY}/${NAMESPACE}/${IMAGE_NAME}:${VERSION}"
    
    log_info "正在启动 MCP Server 容器..."
    
    docker run -d \
        --name $CONTAINER_NAME \
        --restart unless-stopped \
        -p $PORT:$CONTAINER_PORT \
        -e JAVA_OPTS="-Xms512m -Xmx1024m -XX:+UseG1GC" \
        -e TZ="Asia/Shanghai" \
        -e SPRING_PROFILES_ACTIVE="prod" \
        -v "$(pwd)/logs:/app/logs" \
        $full_image
    
    if [ $? -eq 0 ]; then
        log_info "容器启动成功！"
    else
        log_error "容器启动失败"
        exit 1
    fi
}

# 函数：等待服务启动
wait_for_service() {
    log_info "等待 MCP Server 启动..."
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s -f http://localhost:$PORT/actuator/health >/dev/null 2>&1; then
            log_info "MCP Server 启动成功！"
            return 0
        fi
        
        echo -n "."
        sleep 2
        attempt=$((attempt + 1))
    done
    
    log_error "MCP Server 启动超时"
    return 1
}

# 函数：显示服务信息
show_service_info() {
    echo -e "${BLUE}"
    echo "=================================================="
    echo "   ✅ 部署完成！服务信息如下："
    echo "=================================================="
    echo -e "${NC}"
    
    echo "🌐 服务地址:"
    echo "   - MCP SSE端点: http://localhost:$PORT/mcp/events"
    echo "   - MCP 消息端点: http://localhost:$PORT/mcp/messages"
    echo "   - 健康检查: http://localhost:$PORT/actuator/health"
    echo "   - 应用信息: http://localhost:$PORT/actuator/info"
    echo ""
    
    echo "📊 容器信息:"
    docker ps | grep $CONTAINER_NAME | awk '{printf "   - 容器ID: %s\n   - 状态: %s\n   - 端口: %s\n", $1, $7" "$8, $6}'
    echo ""
    
    echo "🔧 管理命令:"
    echo "   # 查看日志"
    echo "   docker logs -f $CONTAINER_NAME"
    echo ""
    echo "   # 重启服务"
    echo "   docker restart $CONTAINER_NAME"
    echo ""
    echo "   # 停止服务"
    echo "   docker stop $CONTAINER_NAME"
    echo ""
    echo "   # 更新服务"
    echo "   bash deploy.sh"
    echo ""
    
    echo "🧪 快速测试:"
    echo "   # 测试MCP SSE连接"
    echo "   curl -N -H \"Accept: text/event-stream\" http://localhost:$PORT/mcp/events"
    echo ""
    echo "   # 测试健康状态"
    echo "   curl http://localhost:$PORT/actuator/health"
    echo ""
    
    echo "=================================================="
}

# 主函数
main() {
    # 检查依赖
    log_info "检查系统依赖..."
    check_command docker
    check_command curl
    
    # 获取用户输入
    if [ -n "$1" ]; then
        VERSION="$1"
    else
        read -p "请输入镜像版本 (默认: latest): " input_version
        VERSION=${input_version:-latest}
    fi
    
    if [ -n "$2" ]; then
        NAMESPACE="$2"
    else
        read -p "请输入命名空间 (默认: bhuang-repo): " input_namespace
        NAMESPACE=${input_namespace:-bhuang-repo}
    fi
    
    # 确认部署信息
    echo ""
    log_info "部署信息确认:"
    echo "  - 镜像仓库: $REGISTRY"
    echo "  - 命名空间: $NAMESPACE"
    echo "  - 镜像名称: $IMAGE_NAME"
    echo "  - 镜像版本: $VERSION"
    echo "  - 容器名称: $CONTAINER_NAME"
    echo "  - 主机端口: $PORT"
    echo "  - 容器内部端口: $CONTAINER_PORT"
    echo ""
    
    read -p "确认部署? (y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        log_warn "部署已取消"
        exit 0
    fi
    
    # 执行部署步骤
    log_info "开始部署 MCP Server..."
    
    stop_existing_container
    pull_image
    run_container
    
    if wait_for_service; then
        show_service_info
        log_info "🎉 MCP Server 部署成功！"
    else
        log_error "服务健康检查失败，请查看日志: docker logs $CONTAINER_NAME"
        exit 1
    fi
}

# 脚本入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi