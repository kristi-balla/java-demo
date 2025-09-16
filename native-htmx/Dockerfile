FROM container-registry.oracle.com/graalvm/native-image:21-muslib@sha256:f7a03f727b78b31af4b274f60ffdd2879893f1cb9dca58cc56304e9e78a22554 AS builder
WORKDIR /workspace

ARG UPX_VERSION=4.2.2
ARG UPX_ARCHIVE=upx-${UPX_VERSION}-amd64_linux.tar.xz
RUN microdnf -y install wget xz unzip zip findutils && \
    wget -q https://github.com/upx/upx/releases/download/v${UPX_VERSION}/${UPX_ARCHIVE} && \
    tar -xJf ${UPX_ARCHIVE} && \
    rm -rf ${UPX_ARCHIVE} && \
    mv upx-${UPX_VERSION}-amd64_linux/upx . && \
    rm -rf upx-${UPX_VERSION}-amd64_linux && \
    wget -O grandel.zip https://services.gradle.org/distributions/gradle-8.14-bin.zip && \
    unzip grandel.zip -d /opt

COPY . .

ENV GRADLE_HOME="/opt/gradle-8.14"
ENV PATH="$GRADLE_HOME/bin:$PATH"
RUN gradle clean nativeCompile
RUN ./upx --best -o app.upx /workspace/build/native/nativeCompile/htmx

FROM gcr.io/distroless/static-debian12:debug@sha256:c7f818f4678fe4ceb0412a370e8e41ca373d5dde25039b84f9cccb72ef558542
COPY --from=builder /workspace/app.upx /app

HEALTHCHECK --interval=5s --timeout=15s --start-period=2s --retries=20 CMD ["wget", "-q", "--spider", "http://localhost:8080/actuator/health"]
ENTRYPOINT [ "/app" ]
