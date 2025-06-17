# 1. Build stage
FROM maven:3.8.8-openjdk-17 AS build
WORKDIR /app

# Pré‑télécharger les dépendances
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Compiler le projet
COPY src ./src
RUN mvn clean package -DskipTests -B

# 2. Runtime stage
FROM openjdk:17-jdk-slim
WORKDIR /app

COPY --from=build /app/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
