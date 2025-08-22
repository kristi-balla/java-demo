FROM gradle:8.14.3-jdk21 AS build

WORKDIR /app
COPY . .

HEALTHCHECK --interval=5s --timeout=3s --start-period=5s --retries=10 CMD curl -f http://localhost:8080/actuator/health || exit 1
CMD [ "gradle", "bootRun" ]
