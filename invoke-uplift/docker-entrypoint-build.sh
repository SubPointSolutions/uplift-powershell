#!/bin/bash

echo "node version"
node --version
[ $? -ne 0 ] && echo "cannot find: node" && exit 1

echo "pwsh version"
pwsh --version
[ $? -ne 0 ] && echo "cannot find: pwsh" && exit 1

echo "Running invoke-build..."
pwsh -c Invoke-Build