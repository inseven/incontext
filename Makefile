build:
	swift build

release:
	swift build --configuration release --triple arm64-apple-macosx
	swift build --configuration release --triple x86_64-apple-macosx
	lipo -create -output incontext .build/arm64-apple-macosx/release/incontext .build/x86_64-apple-macosx/release/incontext

clean:
	rm -rf .build
	rm -f incontext

test:
	swift test

install: release
	install incontext /usr/local/bin/incontext

uninstall:
	rm /usr/local/bin/incontext
