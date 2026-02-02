# ============================================
# BUILD STAGE
# ============================================
FROM maven:3.8.7-openjdk-11 AS builder

# Set working directory
WORKDIR /app

# Copy pom.xml first (for layer caching)
COPY pom.xml .

# Download dependencies (cached layer)
RUN mvn dependency:go-offline -B

# Copy source code
COPY src ./src

# Build application
RUN mvn clean package -DskipTests \
    -Dmaven.test.skip=true \
    -Dmaven.javadoc.skip=true

# ============================================
# RUNTIME STAGE
# ============================================
FROM openjdk:11-jre-slim

# Set labels
LABEL maintainer="devops@company.com"
LABEL version="1.0"
LABEL description="Java Microservice"

# Create non-root user
RUN groupadd -r spring && useradd -r -g spring spring

# Set working directory
WORKDIR /app

# Copy JAR from builder stage
COPY --from=builder --chown=spring:spring /app/target/*.jar app.jar

# Switch to non-root user
USER spring

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/api/health || exit 1

# Expose port
EXPOSE 8080

# JVM optimizations for containers
ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -Djava.security.egd=file:/dev/./urandom"

# Run application
ENTRYPOINT ["sh", "-c", "java ${JAVA_OPTS} -jar app.jar"]
