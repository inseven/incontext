#!/usr/bin/env bash

# Copyright (c) 2016-2026 Jason Morley
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

set -e
set -o pipefail
set -x
set -u

ROOT_DIRECTORY="$( cd "$( dirname "$( dirname "${BASH_SOURCE[0]}" )" )" &> /dev/null && pwd )"
ARTIFACTS_DIRECTORY="$ROOT_DIRECTORY/artifacts"
BUILD_DIRECTORY="$ROOT_DIRECTORY/build"
SCRIPTS_DIRECTORY="$ROOT_DIRECTORY/scripts"

ENV_PATH="$ROOT_DIRECTORY/.env"
RELEASE_SCRIPT_PATH="$SCRIPTS_DIRECTORY/gh-release.sh"

source "$SCRIPTS_DIRECTORY/environment.sh"

# Check that the GitHub command is available on the path.
which gh || (echo "GitHub cli (gh) not available on the path." && exit 1)

# Process the command line arguments.
POSITIONAL=()
RELEASE=${RELEASE:-false}
while [[ $# -gt 0 ]]
do
    key="$1"
    case $key in
        -r|--release)
        RELEASE=true
        shift
        ;;
        *)
        POSITIONAL+=("$1")
        shift
        ;;
    esac
done

# Source the .env file if it exists to make local development easier.
if [ -f "$ENV_PATH" ] ; then
    echo "Sourcing .env..."
    source "$ENV_PATH"
fi

cd "$ROOT_DIRECTORY"

# Clean up and recreate the output directories.
if [ -d "$BUILD_DIRECTORY" ] ; then
    rm -r "$BUILD_DIRECTORY"
fi
mkdir -p "$BUILD_DIRECTORY"

# List the artifacts.
find "$ARTIFACTS_DIRECTORY"

# Copy the artifacts to the builds directory, adding each to the manifest.

cd "$BUILD_DIRECTORY"

GIT_SHA=`git rev-parse HEAD`

# macOS.

INCONTEXT_MACOS_NAME="incontext-$VERSION_NUMBER-$BUILD_NUMBER.zip"
INCONTEXT_HELPER_MACOS_NAME="InContext-Helper-$VERSION_NUMBER-$BUILD_NUMBER.zip"

cp "$ARTIFACTS_DIRECTORY/incontext-macos/$INCONTEXT_MACOS_NAME" "$INCONTEXT_MACOS_NAME"
cp "$ARTIFACTS_DIRECTORY/incontext-macos/$INCONTEXT_HELPER_MACOS_NAME" "$INCONTEXT_HELPER_MACOS_NAME"
cp "$ARTIFACTS_DIRECTORY/incontext-macos/appcast.xml" appcast.xml

build-tools add-artifact manifest.json \
    --project incontext \
    --version "$VERSION_NUMBER" \
    --build-number "$BUILD_NUMBER" \
    --path "$INCONTEXT_MACOS_NAME" \
    --format zip \
    --git-sha "$GIT_SHA" \
    --supports-os macos \
    --supports-version 26 \
    --supports-codename tahoe \
    --supports-architecture arm64 \
    --supports-architecture x86_64

# Ubuntu.

INCONTEXT_UBUNTU_RESOLUTE_AMD64_NAME="incontext_${VERSION_NUMBER}-resolute${BUILD_NUMBER}_amd64.deb"
cp "$ARTIFACTS_DIRECTORY/incontext-ubuntu-resolute-amd64/incontext.deb" "$INCONTEXT_UBUNTU_RESOLUTE_AMD64_NAME"

build-tools add-artifact manifest.json \
    --project incontext \
    --version "$VERSION_NUMBER" \
    --build-number "$BUILD_NUMBER" \
    --path "$INCONTEXT_UBUNTU_RESOLUTE_AMD64_NAME" \
    --format deb \
    --git-sha "$GIT_SHA" \
    --supports-os ubuntu \
    --supports-version 26.04 \
    --supports-codename resolute \
    --supports-architecture amd64

INCONTEXT_UBUNTU_RESOLUTE_ARM64_NAME="incontext_${VERSION_NUMBER}-resolute${BUILD_NUMBER}_arm64.deb"
cp "$ARTIFACTS_DIRECTORY/incontext-ubuntu-resolute-arm64/incontext.deb" "$INCONTEXT_UBUNTU_RESOLUTE_ARM64_NAME"

build-tools add-artifact manifest.json \
    --project incontext \
    --version "$VERSION_NUMBER" \
    --build-number "$BUILD_NUMBER" \
    --path "$INCONTEXT_UBUNTU_RESOLUTE_ARM64_NAME" \
    --format deb \
    --git-sha "$GIT_SHA" \
    --supports-os ubuntu \
    --supports-version 26.04 \
    --supports-codename resolute \
    --supports-architecture arm64

if $RELEASE ; then

    changes \
        release \
        --skip-if-empty \
        --push \
        --exec "$RELEASE_SCRIPT_PATH" \
        "$BUILD_DIRECTORY/$INCONTEXT_MACOS_NAME" \
        "$BUILD_DIRECTORY/$INCONTEXT_HELPER_MACOS_NAME" \
        "$BUILD_DIRECTORY/appcast.xml" \
        "$BUILD_DIRECTORY/$INCONTEXT_UBUNTU_RESOLUTE_AMD64_NAME" \
        "$BUILD_DIRECTORY/$INCONTEXT_UBUNTU_RESOLUTE_ARM64_NAME" \
        "$BUILD_DIRECTORY/manifest.json"

fi
