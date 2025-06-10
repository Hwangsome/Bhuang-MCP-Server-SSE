#!/bin/bash

# 本地开发环境 Docker 镜像构建脚本
# 作者: Bhuang
# 版本: 1.0.0

set -e

echo "🚀 开始构建本地开发镜像..."

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置参数
IMAGE_NAME="bhuang-mcp-server-sse"
LOCAL_TAG="local-dev"
FULL_IMAGE_NAME="${IMAGE_NAME}:${LOCAL_TAG}"

echo -e "${BLUE}📦 镜像信息:${NC}"
echo "  - 镜像名: ${FULL_IMAGE_NAME}"
echo "  - 构建时间: $(date '+%Y-%m-%d %H:%M:%S')"

# 检查 Docker 是否运行
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker 未运行，请先启动 Docker${NC}"
    exit 1
fi

# 检查 JAR 文件是否存在
if [ ! -f "target/bhuang-mcp-server-sse.jar" ]; then
    echo -e "${YELLOW}⚠️  JAR 文件不存在，开始 Maven 构建...${NC}"
    mvn clean package -DskipTests -q
    echo -e "${GREEN}✅ Maven 构建完成${NC}"
fi

# 构建 Docker 镜像
echo -e "${BLUE}🔨 开始构建 Docker 镜像...${NC}"
docker build -t ${FULL_IMAGE_NAME} .

# 验证构建结果
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Docker 镜像构建成功!${NC}"
    echo
    echo -e "${BLUE}📋 镜像信息:${NC}"
    docker images | grep ${IMAGE_NAME}
    echo
    echo -e "${BLUE}🚀 使用方法:${NC}"
    echo "  1. 启动容器: docker compose up -d"
    echo "  2. 查看日志: docker logs bhuang-mcp-server-sse"
    echo "  3. 健康检查: curl http://localhost:8088/actuator/health"
    echo "  4. 停止容器: docker compose down"
else
    echo -e "${RED}❌ Docker 镜像构建失败${NC}"
    exit 1
fi

echo -e "${GREEN}🎉 本地开发镜像构建完成!${NC}" 