#!/bin/bash

# Copyright (c) 2016-2024 Jason Morley
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
ARCHIVES_DIRECTORY="${ROOT_DIRECTORY}/archives"
SPARKLE_DIRECTORY="${SCRIPTS_DIRECTORY}/Sparkle"

CLI_ARCHIVE_PATH="${BUILD_DIRECTORY}/Command.xcarchive"
HELPER_ARCHIVE_PATH="${BUILD_DIRECTORY}/Helper.xcarchive"

KEYCHAIN_PATH=${KEYCHAIN_PATH:-login}

RELEASE_SCRIPT_PATH="${SCRIPTS_DIRECTORY}/release.sh"

RELEASE_NOTES_TEMPLATE_PATH="${SCRIPTS_DIRECTORY}/release-notes.html"

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

# Clean up and recreate the output directories.

if [ -d "$BUILD_DIRECTORY" ] ; then
    rm -r "$BUILD_DIRECTORY"
fi
mkdir -p "$BUILD_DIRECTORY"

if [ -d "$ARCHIVES_DIRECTORY" ] ; then
    rm -r "$BUILD_DIRECTORY"
fi
mkdir -p "$ARCHIVES_DIRECTORY"

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

pushd InContext

    # Install the provisioning profiles.
    build-tools install-provisioning-profile "InContext_Helper_Developer_ID_Profile.provisionprofile"

    # Build and archive the command.
    xcodebuild \
        -project InContext.xcodeproj \
        -scheme "InContext" \
        -archivePath "$CLI_ARCHIVE_PATH" \
        OTHER_CODE_SIGN_FLAGS="--keychain=\"${KEYCHAIN_PATH}\"" \
        MARKETING_VERSION=$VERSION_NUMBER \
        CURRENT_PROJECT_VERSION=$BUILD_NUMBER \
        clean archive

    # Build and archive the helper.
    xcodebuild \
        -project InContext.xcodeproj \
        -scheme "InContext Helper" \
        -archivePath "$HELPER_ARCHIVE_PATH" \
        MARKETING_VERSION=$VERSION_NUMBER \
        CURRENT_PROJECT_VERSION=$BUILD_NUMBER \
        clean archive

popd

# N.B. We do not currently attempt to export this archive as it's apparently a 'generic' archive that xcodebuild doesn't
# know what to do with. Instead, we pluck our binary directly out of the archive as we know where it is and we're going
# to package it and notarize it ourselves.
cp "${CLI_ARCHIVE_PATH}/Products/usr/local/bin/incontext" "${BUILD_DIRECTORY}/incontext"

# Export the command.
ZIP_BASENAME="incontext-${VERSION_NUMBER}-${BUILD_NUMBER}"
ZIP_PATH="${BUILD_DIRECTORY}/${ZIP_BASENAME}.zip"
pushd "$BUILD_DIRECTORY"
zip -r "$ZIP_PATH" incontext
rm incontext
popd

# Export the helper.
xcodebuild \
    -archivePath "$HELPER_ARCHIVE_PATH" \
    -exportArchive \
    -exportPath "$BUILD_DIRECTORY" \
    -exportOptionsPlist "InContext/ExportOptions.plist"

# Compress the helper.
# Apple recommends we use ditto to prepare zips for notarization.
# https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution/customizing_the_notarization_workflow
HELPER_ZIP_BASENAME="InContext-Helper-$VERSION_NUMBER-$BUILD_NUMBER"
HELPER_ZIP_PATH="$BUILD_DIRECTORY/$HELPER_ZIP_BASENAME.zip"
pushd "$BUILD_DIRECTORY"
/usr/bin/ditto -c -k --keepParent "InContext Helper.app" "$HELPER_ZIP_PATH"
rm -r "InContext Helper.app"
popd

# Notarization.

API_KEY_PATH="$TEMPORARY_DIRECTORY/api.key"
echo "$APPLE_API_KEY_BASE64" | base64 -d > "$API_KEY_PATH"

# Notarize the command.

xcrun notarytool submit "$ZIP_PATH" \
    --key "$API_KEY_PATH" \
    --key-id "$APPLE_API_KEY_ID" \
    --issuer "$APPLE_API_KEY_ISSUER_ID" \
    --output-format json \
    --wait | tee command-notarization-response.json
NOTARIZATION_ID=`cat command-notarization-response.json | jq -r ".id"`
NOTARIZATION_RESPONSE=`cat command-notarization-response.json | jq -r ".status"`

xcrun notarytool log \
    --key "$API_KEY_PATH" \
    --key-id "$APPLE_API_KEY_ID" \
    --issuer "$APPLE_API_KEY_ISSUER_ID" \
    "$NOTARIZATION_ID" | tee "$BUILD_DIRECTORY/command-notarization-log.json"

if [ "$NOTARIZATION_RESPONSE" != "Accepted" ] ; then
    echo "Failed to notarize command."
    exit 1
fi

# Notarize the helper.

xcrun notarytool submit "$HELPER_ZIP_PATH" \
    --key "$API_KEY_PATH" \
    --key-id "$APPLE_API_KEY_ID" \
    --issuer "$APPLE_API_KEY_ISSUER_ID" \
    --output-format json \
    --wait | tee helper-notarization-response.json
NOTARIZATION_ID=`cat helper-notarization-response.json | jq -r ".id"`
NOTARIZATION_RESPONSE=`cat helper-notarization-response.json | jq -r ".status"`

xcrun notarytool log \
    --key "$API_KEY_PATH" \
    --key-id "$APPLE_API_KEY_ID" \
    --issuer "$APPLE_API_KEY_ISSUER_ID" \
    "$NOTARIZATION_ID" | tee "$BUILD_DIRECTORY/helper-notarization-log.json"

if [ "$NOTARIZATION_RESPONSE" != "Accepted" ] ; then
    echo "Failed to notarize helper."
    exit 1
fi

# Build Sparkle.
cd "$SPARKLE_DIRECTORY"
xcodebuild -project Sparkle.xcodeproj -scheme generate_appcast SYMROOT=`pwd`/.build
GENERATE_APPCAST=`pwd`/.build/Debug/generate_appcast

SPARKLE_PRIVATE_KEY_FILE="$TEMPORARY_DIRECTORY/private-key-file"
echo -n "$SPARKLE_PRIVATE_KEY_BASE64" | base64 --decode -o "$SPARKLE_PRIVATE_KEY_FILE"

# Generate the appcast.
cd "$ROOT_DIRECTORY"
cp "$HELPER_ZIP_PATH" "$ARCHIVES_DIRECTORY"
changes notes --template "$RELEASE_NOTES_TEMPLATE_PATH" >> "$ARCHIVES_DIRECTORY/$HELPER_ZIP_BASENAME.html"
"$GENERATE_APPCAST" --ed-key-file "$SPARKLE_PRIVATE_KEY_FILE" "$ARCHIVES_DIRECTORY"
APPCAST_PATH="$ARCHIVES_DIRECTORY/appcast.xml"
cp "$APPCAST_PATH" "$BUILD_DIRECTORY"

# Create a GitHub release.

if $RELEASE ; then

    changes \
        release \
        --skip-if-empty \
        --push \
        --exec "cheese/gh-release.sh" \
        "$ZIP_PATH" \
        "$HELPER_ZIP_PATH" \
        "$BUILD_DIRECTORY/appcast.xml"

fi
