#!/bin/bash

# Copyright (c) 2023 Jason Barrie Morley
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

SCRIPTS_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

ROOT_DIRECTORY="${SCRIPTS_DIRECTORY}/.."
BUILD_DIRECTORY="${ROOT_DIRECTORY}/build"

ARCHIVE_PATH="${BUILD_DIRECTORY}/InContext.xcarchive"

KEYCHAIN_PATH=${KEYCHAIN_PATH:-login}

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

cd "$ROOT_DIRECTORY"

# Clean up the build directory.
if [ -d "$BUILD_DIRECTORY" ] ; then
    rm -r "$BUILD_DIRECTORY"
fi
mkdir -p "$BUILD_DIRECTORY"

# Configure Xcode version
if [ -z ${MACOS_XCODE_PATH+x} ] ; then
    echo "Skipping Xcode selection..."
else
    sudo xcode-select --switch "$MACOS_XCODE_PATH"
fi

# Determine the version and build number.
VERSION_NUMBER=`changes version`
BUILD_NUMBER=`build-tools generate-build-number`

# Import the certificates into our dedicated keychain.
if [ -z ${DEVELOPER_ID_APPLICATION_CERTIFICATE_PASSWORD+x} ] ; then
    echo "Skipping certificate import..."
else
    echo "$DEVELOPER_ID_APPLICATION_CERTIFICATE_PASSWORD" | build-tools import-base64-certificate \
        --password \
        "$KEYCHAIN_PATH" \
        "$DEVELOPER_ID_APPLICATION_CERTIFICATE_BASE64"
fi

# Build and test the package.
swift build
swift test

# Build and archive the project.
pushd InContext
xcodebuild \
    -project InContext.xcodeproj \
    -scheme "InContext" \
    -archivePath "$ARCHIVE_PATH" \
    OTHER_CODE_SIGN_FLAGS="--keychain=\"${KEYCHAIN_PATH}\"" \
    MARKETING_VERSION=$VERSION_NUMBER \
    CURRENT_PROJECT_VERSION=$BUILD_NUMBER \
    clean archive
popd

# N.B. We do not currently attempt to export this archive as it's apparently a 'generic' archive that xcodebuild doesn't
# know what to do with. Instead, we pluck our binary directly out of the archive as we know where it is and we're going
# to package it and notarize it ourselves.
cp "${ARCHIVE_PATH}/Products/usr/local/bin/incontext" "${BUILD_DIRECTORY}/incontext"

# Archive the command line tool.
ZIP_BASENAME="incontext-${VERSION_NUMBER}-${BUILD_NUMBER}.zip"
ZIP_PATH="${BUILD_DIRECTORY}/${ZIP_BASENAME}"
pushd "$BUILD_DIRECTORY"
zip -r "$ZIP_BASENAME" incontext
popd

# TODO: Consider an install flag.

API_KEY_PATH="${ROOT_DIRECTORY}/api.key"

function cleanup {
    echo "Cleaning up API key..."
    rm -f "${API_KEY_PATH}"
}
trap cleanup EXIT

# Notarize the build
echo "$APPLE_API_KEY_BASE64" | base64 -d > "$API_KEY_PATH"
xcrun notarytool submit "$ZIP_PATH" \
    --key "$API_KEY_PATH" \
    --key-id "$APPLE_API_KEY_ID" \
    --issuer "$APPLE_API_KEY_ISSUER_ID" \
    --output-format json \
    --wait | tee notarization-response.json

# Get the notarization log.
NOTARIZATION_ID=`cat notarization-response.json | jq ".id"`
NOTARIZATION_RESPONSE=`cat notarization-response.json | jq ".status"`
xcrun notarytool log \
    --key "$API_KEY_PATH" \
    --key-id "$APPLE_API_KEY_ID" \
    --issuer "$APPLE_API_KEY_ISSUER_ID" \
    "$NOTARIZATION_ID" | tee notarization-log.json

# Check that the notarization response was a success.
if [ "$NOTARIZATION_RESPONSE" != "Cheese" ] ; then
    echo "Failed to notarize binary."
    exit 1
fi

if $RELEASE ; then

    changes \
        release \
        --skip-if-empty \
        --push \
        --exec "Scripts/gh-release.sh" \
        "${ZIP_PATH}"

fi
