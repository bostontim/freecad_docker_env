#!/bin/bash

set -e

cd /mnt/build
cmake -j$(nproc) -DBOOST_ROOT=/usr/local/include/boost \
    -DBUILD_QT5=ON -DBUILD_FEM=OFF -DBUILD_SANDBOX=ON \
    -DPYTHON_LIBRARY=/usr/local/lib/libpython3.7.a \
    -DPYTHON_INCLUDE_DIR=/usr/local/include/python3.7 \
    -DPYTHON_PACKAGES_PATH=/usr/local/lib/python3.7/site-packages \
    -DPYTHON_EXECUTABLE=/usr/local/bin/python3 \
    /mnt/source
make -j $(nproc)
