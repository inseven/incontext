#!/usr/bin/env bash

set -e
set -o pipefail
set -x
set -u

export SWIFT_BIN=$PWD/swift-5.10-RELEASE-ubuntu22.04/usr/bin

if [ ! -d "$SWIFT_BIN" ] ; then
    curl -O https://download.swift.org/swift-5.10-release/ubuntu2204/swift-5.10-RELEASE/swift-5.10-RELEASE-ubuntu22.04.tar.gz
    tar -zxvf swift-5.10-RELEASE-ubuntu22.04.tar.gz
fi

export PATH=$PATH:$SWIFT_BIN

# Remove the build directory if it exists to force a full rebuild.
if [ -d .build ] ; then
    rm -rf .build
fi

# Determine the version and build number.
# We expect these to be injected in by our GitHub build job so we just ensure there are sensible defaults.
VERSION_NUMBER=${VERSION_NUMBER:-0.0.0}
BUILD_NUMBER=${BUILD_NUMBER:-0}

# Run the tests.
swift test

# Build the project.
swift build -Xcc "-DVERSION_NUMBER=\"$VERSION_NUMBER\"" -Xcc "-DBUILD_NUMBER=\"$BUILD_NUMBER\""

# Double-check the reported version.
EXPECTED_VERSION="$VERSION_NUMBER $BUILD_NUMBER"
ACTUAL_VERSION=`.build/debug/incontext --version`
if [[ "$ACTUAL_VERSION" != "$EXPECTED_VERSION"* ]] ; then
    echo "Error: Expected '$BINARY_PATH --version' to start with '$EXPECTED_VERSION', got '$ACTUAL_VERSION'." >&2
    exit 1
fi
