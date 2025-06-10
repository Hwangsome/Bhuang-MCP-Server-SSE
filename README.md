# Weather Service MCP Server

这是一个基于Spring AI和WebFlux的天气服务MCP（Model Context Protocol）服务器，使用SSE（Server-Sent Events）传输协议。

## 功能特性

### 🛠️ 工具（Tools）
- **getWeatherForecastByLocation**: 根据经纬度获取详细天气预报
- **getWeatherForecastByCity**: 根据城市名称获取天气预报
- **getCurrentWeather**: 获取当前天气状况
- **getAlerts**: 获取美国各州的天气警报

### 📚 资源（Resources）
- **weather://service/info**: 天气服务信息
- **weather://cities/supported**: 支持的城市列表

### 💬 提示（Prompts）
- **weather-query**: 天气查询助手，支持不同类型的天气查询

## 技术栈

- **Spring Boot 3.5.0**: 应用程序框架
- **Spring AI 1.0.0**: AI集成框架
- **Spring WebFlux**: 响应式Web框架
- **MCP (Model Context Protocol)**: 与AI模型的标准化通信协议
- **National Weather Service API**: 数据源

## 支持的城市

以下城市支持通过名称查询：
- Seattle, WA
- New York, NY
- Los Angeles, CA
- Chicago, IL
- Houston, TX
- Phoenix, AZ
- Philadelphia, PA
- San Antonio, TX
- San Diego, CA
- Dallas, TX

对于其他城市，请使用经纬度坐标。

## 快速开始

### 1. 构建和运行

```bash
# 构建项目
mvn clean compile

# 运行应用
mvn spring-boot:run
```

应用将在 `http://localhost:8080` 启动。

### 2. MCP端点

- **SSE连接端点**: `http://localhost:8080/sse`
- **消息端点**: `http://localhost:8080/mcp/messages`

### 3. 作为MCP客户端连接

在支持MCP的客户端中，配置连接：

```json
{
  "name": "weather-service",
  "type": "sse",
  "url": "http://localhost:8080",
  "sse-endpoint": "/sse"
}
```

### 4. 健康检查

```bash
curl http://localhost:8080/actuator/health
```

## 配置选项

主要配置位于 `application.yml` 中：

```yaml
spring:
  ai:
    mcp:
      server:
        name: weather-service-mcp-server
        version: 1.0.0
        type: ASYNC
        sse-endpoint: /sse
        sse-message-endpoint: /mcp/messages
        request-timeout: 30s
```

## 使用示例

### 通过MCP客户端查询天气

1. **获取纽约天气预报**:
   ```
   "给我查询纽约的天气预报"
   ```

2. **获取特定坐标的当前天气**:
   ```
   "查询北纬40.7128度，西经74.0060度的当前天气"
   ```

3. **查询加州的天气警报**:
   ```
   "查询加州是否有天气警报"
   ```

## 日志

日志文件将保存在 `logs/weather-mcp-server.log`。

日志级别配置：
- 应用程序日志: INFO
- MCP协议日志: DEBUG
- WebFlux日志: INFO

## 开发说明

### 添加新工具

1. 在 `WeatherService` 类中添加新方法
2. 使用 `@Tool` 注解标记方法
3. 提供清晰的描述和参数注解

示例：
```java
@Tool(description = "获取紫外线指数")
public String getUVIndex(@ToolParam(description = "纬度") double latitude, 
                        @ToolParam(description = "经度") double longitude) {
    // 实现逻辑
}
```

### 添加新资源

在 `McpConfig` 类中的 `weatherResources()` 方法中添加新的资源规范。

### 添加新提示

在 `McpConfig` 类中的 `weatherPrompts()` 方法中添加新的提示规范。

## 故障排除

### 常见问题

1. **连接失败**: 检查防火墙设置和端口8080是否可用
2. **工具调用失败**: 检查网络连接到 api.weather.gov
3. **SSE连接断开**: 检查客户端是否正确实现了SSE重连机制

### 调试

启用详细日志：
```yaml
logging:
  level:
    org.springframework.ai.mcp: TRACE
    com.bhuang: DEBUG
```

## 许可证

Apache License 2.0

## 贡献

欢迎提交Issue和Pull Request！