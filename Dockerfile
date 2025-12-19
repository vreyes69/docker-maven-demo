FROM eclipse-temurin:17-jre

WORKDIR /app

ARG JAR_FILE
COPY target/${JAR_FILE}.jar app.jar

ENV TZ=Asia/Shanghai
ENV JAVA_OPTS=""

ENTRYPOINT ["sh","-c","java $JAVA_OPTS -jar app.jar"]
