# Gadgets — native local app

A self-contained macOS binary that renders the gadgets tool collection directly
in a window using **Swift + WKWebView** — no browser, no nginx.

The static web files (`index.html`, `assets/`, `markdown/`, `json/`, `code/`,
`log/` at the repo root) are embedded into the binary at build time and served
to the webview over a custom `gadgets://` URL scheme, so relative links,
cross-tool navigation, and the Copy buttons all work.

## Requirements

- macOS 12+
- Swift toolchain (`swift --version`)

## Run

```bash
cd app
make run          # embeds the latest web assets, then builds & runs
```

## Build a double-clickable app

```bash
cd app
make app          # produces dist/Gadgets.app
open dist/Gadgets.app
```

## How it works

- `tools/generate-assets.sh` base64-encodes the web files into
  `Sources/GadgetsApp/Assets.generated.swift` (regenerate any time the web files
  change — `make assets`, or just use `make run`/`make build`/`make app`, which
  do it for you).
- `AssetSchemeHandler` serves those bytes over `gadgets://`, mapping directory
  paths to `index.html` and setting MIME types like a static file server.
- A `WKScriptMessageHandler` bridges `navigator.clipboard.writeText` to
  `NSPasteboard` so the Copy buttons work outside a secure context.

The existing nginx `Dockerfile` deployment is unaffected — this app is an
additional, alternative way to run the same tools locally.
