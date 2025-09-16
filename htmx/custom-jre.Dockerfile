FROM gradle:8.14.3-jdk21@sha256:42b9c012cb77c139f743e452a411ad26fb521a8fc0956265df2dca45b45e22f9 AS build

WORKDIR /app
COPY . .

RUN gradle bootJar

FROM eclipse-temurin:21@sha256:2b9cd724df3c0797032bfcfebd268ba89e80a77e93c791c4cecd4d5e1202e027 AS custom-jre

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

FROM debian:12-slim@sha256:df52e55e3361a81ac1bead266f3373ee55d29aa50cf0975d440c2be3483d8ed3

WORKDIR /prod
COPY --from=custom-jre /custom/jre jre
COPY --from=build /app/build/libs/naive-0.0.1-SNAPSHOT.jar app.jar

RUN apt-get -qqy update && \
    apt-get -qqy install --no-install-recommends wget && \
    rm -rf /var/lib/apt/lists/*

ENV PATH="/prod/jre/bin:$PATH"

HEALTHCHECK --interval=5s --timeout=15s --start-period=20s --retries=20 CMD ["wget", "-q", "--spider", "http://localhost:8080/actuator/health"]
ENTRYPOINT [ "java", "-jar", "app.jar" ]
