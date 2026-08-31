import Cocoa

// Resolved at runtime rather than hardcoded, so the built binary works
// regardless of where the repo lives on disk. Override with
// CLAMSHELL_TOGGLE_SCRIPT if you're running the binary from somewhere
// that isn't <repo>/menubar/build/.
func resolveToggleScriptPath() -> String {
    if let overridePath = ProcessInfo.processInfo.environment["CLAMSHELL_TOGGLE_SCRIPT"] {
        return overridePath
    }
    // executable lives at <repo>/menubar/build/ClamshellStatusBar
    let exeURL = URL(fileURLWithPath: CommandLine.arguments[0]).resolvingSymlinksInPath()
    let repoDir = exeURL
        .deletingLastPathComponent() // build/
        .deletingLastPathComponent() // menubar/
        .deletingLastPathComponent() // <repo>/
    return repoDir.appendingPathComponent("bin/clamshell-toggle.sh").path
}

let toggleScript = resolveToggleScriptPath()

func runScript(_ args: [String]) -> String {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: toggleScript)
    process.arguments = args
    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = pipe
    do {
        try process.run()
        process.waitUntilExit()
    } catch {
        return "error"
    }
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "error"
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    var refreshTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        refresh()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    func refresh() {
        let state = runScript(["status"])
        DispatchQueue.main.async {
            self.statusItem.button?.title = (state == "enabled") ? "🔓" : "🔒"
            self.rebuildMenu(state: state)
        }
    }

    func rebuildMenu(state: String) {
        let menu = NSMenu()
        let statusLabel = NSMenuItem(title: "Clamshell battery mode: \(state)", action: nil, keyEquivalent: "")
        statusLabel.isEnabled = false
        menu.addItem(statusLabel)
        menu.addItem(NSMenuItem.separator())

        let enableItem = NSMenuItem(title: "Enable", action: #selector(enable), keyEquivalent: "")
        enableItem.target = self
        enableItem.state = (state == "enabled") ? .on : .off
        enableItem.isEnabled = (state != "enabled")
        menu.addItem(enableItem)

        let disableItem = NSMenuItem(title: "Disable", action: #selector(disable), keyEquivalent: "")
        disableItem.target = self
        disableItem.state = (state == "disabled") ? .on : .off
        disableItem.isEnabled = (state != "disabled")
        menu.addItem(disableItem)

        menu.addItem(NSMenuItem.separator())
        let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc func enable() {
        _ = runScript(["enable"])
        refresh()
    }

    @objc func disable() {
        _ = runScript(["disable"])
        refresh()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
