//package com.bhuang.integration;
//
//import org.junit.jupiter.api.Test;
//import org.springframework.boot.test.context.SpringBootTest;
//import org.springframework.test.context.ActiveProfiles;
//import org.springframework.test.web.reactive.server.WebTestClient;
//import org.springframework.beans.factory.annotation.Autowired;
//import org.springframework.context.ApplicationContext;
//import org.springframework.http.MediaType;
//import org.springframework.test.context.TestPropertySource;
//import org.slf4j.Logger;
//import org.slf4j.LoggerFactory;
//
//import reactor.core.publisher.Flux;
//import reactor.test.StepVerifier;
//
//import java.time.Duration;
//import java.util.concurrent.CountDownLatch;
//import java.util.concurrent.TimeUnit;
//import java.util.concurrent.atomic.AtomicReference;
//
///**
// * 完整的MCP工作流程测试
// * 演示：SSE连接 -> 获取会话ID -> 发送消息请求 -> 接收响应
// */
//@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
//@ActiveProfiles("test")
//@TestPropertySource(properties = {
//    "spring.ai.mcp.server.sse-endpoint=/sse",
//    "spring.ai.mcp.server.sse-message-endpoint=/mcp/messages"
//})
//public class CompleteMcpWorkflowTest {
//
//    private static final Logger log = LoggerFactory.getLogger(CompleteMcpWorkflowTest.class);
//
//    @Autowired
//    private ApplicationContext applicationContext;
//
//    @Test
//    public void testCompleteMcpWorkflow() throws InterruptedException {
//        // 创建WebTestClient
//        WebTestClient webTestClient = WebTestClient.bindToApplicationContext(applicationContext)
//                .configureClient()
//                .responseTimeout(Duration.ofSeconds(30))
//                .build();
//
//        // 第一步：建立SSE连接并等待获得会话ID
//        log.info("第一步：建立SSE连接");
//
//        final CountDownLatch sessionLatch = new CountDownLatch(1);
//        final AtomicReference<String> sessionId = new AtomicReference<>();
//
//        // 开始SSE连接
//        Flux<String> sseStream = webTestClient.get()
//                .uri("/sse")
//                .accept(MediaType.TEXT_EVENT_STREAM)
//                .exchange()
//                .expectStatus().isOk()
//                .expectHeader().contentTypeCompatibleWith(MediaType.TEXT_EVENT_STREAM)
//                .returnResult(String.class)
//                .getResponseBody();
//
//        // 监听SSE事件
//        sseStream.subscribe(
//            event -> {
//                log.info("接收到SSE事件: {}", event);
//
//                // 从SSE响应中解析真实的会话ID
//                if (event.contains("/mcp/messages?sessionId=")) {
//                    // 提取URL中的sessionId参数
//                    String[] parts = event.split("sessionId=");
//                    if (parts.length > 1) {
//                        String extractedSessionId = parts[1].trim();
//                        // 移除可能的其他参数或换行符
//                        int endIndex = extractedSessionId.indexOf('\n');
//                        if (endIndex > 0) {
//                            extractedSessionId = extractedSessionId.substring(0, endIndex);
//                        }
//                        endIndex = extractedSessionId.indexOf('&');
//                        if (endIndex > 0) {
//                            extractedSessionId = extractedSessionId.substring(0, endIndex);
//                        }
//                        sessionId.set(extractedSessionId);
//                        sessionLatch.countDown();
//                        log.info("获得会话ID: {}", sessionId.get());
//                    }
//                }
//            },
//            error -> {
//                log.error("SSE连接错误: ", error);
//                sessionLatch.countDown();
//            },
//            () -> {
//                log.info("SSE连接关闭");
//                sessionLatch.countDown();
//            }
//        );
//
//        // 等待获得会话ID
//        boolean sessionEstablished = sessionLatch.await(10, TimeUnit.SECONDS);
//        if (!sessionEstablished || sessionId.get() == null) {
//            log.warn("未能获得会话ID，使用默认值进行测试");
//            sessionId.set("test-session-default");
//        }
//
//        // 第二步：使用会话ID发送初始化请求
//        log.info("第二步：发送初始化请求，会话ID: {}", sessionId.get());
//
//        String initRequest = """
//            {
//                "jsonrpc": "2.0",
//                "id": 1,
//                "method": "initialize",
//                "params": {
//                    "protocolVersion": "2024-11-05",
//                    "capabilities": {
//                        "tools": {}
//                    },
//                    "clientInfo": {
//                        "name": "test-client",
//                        "version": "1.0.0"
//                    }
//                }
//            }
//            """;
//
//        webTestClient.post()
//                .uri(uriBuilder -> uriBuilder
//                    .path("/mcp/messages")
//                    .queryParam("sessionId", sessionId.get())
//                    .build())
//                .contentType(MediaType.APPLICATION_JSON)
//                .bodyValue(initRequest)
//                .exchange()
//                .expectStatus().isOk()
//                .expectBody()
//                .consumeWith(response -> {
//                    log.info("初始化请求发送成功，状态: 200 OK");
//                    // MCP协议通过SSE返回响应，不需要验证HTTP响应体
//                });
//
//        // 第三步：获取工具列表
//        log.info("第三步：获取工具列表");
//
//        String toolsListRequest = """
//            {
//                "jsonrpc": "2.0",
//                "id": 2,
//                "method": "tools/list"
//            }
//            """;
//
//        webTestClient.post()
//                .uri(uriBuilder -> uriBuilder
//                    .path("/mcp/messages")
//                    .queryParam("sessionId", sessionId.get())
//                    .build())
//                .contentType(MediaType.APPLICATION_JSON)
//                .bodyValue(toolsListRequest)
//                .exchange()
//                .expectStatus().isOk()
//                .expectBody()
//                .consumeWith(response -> {
//                    log.info("工具列表请求发送成功，状态: 200 OK");
//                });
//
//        // 第四步：调用天气工具
//        log.info("第四步：调用天气工具");
//
//        String weatherToolRequest = """
//            {
//                "jsonrpc": "2.0",
//                "id": 3,
//                "method": "tools/call",
//                "params": {
//                    "name": "getCurrentWeather",
//                    "arguments": {
//                        "location": "北京"
//                    }
//                }
//            }
//            """;
//
//        webTestClient.post()
//                .uri(uriBuilder -> uriBuilder
//                    .path("/mcp/messages")
//                    .queryParam("sessionId", sessionId.get())
//                    .build())
//                .contentType(MediaType.APPLICATION_JSON)
//                .bodyValue(weatherToolRequest)
//                .exchange()
//                .expectStatus().isOk()
//                .expectBody()
//                .consumeWith(response -> {
//                    log.info("天气工具请求发送成功，状态: 200 OK");
//                });
//
//        log.info("完整的MCP工作流程测试完成！");
//    }
//
//    @Test
//    public void testSeparateConnectionAndMessage() {
//        // 创建WebTestClient
//        WebTestClient webTestClient = WebTestClient.bindToApplicationContext(applicationContext)
//                .configureClient()
//                .responseTimeout(Duration.ofSeconds(10))
//                .build();
//
//        log.info("测试分离的连接和消息处理");
//
//        // 测试SSE连接
//        webTestClient.get()
//                .uri("/sse")
//                .accept(MediaType.TEXT_EVENT_STREAM)
//                .exchange()
//                .expectStatus().isOk()
//                .expectHeader().contentTypeCompatibleWith(MediaType.TEXT_EVENT_STREAM);
//
//        log.info("SSE连接测试通过");
//
//        // 测试没有会话ID的消息请求应该失败
//        String requestWithoutSession = """
//            {
//                "jsonrpc": "2.0",
//                "id": 1,
//                "method": "tools/list"
//            }
//            """;
//
//        webTestClient.post()
//                .uri("/mcp/messages")
//                .contentType(MediaType.APPLICATION_JSON)
//                .bodyValue(requestWithoutSession)
//                .exchange()
//                .expectStatus().isBadRequest()
//                .expectBody()
//                .consumeWith(response -> {
//                    String body = new String(response.getResponseBody());
//                    log.info("预期的错误响应: {}", body);
//                });
//
//        log.info("消息端点会话验证测试通过");
//    }
//}