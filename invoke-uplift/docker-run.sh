#!/bin/bash

buildImageTag="subpointsolutions/invoke-uplift:build"

chmod +x docker-entrypoint-build.sh 
chmod +x src/docker-build.sh

echo "Building container..."
sh -c 'cd src && sh docker-build.sh'
[ $? -ne 0 ] && echo "Failed to build container" && exit 1

echo "Running container..."
docker run --rm \
    --entrypoint /app/docker-entrypoint-build.sh \
    -v "$(pwd):/app" \
    $buildImageTag

# emergency debugging in -it mode 

# docker run --rm -it \
#     --entrypoint bash \
#     -v "$(pwd):/app" \
#     $buildImageTag

[ $? -ne 0 ] && echo "Failed to run container build" && exit 1

echo "Completed!"

exit 0