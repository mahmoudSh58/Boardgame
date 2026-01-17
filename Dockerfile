# ===== Runtime Stage =====
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app

# Copy built jar from build stage
COPY  target/*.jar app.jar

# Expose app port
EXPOSE 8080

# Run the app
ENTRYPOINT ["java", "-jar", "app.jar"]
