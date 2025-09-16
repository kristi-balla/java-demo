FROM gradle:8.14.3-jdk21@sha256:42b9c012cb77c139f743e452a411ad26fb521a8fc0956265df2dca45b45e22f9 AS build

WORKDIR /app
COPY . .

HEALTHCHECK --interval=5s --timeout=3s --start-period=5s --retries=10 CMD curl -f http://localhost:8080/actuator/health || exit 1
CMD [ "gradle", "bootRun" ]
