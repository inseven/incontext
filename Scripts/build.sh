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

# Build and test.
sudo xcode-select --switch "$MACOS_XCODE_PATH"

# Import the certificates into our dedicated keychain.
echo "$DEVELOPER_ID_APPLICATION_CERTIFICATE_PASSWORD" | build-tools import-base64-certificate \
    --password \
    "$KEYCHAIN_PATH" \
    "$DEVELOPER_ID_APPLICATION_CERTIFICATE_BASE64"

make clean
make test
make archive KEYCHAIN="$KEYCHAIN_PATH"

# if $RELEASE ; then
#
#     IPA_PATH="${BUILD_DIRECTORY}/Bookmarks.ipa"
#     PKG_PATH="${BUILD_DIRECTORY}/Bookmarks.pkg"
#
#     changes \
#         release \
#         --skip-if-empty \
#         --pre-release \
#         --push \
#         --exec "${RELEASE_SCRIPT_PATH}" \
#         "${IPA_PATH}" "${PKG_PATH}" "${ZIP_PATH}"
#     unlink "$API_KEY_PATH"
#
# fi
