# syntax=docker/dockerfile:1.7

# ---------- Stage 1: build ----------
FROM maven:3.9.9-eclipse-temurin-21 AS build

WORKDIR /workspace

COPY pom.xml ./
RUN mvn -B -ntp dependency:go-offline

COPY src ./src
RUN mvn -B -ntp package -DskipTests

# ---------- Stage 2: runtime ----------
FROM eclipse-temurin:21-jre

ENV SPRING_PROFILES_ACTIVE=docker

WORKDIR /app

COPY --from=build /workspace/target/*.jar /app/app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "/app/app.jar"]
