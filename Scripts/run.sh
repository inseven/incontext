#!/bin/bash

set -e
set -o pipefail
set -u

SCRIPTS_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
ROOT_DIRECTORY="${SCRIPTS_DIRECTORY}/.."

pushd "$ROOT_DIRECTORY"
swift build -c release
BINARY_DIRECTORY=`swift build --product incontext --show-bin-path`
BINARY_DIRECTORY="$( cd "$BINARY_DIRECTORY" &> /dev/null &&
pwd )"
popd

"$BINARY_DIRECTORY/incontext" $@
