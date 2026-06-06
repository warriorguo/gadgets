---
name: local-binary-means-swift-webview
description: "For \"make this a local binary\" on web/tool projects, build a native Swift + WKWebView app, not a Go/HTTP server"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 9e60a22b-ea63-4e73-ac78-75da99d76256
---

When the user asks to turn a web project into a "local running binary" / "local
binary", they mean a **native Swift + WKWebView desktop app** that renders the
existing web pages directly in an app window — NOT a Go (or other) HTTP server
that you open in a browser.

**Why:** The user maintains several native macOS apps built this way (videoz =
WKWebView over libmpv; OIA/OAE native macOS tools). A browser-backed web server
is explicitly not what they want for this phrasing. They rejected a Go +
go:embed HTTP-server proposal for the gadgets project and redirected to
"使用swift等webview等技术 将网页页面直接在一个local binary上显示和使用".

**How to apply:** Default to a Swift/WKWebView app for these requests. Serve the
bundled static assets to the webview (custom URL scheme handler or loopback) so
relative links and clipboard work, and produce a double-clickable binary/app.
