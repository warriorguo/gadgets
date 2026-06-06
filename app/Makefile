APP_NAME := Gadgets
BIN_NAME := GadgetsApp
GEN := Sources/GadgetsApp/Assets.generated.swift
DIST := dist

.PHONY: assets build run app clean

# Re-embed the static web files into the generated Swift source.
assets:
	./tools/generate-assets.sh

# Build the release binary (embeds the latest web assets).
build: assets
	swift build -c release

# Build and run the app directly.
run: assets
	swift run -c release

# Package a double-clickable $(APP_NAME).app under dist/.
app: build
	rm -rf "$(DIST)/$(APP_NAME).app"
	mkdir -p "$(DIST)/$(APP_NAME).app/Contents/MacOS"
	cp "$$(swift build -c release --show-bin-path)/$(BIN_NAME)" \
	   "$(DIST)/$(APP_NAME).app/Contents/MacOS/$(APP_NAME)"
	printf '%s\n' \
	  '<?xml version="1.0" encoding="UTF-8"?>' \
	  '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' \
	  '<plist version="1.0"><dict>' \
	  '  <key>CFBundleName</key><string>$(APP_NAME)</string>' \
	  '  <key>CFBundleExecutable</key><string>$(APP_NAME)</string>' \
	  '  <key>CFBundleIdentifier</key><string>com.warriorguo.gadgets</string>' \
	  '  <key>CFBundlePackageType</key><string>APPL</string>' \
	  '  <key>CFBundleShortVersionString</key><string>1.0</string>' \
	  '  <key>LSMinimumSystemVersion</key><string>12.0</string>' \
	  '  <key>NSHighResolutionCapable</key><true/>' \
	  '</dict></plist>' \
	  > "$(DIST)/$(APP_NAME).app/Contents/Info.plist"
	@echo "Built $(DIST)/$(APP_NAME).app — open it with: open \"$(DIST)/$(APP_NAME).app\""

clean:
	rm -rf .build "$(DIST)" "$(GEN)"
