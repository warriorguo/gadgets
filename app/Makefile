APP_NAME := Gadgets
BIN_NAME := GadgetsApp
GEN := Sources/GadgetsApp/Assets.generated.swift
DIST := dist
ICON_SRC := Resources/AppIcon.png
ICNS := $(DIST)/AppIcon.icns

.PHONY: assets build run app icon clean

# Re-embed the static web files into the generated Swift source.
assets:
	./tools/generate-assets.sh

# Build the release binary (embeds the latest web assets).
build: assets
	swift build -c release

# Build and run the app directly.
run: assets
	swift run -c release

# Generate a multi-resolution .icns from the source PNG.
icon: $(ICNS)
$(ICNS): $(ICON_SRC)
	rm -rf "$(DIST)/AppIcon.iconset"
	mkdir -p "$(DIST)/AppIcon.iconset"
	sips -z 16 16     "$(ICON_SRC)" --out "$(DIST)/AppIcon.iconset/icon_16x16.png"      >/dev/null
	sips -z 32 32     "$(ICON_SRC)" --out "$(DIST)/AppIcon.iconset/icon_16x16@2x.png"   >/dev/null
	sips -z 32 32     "$(ICON_SRC)" --out "$(DIST)/AppIcon.iconset/icon_32x32.png"      >/dev/null
	sips -z 64 64     "$(ICON_SRC)" --out "$(DIST)/AppIcon.iconset/icon_32x32@2x.png"   >/dev/null
	sips -z 128 128   "$(ICON_SRC)" --out "$(DIST)/AppIcon.iconset/icon_128x128.png"    >/dev/null
	sips -z 256 256   "$(ICON_SRC)" --out "$(DIST)/AppIcon.iconset/icon_128x128@2x.png" >/dev/null
	sips -z 256 256   "$(ICON_SRC)" --out "$(DIST)/AppIcon.iconset/icon_256x256.png"    >/dev/null
	sips -z 512 512   "$(ICON_SRC)" --out "$(DIST)/AppIcon.iconset/icon_256x256@2x.png" >/dev/null
	sips -z 512 512   "$(ICON_SRC)" --out "$(DIST)/AppIcon.iconset/icon_512x512.png"    >/dev/null
	sips -z 1024 1024 "$(ICON_SRC)" --out "$(DIST)/AppIcon.iconset/icon_512x512@2x.png" >/dev/null
	iconutil -c icns "$(DIST)/AppIcon.iconset" -o "$(ICNS)"
	rm -rf "$(DIST)/AppIcon.iconset"

# Package a double-clickable $(APP_NAME).app under dist/.
app: build icon
	rm -rf "$(DIST)/$(APP_NAME).app"
	mkdir -p "$(DIST)/$(APP_NAME).app/Contents/MacOS"
	mkdir -p "$(DIST)/$(APP_NAME).app/Contents/Resources"
	cp "$$(swift build -c release --show-bin-path)/$(BIN_NAME)" \
	   "$(DIST)/$(APP_NAME).app/Contents/MacOS/$(APP_NAME)"
	cp "$(ICNS)" "$(DIST)/$(APP_NAME).app/Contents/Resources/AppIcon.icns"
	printf '%s\n' \
	  '<?xml version="1.0" encoding="UTF-8"?>' \
	  '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' \
	  '<plist version="1.0"><dict>' \
	  '  <key>CFBundleName</key><string>$(APP_NAME)</string>' \
	  '  <key>CFBundleExecutable</key><string>$(APP_NAME)</string>' \
	  '  <key>CFBundleIdentifier</key><string>com.warriorguo.gadgets</string>' \
	  '  <key>CFBundleIconFile</key><string>AppIcon</string>' \
	  '  <key>CFBundlePackageType</key><string>APPL</string>' \
	  '  <key>CFBundleShortVersionString</key><string>1.0</string>' \
	  '  <key>LSMinimumSystemVersion</key><string>12.0</string>' \
	  '  <key>NSHighResolutionCapable</key><true/>' \
	  '</dict></plist>' \
	  > "$(DIST)/$(APP_NAME).app/Contents/Info.plist"
	@echo "Built $(DIST)/$(APP_NAME).app — open it with: open \"$(DIST)/$(APP_NAME).app\""

clean:
	rm -rf .build "$(DIST)" "$(GEN)"
