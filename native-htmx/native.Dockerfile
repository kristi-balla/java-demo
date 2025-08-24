FROM container-registry.oracle.com/graalvm/native-image:21-muslib AS builder
WORKDIR /workspace

RUN microdnf -y install wget xz unzip zip findutils && \
    wget -O grandel.zip https://services.gradle.org/distributions/gradle-8.14-bin.zip && \
    unzip grandel.zip -d /opt

COPY . .

ENV GRADLE_HOME="/opt/gradle-8.14"
ENV PATH="$GRADLE_HOME/bin:$PATH"
RUN gradle clean nativeCompile

FROM gcr.io/distroless/static-debian12:debug
COPY --from=builder /workspace/build/native/nativeCompile/htmx /app

HEALTHCHECK --interval=5s --timeout=15s --start-period=2s --retries=20 CMD ["wget", "-q", "--spider", "http://localhost:8080/actuator/health"]
ENTRYPOINT [ "/app" ]
