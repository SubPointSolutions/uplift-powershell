#!/bin/bash

buildImageTag="subpointsolutions/invoke-uplift:build"
echo "Building container: $buildImageTag"

docker build \
    -t $buildImageTag \
    .

[ $? -ne 0 ] && echo "Failed container build" && exit 1

echo "Completed!"

exit 