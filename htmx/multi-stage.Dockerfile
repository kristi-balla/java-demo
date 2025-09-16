FROM gradle:8.14.3-jdk21@sha256:42b9c012cb77c139f743e452a411ad26fb521a8fc0956265df2dca45b45e22f9 AS build

WORKDIR /app
COPY . .

RUN gradle bootJar

FROM gcr.io/distroless/java21-debian12:debug@sha256:ad62143d5f59c87c979b1698123e9be07a19484b4e3e0c3a257dc93672432b34

COPY --from=build /app/build/libs/naive-0.0.1-SNAPSHOT.jar app.jar

HEALTHCHECK --interval=5s --timeout=15s --start-period=20s --retries=20 CMD ["wget", "-q", "--spider", "http://localhost:8080/actuator/health"]
ENTRYPOINT [ "java", "-jar", "app.jar" ]
