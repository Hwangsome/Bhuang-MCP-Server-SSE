# 🚀 Bhuang MCP Server SSE - 部署指南

[![Build and Deploy](https://github.com/your-username/your-repo/actions/workflows/build-and-deploy.yml/badge.svg)](https://github.com/your-username/your-repo/actions/workflows/build-and-deploy.yml)

本项目是一个基于Spring AI框架的MCP (Model Context Protocol) 服务器，支持SSE (Server-Sent Events) 传输层。

## 📋 目录

- [快速开始](#快速开始)
- [GitHub Actions 自动部署](#github-actions-自动部署)
- [手动部署](#手动部署)
- [配置说明](#配置说明)
- [监控和维护](#监控和维护)
- [故障排查](#故障排查)

## 🚀 快速开始

### 方式1: 一键部署脚本

```bash
# 下载并运行部署脚本
curl -O https://raw.githubusercontent.com/your-username/your-repo/master/deploy.sh
chmod +x deploy.sh
./deploy.sh
```

### 方式2: Docker Compose

```bash
# 下载 docker-compose.yml
curl -O https://raw.githubusercontent.com/your-username/your-repo/master/docker-compose.yml

# 设置环境变量
export REGISTRY="registry.cn-hangzhou.aliyuncs.com"
export NAMESPACE="your-namespace"
export VERSION="latest"

# 启动服务
docker-compose up -d
```

### 方式3: 直接Docker运行

```bash
# 登录阿里云镜像仓库
docker login --username=黄帅啊 registry.cn-hangzhou.aliyuncs.com

# 拉取并运行
docker pull registry.cn-hangzhou.aliyuncs.com/your-namespace/bhuang-mcp-server-sse:latest
docker run -d --name bhuang-mcp-server -p 8080:8080 \
  -e JAVA_OPTS="-Xms512m -Xmx1024m" \
  --restart unless-stopped \
  registry.cn-hangzhou.aliyuncs.com/your-namespace/bhuang-mcp-server-sse:latest
```

## 🔄 GitHub Actions 自动部署

### 前置条件

在GitHub仓库的Settings -> Secrets and variables -> Actions中配置以下密钥：

| 密钥名称 | 描述 | 示例值 |
|---------|------|--------|
| `ALIBABA_CLOUD_REGISTRY` | 阿里云镜像仓库地址 | `registry.cn-hangzhou.aliyuncs.com` |
| `ALIBABA_CLOUD_NAMESPACE` | 镜像命名空间 | `your-namespace` |
| `ALIBABA_CLOUD_USERNAME` | 阿里云账号用户名 | `黄帅啊` |
| `ALIBABA_CLOUD_PASSWORD` | 阿里云镜像仓库密码 | `your-password` |

### 触发条件

工作流程会在以下情况自动触发：

- **Push事件**: 推送到 `main` 或 `master` 分支
- **Pull Request事件**: 对 `main` 或 `master` 分支创建PR

### 工作流程步骤

1. **代码检出** - 获取最新代码
2. **Java环境设置** - 配置JDK 17和Maven缓存
3. **项目构建** - Maven clean package
4. **单元测试** - 运行所有测试用例
5. **Docker构建** - 创建并推送镜像到阿里云
6. **部署总结** - 生成详细的部署报告

## 🛠️ 手动部署

### 本地构建

```bash
# 克隆项目
git clone https://github.com/your-username/your-repo.git
cd your-repo

# 构建项目
mvn clean package -DskipTests

# 运行测试
mvn test

# 构建Docker镜像
docker build -t bhuang-mcp-server-sse:local .

# 运行容器
docker run -d --name bhuang-mcp-server -p 8080:8080 bhuang-mcp-server-sse:local
```

### 推送到阿里云

```bash
# 登录阿里云
docker login --username=黄帅啊 registry.cn-hangzhou.aliyuncs.com

# 标记镜像
docker tag bhuang-mcp-server-sse:local \
  registry.cn-hangzhou.aliyuncs.com/your-namespace/bhuang-mcp-server-sse:latest

# 推送镜像
docker push registry.cn-hangzhou.aliyuncs.com/your-namespace/bhuang-mcp-server-sse:latest
```

## ⚙️ 配置说明

### 环境变量

| 变量名 | 描述 | 默认值 |
|--------|------|--------|
| `JAVA_OPTS` | JVM参数 | `-Xms256m -Xmx512m` |
| `SPRING_PROFILES_ACTIVE` | Spring配置文件 | `prod` |
| `TZ` | 时区设置 | `Asia/Shanghai` |

### 端口配置

| 端口 | 描述 | 协议 |
|------|------|------|
| `8080` | HTTP服务端口 | HTTP |
| `/sse` | SSE连接端点 | SSE |
| `/mcp/messages` | MCP消息端点 | HTTP POST |

### 健康检查端点

| 端点 | 描述 |
|------|------|
| `/actuator/health` | 应用健康状态 |
| `/actuator/info` | 应用信息 |
| `/actuator/metrics` | 应用指标 |

## 📊 监控和维护

### 查看服务状态

```bash
# 容器状态
docker ps | grep bhuang-mcp-server

# 实时日志
docker logs -f bhuang-mcp-server

# 健康检查
curl http://localhost:8080/actuator/health
```

### 性能监控

```bash
# 内存使用
docker stats bhuang-mcp-server

# 应用指标
curl http://localhost:8080/actuator/metrics

# JVM信息
curl http://localhost:8080/actuator/metrics/jvm.memory.used
```

### 日志管理

```bash
# 查看最近100行日志
docker logs --tail 100 bhuang-mcp-server

# 查看特定时间段日志
docker logs --since="2024-01-01T00:00:00" --until="2024-01-01T23:59:59" bhuang-mcp-server

# 导出日志到文件
docker logs bhuang-mcp-server > mcp-server.log 2>&1
```

## 🧪 MCP 客户端测试

### 建立SSE连接

```bash
# 连接SSE端点获取会话ID
curl -N -H "Accept: text/event-stream" http://localhost:8080/sse
```

### 发送MCP消息

```bash
# 初始化请求
curl -X POST "http://localhost:8080/mcp/messages?sessionId=YOUR_SESSION_ID" \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "initialize",
    "params": {
      "protocolVersion": "2024-11-05",
      "capabilities": {"tools": {}},
      "clientInfo": {"name": "test-client", "version": "1.0.0"}
    }
  }'

# 获取工具列表
curl -X POST "http://localhost:8080/mcp/messages?sessionId=YOUR_SESSION_ID" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc": "2.0", "id": 2, "method": "tools/list"}'

# 调用天气工具
curl -X POST "http://localhost:8080/mcp/messages?sessionId=YOUR_SESSION_ID" \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 3,
    "method": "tools/call",
    "params": {
      "name": "getCurrentWeather",
      "arguments": {"location": "北京"}
    }
  }'
```

## 🔧 故障排查

### 常见问题

#### 1. 容器启动失败

```bash
# 查看详细错误信息
docker logs bhuang-mcp-server

# 检查端口占用
netstat -tlnp | grep 8080

# 检查内存使用
free -h
```

#### 2. 镜像拉取失败

```bash
# 检查网络连接
ping registry.cn-hangzhou.aliyuncs.com

# 重新登录
docker login registry.cn-hangzhou.aliyuncs.com

# 手动拉取测试
docker pull registry.cn-hangzhou.aliyuncs.com/your-namespace/bhuang-mcp-server-sse:latest
```

#### 3. SSE连接问题

```bash
# 检查防火墙设置
sudo ufw status

# 测试端口连通性
telnet localhost 8080

# 查看网络配置
docker network ls
```

### 日志分析

#### 应用启动日志

```bash
# 查看启动过程
docker logs bhuang-mcp-server | grep "Started McpServerSseApplication"

# 查看Spring配置加载
docker logs bhuang-mcp-server | grep "Active profiles"
```

#### MCP协议日志

```bash
# 查看MCP连接日志
docker logs bhuang-mcp-server | grep "MCP"

# 查看SSE连接日志
docker logs bhuang-mcp-server | grep "SSE"
```

## 📚 相关文档

- [Model Context Protocol 规范](https://spec.modelcontextprotocol.io/)
- [Spring AI MCP 文档](https://docs.spring.io/spring-ai/reference/api/mcp.html)
- [阿里云容器镜像服务](https://cr.console.aliyun.com/)
- [Docker 官方文档](https://docs.docker.com/)

## 🤝 贡献指南

1. Fork 本仓库
2. 创建特性分支: `git checkout -b feature/new-feature`
3. 提交更改: `git commit -am 'Add new feature'`
4. 推送分支: `git push origin feature/new-feature`
5. 创建 Pull Request

## 📄 许可证

本项目使用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情

## 👨‍💻 作者

**Bhuang** - [GitHub](https://github.com/your-username)

---

⭐ 如果这个项目对您有帮助，请给它一个 Star！