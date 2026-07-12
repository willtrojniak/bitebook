all: build
	

# (Re)Generate buildserver.json for sourcekit support
build-server:
	xcode-build-server config -project bitebook.xcodeproj -scheme bitebook

build:
	xcodebuild -scheme bitebook -configuration Debug -derivedDataPath .build

clean:
	rm -rf ./.build
