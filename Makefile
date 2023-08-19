build:
	swift build -Xcc -DINCONTEXT_VERSION=\"1.0.0\" -Xcc -DINCONTEXT_BUILD_NUMBER=\"00000000\"

release:
	swift build --configuration release --triple arm64-apple-macosx -Xcc -DINCONTEXT_VERSION=\"1.0.0\" -Xcc -DINCONTEXT_BUILD_NUMBER=\"00000000\"
	swift build --configuration release --triple x86_64-apple-macosx -Xcc -DINCONTEXT_VERSION=\"1.0.0\" -Xcc -DINCONTEXT_BUILD_NUMBER=\"00000000\"
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
