FROM gradle:8.14.3-jdk21 AS build

WORKDIR /app
COPY . .

RUN gradle bootJar

FROM gcr.io/distroless/java21-debian12:debug

COPY --from=build /app/build/libs/naive-0.0.1-SNAPSHOT.jar app.jar

HEALTHCHECK --interval=5s --timeout=15s --start-period=20s --retries=20 CMD ["wget", "-q", "--spider", "http://localhost:8080/actuator/health"]
ENTRYPOINT [ "java", "-jar", "app.jar" ]
