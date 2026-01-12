# LogoScreenSaver

A bouncing logo screensaver for macOS. Will it ever hit a corner?

## Building and Testing

Build the screensaver:

```bash
xcodebuild
```

Run the test app for development:

```bash
swift run LogoScreenSaverApp
```

Lint the code:

```bash
swiftlint lint
```

Run unit and integration tests:

```bash
swift test
```

## Installing

Open the built `.saver` file to install:

```bash
open build/Release/LogoScreenSaver.saver
```

This prompts you to install the screensaver. Once installed, enable it in **System Settings > Screen Saver**.

Note: The `legacyScreenSaver` daemon may cache the screensaver and need to be killed to see updates.

## Configuration

All settings are configured via plist files in `Core/Resources/Config/`:

| File | Purpose |
|------|---------|
| Debug.plist | Debug overlay, log level, logo size limit |
| Colors.plist | Color palettes and logo colorization settings |
| Logos.plist | Logo file definitions |

### Adding Custom Logos

1. Add your image file to `Core/Resources/Logos/`
2. Add an entry to `Logos.plist`:

```xml
<key>my_logo</key>
<dict>
    <key>Type</key>
    <string>svg</string>
    <key>Source</key>
    <string>builtin</string>
</dict>
```

Supported formats: SVG (macOS 14+), PNG, JPG, TIFF, PDF.

## License

Apache License 2.0. See [LICENSE.md](./LICENSE.md).
