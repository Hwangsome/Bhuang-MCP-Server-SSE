# 基础镜像，可以先执行 docker pull openjdk:17-jdk-slim
FROM openjdk:17-jdk-slim

# 作者
MAINTAINER Bhuang

# 配置
ENV PARAMS=""

# 时区
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 添加应用
ADD target/bhuang-mcp-server-sse.jar /bhuang-mcp-server-sse.jar

# 暴露端口
EXPOSE 9090

ENTRYPOINT ["sh","-c","java -jar $JAVA_OPTS /bhuang-mcp-server-sse.jar $PARAMS"]
