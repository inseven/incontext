export SHELL:=/bin/bash
export SHELLOPTS:=$(if $(SHELLOPTS),$(SHELLOPTS):)pipefail:errexit

export ROOT_DIRECTORY := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
export PYTHONUSERBASE := $(ROOT_DIRECTORY).local/python

export PATH := $(PYTHONUSERBASE)/bin:$(PATH)
export PATH "= $(ROOT_DIRECTORY)scripts/build-tools:$(ROOT_DIRECTORY)scripts/changes:$(PATH)

KEYCHAIN ?= login

all:
	mkdir -p $(PYTHONUSERBASE)
	pip3 install --user pipenv --upgrade
	PIPENV_PIPFILE="Scripts/changes/Pipfile" pipenv install
	PIPENV_PIPFILE="Scripts/build-tools/Pipfile" pipenv install
	$(eval INCONTEXT_VERSION=$(shell changes version))
	$(eval INCONTEXT_BUILD_NUMBER=$(shell build-tools generate-build-number))
	echo Building $(INCONTEXT_VERSION) $(INCONTEXT_BUILD_NUMBER)...

build: all
	swift build \
		-Xcc -DINCONTEXT_VERSION=\"$(INCONTEXT_VERSION)\" \
		-Xcc -DINCONTEXT_BUILD_NUMBER=\"$(INCONTEXT_BUILD_NUMBER)\"

release: all
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
