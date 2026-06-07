import AppKit
import WebKit

// MARK: - Asset scheme handler
//
// Serves the embedded static gadgets to the WKWebView over a custom
// `gadgets://` scheme. Using a real origin (rather than file://) keeps relative
// links and cross-tool navigation working, and lets us map directory paths to
// their index.html the way a web server would.

private func mimeType(for path: String) -> String {
    switch (path as NSString).pathExtension.lowercased() {
    case "html", "htm": return "text/html"
    case "css": return "text/css"
    case "js", "mjs": return "application/javascript"
    case "json": return "application/json"
    case "svg": return "image/svg+xml"
    case "png": return "image/png"
    case "jpg", "jpeg": return "image/jpeg"
    case "gif": return "image/gif"
    case "ico": return "image/x-icon"
    case "woff2": return "font/woff2"
    default: return "application/octet-stream"
    }
}

final class AssetSchemeHandler: NSObject, WKURLSchemeHandler {
    func webView(_ webView: WKWebView, start task: WKURLSchemeTask) {
        guard let url = task.request.url else {
            task.didFailWithError(URLError(.badURL))
            return
        }

        // Normalize the path the way a static file server would: a directory
        // serves its index.html. Note URL.path strips a trailing slash
        // ("/log/" -> "/log"), so we can't rely on it to spot a directory —
        // instead we fall back to "<path>/index.html" when there's no direct hit.
        var path = url.path
        if path.hasPrefix("/") { path.removeFirst() }
        if path.isEmpty { path = "index.html" }
        if embeddedAssets[path] == nil {
            let dir = path.hasSuffix("/") ? path : path + "/"
            if embeddedAssets[dir + "index.html"] != nil { path = dir + "index.html" }
        }

        guard let b64 = embeddedAssets[path], let data = Data(base64Encoded: b64) else {
            let resp = HTTPURLResponse(url: url, statusCode: 404,
                                       httpVersion: "HTTP/1.1",
                                       headerFields: ["Content-Type": "text/plain"])!
            task.didReceive(resp)
            task.didReceive("Not found: \(path)".data(using: .utf8)!)
            task.didFinish()
            return
        }

        let resp = HTTPURLResponse(url: url, statusCode: 200,
                                   httpVersion: "HTTP/1.1",
                                   headerFields: [
                                       "Content-Type": mimeType(for: path),
                                       "Content-Length": String(data.count),
                                       "Access-Control-Allow-Origin": "*",
                                   ])!
        task.didReceive(resp)
        task.didReceive(data)
        task.didFinish()
    }

    func webView(_ webView: WKWebView, stop task: WKURLSchemeTask) {}
}

// MARK: - Clipboard bridge
//
// The "Copy" buttons in the tools call navigator.clipboard.writeText, which the
// browser only exposes in a secure context. Our custom scheme is not one, so we
// shim it to post the text to native code, which writes the system pasteboard.

final class ClipboardBridge: NSObject, WKScriptMessageHandler {
    func userContentController(_ controller: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        guard let text = message.body as? String else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}

private let clipboardShim = """
(function () {
  const write = (text) => {
    try { window.webkit.messageHandlers.copy.postMessage(String(text)); } catch (e) {}
    return Promise.resolve();
  };
  // WKWebView under a custom scheme is not a secure context, so the native
  // navigator.clipboard exists but its writeText rejects. Assigning to
  // writeText silently fails (it isn't writable), so install our own
  // `clipboard` data property on the navigator instance to shadow it entirely.
  try {
    Object.defineProperty(navigator, 'clipboard', {
      configurable: true,
      writable: true,
      value: { writeText: write, readText: () => Promise.resolve('') },
    });
  } catch (e) {}
})();
"""

// MARK: - Main menu
//
// A plain NSApplication has no menu bar, so the standard editing key equivalents
// (Cmd+X/C/V/A) are never translated into cut:/copy:/paste:/selectAll: actions —
// which is why Cmd+V didn't paste into the tools. Installing a standard Edit menu
// wires those shortcuts back up through the responder chain to the WKWebView.

private func makeMainMenu(appName: String) -> NSMenu {
    let mainMenu = NSMenu()

    let appItem = NSMenuItem()
    mainMenu.addItem(appItem)
    let appMenu = NSMenu()
    appItem.submenu = appMenu
    appMenu.addItem(withTitle: "Hide \(appName)",
                    action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
    appMenu.addItem(.separator())
    appMenu.addItem(withTitle: "Quit \(appName)",
                    action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

    let editItem = NSMenuItem()
    mainMenu.addItem(editItem)
    let editMenu = NSMenu(title: "Edit")
    editItem.submenu = editMenu
    editMenu.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
    let redo = editMenu.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "z")
    redo.keyEquivalentModifierMask = [.command, .shift]
    editMenu.addItem(.separator())
    editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
    editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
    editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
    editMenu.addItem(withTitle: "Select All",
                     action: #selector(NSResponder.selectAll(_:)), keyEquivalent: "a")

    return mainMenu
}

// MARK: - App

final class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var webView: WKWebView!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.mainMenu = makeMainMenu(appName: "Gadgets")

        let controller = WKUserContentController()
        controller.add(ClipboardBridge(), name: "copy")
        controller.addUserScript(WKUserScript(source: clipboardShim,
                                              injectionTime: .atDocumentStart,
                                              forMainFrameOnly: false))

        let config = WKWebViewConfiguration()
        config.userContentController = controller
        config.setURLSchemeHandler(AssetSchemeHandler(), forURLScheme: "gadgets")

        webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 1100, height: 760),
                            configuration: config)

        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1100, height: 760),
                          styleMask: [.titled, .closable, .miniaturizable, .resizable],
                          backing: .buffered, defer: false)
        window.title = "Gadgets"
        window.contentView = webView
        window.setFrameAutosaveName("GadgetsMainWindow")
        window.center()
        window.makeKeyAndOrderFront(nil)

        webView.load(URLRequest(url: URL(string: "gadgets://app/index.html")!))

        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.regular)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
