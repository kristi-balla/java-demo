#!/usr/bin/env bash
set -euo pipefail

# usage: ./benchmark.sh <image-tag> <dockerfile>
# example: ./benchmark.sh naive:v01 naive.Dockerfile

log() {
  GREEN='\033[0;32m'
  NC='\033[0m' # no color
  echo -e "${GREEN}$1${NC}"
}

IMAGE=$1
DOCKERFILE=$2
NAME=test-$IMAGE
CIDFILE=$(mktemp)
CSVOUT=results.csv

log "▶️ Measuring for image: $IMAGE (from $DOCKERFILE)"

# --- BUILD TIME ---
build_start=$(date +%s%3N)
docker build --no-cache -t "$IMAGE" -f "$DOCKERFILE" htmx/
build_end=$(date +%s%3N)
build_time_ms=$(($build_end - $build_start))
log "Build time: ${build_time_ms} ms"

# --- IMAGE SIZE ---
img_size=$(docker image inspect "$IMAGE" --format='{{.Size}}' | numfmt --to=si)
log "Image size: $img_size"

# --- START CONTAINER ---
cid=$(docker run -p 8080:8080 -d --rm --name $NAME "$IMAGE")
log "Container ID: $cid"

# --- STARTUP TIME ---
start_ts=$(date +%s%3N)
while [ "`docker inspect -f {{.State.Health.Status}} $cid`" != "healthy" ]; do sleep 0.1; done
end_ts=$(date +%s%3N)
startup_ms=$(($end_ts - $start_ts))
log "Startup time: ${startup_ms} ms"

# --- CONTAINER MEMORY USAGE ---
cont_mem=$(docker stats --no-stream --format=json "$cid" | jq -r '.MemUsage' | cut -d '/' -f1)
log "Container memory usage: $cont_mem"

# --- APPLICATION MEMORY FOOTPRINT ---
pid=$(docker logs "$cid" 2>&1 | sed -nE 's/.*PID[[:space:]]+([0-9]+).*/\1/p')
footprint=$(docker exec "$cid" awk '/VmRSS/ {print $(NF-1), $NF}' /proc/$pid/status)
log "Application memory footprint (VmRSS): ${footprint}"

# --- CLEANUP ---
docker stop "$cid" >/dev/null

# --- WRITE TO CSV ---
if [ ! -f "$CSVOUT" ]; then
  echo "image,build_time(ms),image_size,startup_time(ms),container_memory,app_memory(MB)" > "$CSVOUT"
fi
echo "$IMAGE,$build_time_ms,$img_size,$startup_ms,$cont_mem,$footprint" >> "$CSVOUT"

log "✅ Done for $IMAGE. Results appended to $CSVOUT"
