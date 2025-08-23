FROM gradle:8.14.3-jdk21 AS build

WORKDIR /app
COPY . .

RUN gradle bootJar

FROM eclipse-temurin:21 AS custom-jre

WORKDIR /custom

COPY --from=build /app/build/libs/naive-0.0.1-SNAPSHOT.jar app.jar

# since springboot produces fat jars, i need to take them apart to figure out what is actually needed
RUN jar -xf app.jar

RUN jdeps \
    --ignore-missing-deps \
    --recursive \
    --multi-release 21 \
    --print-module-deps \
    --class-path 'BOOT-INF/lib/*' \
    app.jar > dependencies.txt

RUN jlink \
    --no-header-files \
    --no-man-pages \
    --compress=zip-9 \
    --strip-debug \
    --add-modules $(cat dependencies.txt) \
    --output jre

FROM debian:12-slim

WORKDIR /prod
COPY --from=custom-jre /custom/jre jre
COPY --from=build /app/build/libs/naive-0.0.1-SNAPSHOT.jar app.jar

RUN apt-get -qqy update && \
    apt-get -qqy install --no-install-recommends wget && \
    rm -rf /var/lib/apt/lists/*

ENV PATH="/prod/jre/bin:$PATH"

HEALTHCHECK --interval=5s --timeout=15s --start-period=20s --retries=20 CMD ["wget", "-q", "--spider", "http://localhost:8080/actuator/health"]
ENTRYPOINT [ "java", "-jar", "app.jar" ]
