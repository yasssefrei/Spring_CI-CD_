# -----------------------
# 1. Build stage (Maven)
# -----------------------
FROM maven:3.8.8-openjdk-17 AS build
WORKDIR /app

# Copier le pom et pré-télécharger les dépendances
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copier le code source et compiler
COPY src ./src
RUN mvn clean package -DskipTests -B

# -------------------------------
# 2. Runtime stage (Java 17 slim)
# -------------------------------
FROM openjdk:17-jdk-slim
WORKDIR /app

# Copier le JAR généré
COPY --from=build /app/target/*.jar app.jar

# Exposer le port Spring Boot
EXPOSE 8080

# Commande de démarrage
ENTRYPOINT ["java", "-jar", "app.jar"]
