#!/bin/bash

# 阿里云 Docker Registry 镜像拉取、标记和运行脚本
# 作者: Bhuang
# 版本: 1.0.0

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置参数 - 可根据需要修改
REGISTRY_DOMAIN="crpi-wzl2k45d0lxbiagj.cn-shenzhen.personal.cr.aliyuncs.com"
REGISTRY_VPC_DOMAIN="crpi-wzl2k45d0lxbiagj-vpc.cn-shenzhen.personal.cr.aliyuncs.com" # 专有网络地址
REGISTRY_USERNAME="黄帅啊"
REPO_PATH="bhuang-repo/bhuang-mcp-server-sse"
IMAGE_VERSION="latest"  # 默认拉取最新版本，可通过参数修改
LOCAL_TAG="bhuang-mcp-sse"  # 本地标签名
CONTAINER_NAME="bhuang-mcp-server"  # 容器名称
SERVER_PORT=9090  # 服务暴露端口

# 参数解析
while [[ $# -gt 0 ]]; do
  case $1 in
    -v|--version)
      IMAGE_VERSION="$2"
      shift 2
      ;;
    -p|--port)
      SERVER_PORT="$2"
      shift 2
      ;;
    -n|--name)
      CONTAINER_NAME="$2"
      shift 2
      ;;
    --vpc)
      USE_VPC=true
      shift
      ;;
    *)
      echo -e "${RED}未知参数: $1${NC}"
      exit 1
      ;;
  esac
done

# 根据是否使用VPC设置域名
if [ "$USE_VPC" = true ]; then
  REGISTRY_URL="$REGISTRY_VPC_DOMAIN"
  echo -e "${BLUE}使用专有网络VPC地址${NC}"
else
  REGISTRY_URL="$REGISTRY_DOMAIN"
  echo -e "${BLUE}使用公网地址${NC}"
fi

FULL_IMAGE_PATH="${REGISTRY_URL}/${REPO_PATH}:${IMAGE_VERSION}"
LOCAL_IMAGE_NAME="${LOCAL_TAG}:${IMAGE_VERSION}"

echo -e "${BLUE}📦 镜像信息:${NC}"
echo "  - 远程镜像: ${FULL_IMAGE_PATH}"
echo "  - 本地标签: ${LOCAL_IMAGE_NAME}"
echo "  - 容器名称: ${CONTAINER_NAME}"
echo "  - 服务端口: ${SERVER_PORT}"

# 检查 Docker 是否运行
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker 未运行，请先启动 Docker${NC}"
    exit 1
fi

# 登录阿里云容器镜像服务
echo -e "${BLUE}🔑 登录阿里云容器镜像服务...${NC}"
echo -e "${YELLOW}需要输入您的阿里云容器镜像服务密码${NC}"
docker login --username=${REGISTRY_USERNAME} ${REGISTRY_URL}

# 拉取镜像
echo -e "${BLUE}⬇️ 拉取镜像: ${FULL_IMAGE_PATH}${NC}"
docker pull ${FULL_IMAGE_PATH}

# 获取镜像ID
IMAGE_ID=$(docker images --format "{{.ID}}" ${FULL_IMAGE_PATH})
if [ -z "$IMAGE_ID" ]; then
    echo -e "${RED}❌ 无法获取镜像ID，拉取可能失败${NC}"
    exit 1
fi
echo -e "${GREEN}✅ 成功拉取镜像，ID: ${IMAGE_ID}${NC}"

# 标记镜像
echo -e "${BLUE}🏷️ 标记镜像: ${LOCAL_IMAGE_NAME}${NC}"
docker tag ${IMAGE_ID} ${LOCAL_IMAGE_NAME}

# 检查并停止旧容器
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo -e "${YELLOW}⚠️ 已存在同名容器，正在停止并移除...${NC}"
    docker stop ${CONTAINER_NAME} > /dev/null 2>&1 || true
    docker rm ${CONTAINER_NAME} > /dev/null 2>&1 || true
fi

# 运行容器
echo -e "${BLUE}🚀 启动容器: ${CONTAINER_NAME}${NC}"
docker run -d \
  --name ${CONTAINER_NAME} \
  -p ${SERVER_PORT}:${SERVER_PORT} \
  -e JAVA_OPTS="-Xms512m -Xmx1024m" \
  -e TZ=Asia/Shanghai \
  ${LOCAL_IMAGE_NAME}

# 检查容器是否成功启动
sleep 2
if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo -e "${GREEN}✅ 容器成功启动!${NC}"
    echo -e "${BLUE}📋 容器信息:${NC}"
    docker ps --filter "name=${CONTAINER_NAME}"
    echo
    echo -e "${BLUE}🌐 服务访问:${NC}"
    echo "  http://localhost:${SERVER_PORT}"
    echo
    echo -e "${BLUE}📊 查看日志:${NC}"
    echo "  docker logs ${CONTAINER_NAME}"
    echo -e "${BLUE}🛑 停止容器:${NC}"
    echo "  docker stop ${CONTAINER_NAME}"
else
    echo -e "${RED}❌ 容器启动失败，请检查日志:${NC}"
    echo "  docker logs ${CONTAINER_NAME}"
fi
