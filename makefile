all: build
	

# (Re)Generate buildserver.json for sourcekit support
build-server:
	xcode-build-server config -project bitebook.xcodeproj -scheme bitebook

build:
	xcodebuild -scheme bitebook -configuration Debug -derivedDataPath .build

build-device:
	xcodebuild -scheme bitebook -configuration Debug -derivedDataPath .build -destination 'generic/platform=iOS' build

# Build, install and launch on the first connected physical iPhone.
run-device: build-device
	@device_id=$$(xcrun devicectl list devices 2>/dev/null | awk '/connected/{for(i=1;i<=NF;i++) if ($$i ~ /^[0-9A-Fa-f]{8}-/) print $$i}' | head -n1); \
	if [ -z "$$device_id" ]; then echo "No connected iOS device found. Is your iPhone paired and unlocked?"; exit 1; fi; \
	echo "Installing to device $$device_id..."; \
	xcrun devicectl device install app --device $$device_id .build/Build/Products/Debug-iphoneos/bitebook.app; \
	xcrun devicectl device process launch --device $$device_id willtrojniak.bitebook

clean:
	rm -rf ./.build
