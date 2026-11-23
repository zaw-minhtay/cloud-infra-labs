# Items API image for Lab 01 (aws). Both base images come from ECR Public, so CodeBuild never
# hits Docker Hub rate limits.

# ---- Build stage: Maven on Amazon Corretto 25. `mvn package` also runs the unit tests,
# ---- so a failing test fails the image build (and the pipeline).
FROM public.ecr.aws/docker/library/maven:3.9.16-amazoncorretto-25-al2023 AS build
WORKDIR /src
COPY pom.xml .
RUN mvn -B -q dependency:go-offline
COPY src ./src
RUN mvn -B package

# ---- Runtime stage: Amazon Corretto 25, headless (no desktop libraries).
FROM public.ecr.aws/amazoncorretto/amazoncorretto:25.0.5-al2023-headless

# CodeBuild passes the Git commit ID here; the app shows it at GET /.
ARG APP_VERSION=dev
ENV APP_VERSION=${APP_VERSION} \
    JAVA_TOOL_OPTIONS="-XX:MaxRAMPercentage=75 -Dsun.net.inetaddr.ttl=5"
# MaxRAMPercentage: size the heap from the task's memory limit.
# inetaddr.ttl=5: re-resolve the Aurora endpoint quickly after a failover.

WORKDIR /app
COPY --from=build /src/target/items-api.jar app.jar

# Run as a non-root user (matches the ECS task definition).
USER 10001
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
