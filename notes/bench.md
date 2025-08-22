# Benchmarks

## Naive

### Memory Footprint

`jcmd 214 VM.native_memory summary scale=MB | awk -F'[=,]' '/Total:/ {print $4}'`

Commited: 200MB (actually commited memory is more interesting than the reserved one, despite the latter being 5GB! This is due to commited being the memory actually in use, but the reserved part is what the JVM asked the OS to reserve for it, should the need arise)

`docker stats --no-stream --format=json 1dd1ad512b36 | jq -r '.MemUsage' | cut -d '/' -f1`

--> 883.3 MB

### Image size

`docker image inspect e278c2250a7b --format=json | jq -r '.[0].Size' | numfmt --to=si`

--> 794M

### Build Time

No relevant stats here, bc there is no build! We literally run directly! The docker build time is heavily impacted on the size of the base image and the internet connection, so you can try out yourself how long it takes you to pull that much memory!

### Startup time

~ 25s. Measured with time. Here however, it is mostly affected by the compilation part, which has to happen before run. We will split and measure the two better in the following.

## Multi-stage


