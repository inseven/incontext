export MAKEFILE_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
export PYTHONUSERBASE := $(MAKEFILE_DIR).local/python
export PATH := $(PYTHONUSERBASE)/bin:$(PATH)

all:
	mkdir -p $(PYTHONUSERBASE)
	pip3 install --user pipenv
	PIPENV_PIPFILE="Scripts/changes/Pipfile" pipenv install
	PIPENV_PIPFILE="Scripts/build-tools/Pipfile" pipenv install
	$(eval INCONTEXT_VERSION=$(shell Scripts/changes/changes version))
	$(eval INCONTEXT_BUILD_NUMBER=$(shell Scripts/build-tools/build-tools generate-build-number))
	echo Building $(INCONTEXT_VERSION) $(INCONTEXT_BUILD_NUMBER)...

build: all
	swift build \
		-Xcc -DINCONTEXT_VERSION=\"$(INCONTEXT_VERSION)\" \
		-Xcc -DINCONTEXT_BUILD_NUMBER=\"$(INCONTEXT_BUILD_NUMBER)\"

release: all
	swift build \
		--configuration release --triple arm64-apple-macosx \
		-Xcc -DINCONTEXT_VERSION=\"$(INCONTEXT_VERSION)\" \
		-Xcc -DINCONTEXT_BUILD_NUMBER=\"$(INCONTEXT_BUILD_NUMBER)\"
	swift build \
		--configuration release --triple x86_64-apple-macosx \
		-Xcc -DINCONTEXT_VERSION=\"$(INCONTEXT_VERSION)\" \
		-Xcc -DINCONTEXT_BUILD_NUMBER=\"$(INCONTEXT_BUILD_NUMBER)\"
	lipo -create \
		-output incontext \
		.build/arm64-apple-macosx/release/incontext \
		.build/x86_64-apple-macosx/release/incontext

clean:
	rm -rf .local
	rm -rf .build
	rm -f incontext

test:
	swift test

install: release
	install incontext /usr/local/bin/incontext

uninstall:
	rm /usr/local/bin/incontext
