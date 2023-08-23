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

export ROOT_DIRECTORY := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

KEYCHAIN ?= login
INCONTEXT_VERSION ?= Unknown
INCONTEXT_BUILD_NUMBER ?= Unknown

build:
	swift build \
		-Xcc -DINCONTEXT_VERSION=\"$(INCONTEXT_VERSION)\" \
		-Xcc -DINCONTEXT_BUILD_NUMBER=\"$(INCONTEXT_BUILD_NUMBER)\"

release:
	mkdir -p build
	swift build \
		--configuration release --triple arm64-apple-macosx \
		-Xcc -DINCONTEXT_VERSION=\"$(INCONTEXT_VERSION)\" \
		-Xcc -DINCONTEXT_BUILD_NUMBER=\"$(INCONTEXT_BUILD_NUMBER)\"
	swift build \
		--configuration release --triple x86_64-apple-macosx \
		-Xcc -DINCONTEXT_VERSION=\"$(INCONTEXT_VERSION)\" \
		-Xcc -DINCONTEXT_BUILD_NUMBER=\"$(INCONTEXT_BUILD_NUMBER)\"
	lipo -create \
		-output build/incontext \
		.build/arm64-apple-macosx/release/incontext \
		.build/x86_64-apple-macosx/release/incontext

sign: release
	codesign \
		--keychain "$(KEYCHAIN)" \
		-s "Developer ID Application: InSeven Limited (S4WXAUZQEV)" \
		--timestamp \
		build/incontext
	codesign \
		-vvv \
		--deep \
		--strict \
		build/incontext

archive: sign
	zip -r \
		"build/incontext-$(INCONTEXT_VERSION)-$(INCONTEXT_BUILD_NUMBER).zip" \
		build/incontext

clean:
	rm -rf .local
	rm -rf .build
	rm -rf build

test:
	swift test

install: release
	install incontext /usr/local/bin/incontext

uninstall:
	rm /usr/local/bin/incontext
