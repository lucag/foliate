// PROTOTYPE: a bare WKWebView window for the dark-mode pages prototype. Throwaway.
// usage: swift viewer.swift <url> [snapshot.png]
import AppKit
import WebKit

let url = URL(string: CommandLine.arguments[1])!
let snapshotPath = CommandLine.arguments.count > 2 ? CommandLine.arguments[2] : nil
let height = CommandLine.arguments.count > 3 ? Double(CommandLine.arguments[3])! : 1000

class Delegate: NSObject, NSApplicationDelegate, WKNavigationDelegate, WKScriptMessageHandler {
    var window: NSWindow!
    var web: WKWebView!
    func applicationDidFinishLaunching(_ n: Notification) {
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "developerExtrasEnabled")
        config.userContentController.add(self, name: "done")
        web = WKWebView(frame: NSRect(x: 0, y: 0, width: 1500, height: height), configuration: config)
        web.isInspectable = true
        web.navigationDelegate = self
        window = NSWindow(contentRect: web.frame, styleMask: [.titled, .closable, .resizable, .miniaturizable], backing: .buffered, defer: false)
        window.title = "PROTOTYPE · dark-mode pages"
        window.contentView = web
        window.appearance = NSAppearance(named: .darkAqua)
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        web.load(URLRequest(url: url))
    }
    // the page posts "done" when every render has finished; snapshot then
    func userContentController(_ c: WKUserContentController, didReceive m: WKScriptMessage) {
        guard let path = snapshotPath else { return }
        let cfg = WKSnapshotConfiguration()
        web.takeSnapshot(with: cfg) { img, err in
            if let img, let tiff = img.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff),
               let png = rep.representation(using: .png, properties: [:]) {
                try? png.write(to: URL(fileURLWithPath: path))
            } else { print("snapshot failed", err as Any) }
            NSApp.terminate(nil)
        }
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ s: NSApplication) -> Bool { true }
}

let app = NSApplication.shared
app.setActivationPolicy(.regular)
let d = Delegate()
app.delegate = d
app.run()
