#!/bin/bash

set -e

cd /mnt/build
cmake -j$(nproc) /mnt/source
make -j $(nproc)
