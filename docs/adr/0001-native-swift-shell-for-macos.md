# A native Swift Shell for macOS instead of porting the GTK app

Foliate runs on macOS through a new Shell written in Swift (SwiftUI first, with AppKit where needed) under `macos/`. It hosts the same Renderer and the same shared Reader page in a WKWebView, rather than porting the GJS/GTK4/libadwaita Shell. WebKitGTK 6.0, which the GTK Shell depends on, has no working macOS build anywhere and upstream doesn't support macOS. Porting the GTK Shell would mean maintaining our own patched WebKitGTK, without GPU acceleration, and re-applying the patches on every WebKit release.

## Considered Options

- **Port the GTK Shell as-is:** blocked by WebKitGTK 6.0, as above. Homebrew is also winding down Intel support.
- **GTK Shell driving WKWebView:** keeps every GTK-on-macOS cost, needs custom Objective-C/GObject-Introspection bindings, and GTK overlays can't draw above the web view.
- **Tauri:** runs the same WKWebView and allows a web-based Shell UI, but loses lazy book loading through the file chooser and needs a messaging shim. We wanted a native Mac feel instead.
- **Electron:** excluded by preference.

## Consequences

- There are two Shells to maintain. The Reader page (`src/reader/`) stays shared and unchanged. macOS differences come in through injected user scripts, never through edits that affect Linux.
- macOS uses the same user-data JSON format as Linux.
- Upstream acceptance was not a deciding factor.
