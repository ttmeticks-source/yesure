import AppKit
import Foundation

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow!
    private var endpointField: NSTextField!
    private var tokenField: NSSecureTextField!
    private var requestView: NSTextView!
    private var statusLabel: NSTextField!
    private var sendButton: NSButton!

    private let allowedActions: Set<String> = [
        "remote_validation", "movement_validation",
        "rate_limit_validation", "permission_validation"
    ]

    private let panel = NSColor(calibratedRed: 0.105, green: 0.105, blue: 0.125, alpha: 1)
    private let background = NSColor(calibratedRed: 0.045, green: 0.047, blue: 0.058, alpha: 1)
    private let red = NSColor(calibratedRed: 0.92, green: 0.12, blue: 0.19, alpha: 1)

    func applicationDidFinishLaunching(_ notification: Notification) { buildWindow() }

    private func buildWindow() {
        let frame = NSRect(x: 0, y: 0, width: 820, height: 700)
        window = NSWindow(contentRect: frame, styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
        window.title = "BOZO EXECUTER"
        window.center()
        window.minSize = NSSize(width: 700, height: 620)
        window.backgroundColor = background

        let root = NSView(frame: frame)
        root.wantsLayer = true
        root.layer?.backgroundColor = background.cgColor
        window.contentView = root

        let accent = NSView(frame: NSRect(x: 0, y: 0, width: 5, height: 700))
        accent.wantsLayer = true
        accent.layer?.backgroundColor = red.cgColor
        root.addSubview(accent)

        let title = makeLabel("BOZO EXECUTER", 28, red, true)
        title.frame = NSRect(x: 30, y: 635, width: 450, height: 36)
        root.addSubview(title)
        let sub = makeLabel("SERVER CONTROL  /  OWNER-AUTHORIZED COMMANDS", 10, .secondaryLabelColor, true)
        sub.frame = NSRect(x: 32, y: 613, width: 500, height: 17)
        root.addSubview(sub)
        let version = makeLabel("MACOS • V1.1", 10, red, true)
        version.alignment = .right
        version.frame = NSRect(x: 650, y: 635, width: 135, height: 20)
        root.addSubview(version)

        addPanel(root, NSRect(x: 25, y: 515, width: 770, height: 78))
        addCaption("CONNECTION", root, 566)
        endpointField = NSTextField(string: "")
        endpointField.placeholderString = "https://your-own-bridge.example/api/command"
        endpointField.frame = NSRect(x: 42, y: 530, width: 465, height: 27)
        styleField(endpointField)
        root.addSubview(endpointField)

        tokenField = NSSecureTextField(string: "")
        tokenField.placeholderString = "Bridge access token"
        tokenField.frame = NSRect(x: 520, y: 530, width: 255, height: 27)
        styleField(tokenField)
        root.addSubview(tokenField)

        addPanel(root, NSRect(x: 25, y: 160, width: 770, height: 340))
        addCaption("COMMAND PAYLOAD", root, 470)
        let hint = makeLabel("JSON • approved command IDs only", 10, .secondaryLabelColor, false)
        hint.frame = NSRect(x: 42, y: 448, width: 400, height: 16)
        root.addSubview(hint)

        let scroll = NSScrollView(frame: NSRect(x: 42, y: 205, width: 736, height: 225))
        scroll.hasVerticalScroller = true
        scroll.borderType = .noBorder
        scroll.drawsBackground = false
        requestView = NSTextView(frame: scroll.bounds)
        requestView.isRichText = false
        requestView.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .medium)
        requestView.textColor = NSColor(calibratedRed: 0.88, green: 0.91, blue: 0.94, alpha: 1)
        requestView.insertionPointColor = red
        requestView.backgroundColor = NSColor(calibratedRed: 0.065, green: 0.067, blue: 0.08, alpha: 1)
        requestView.textContainerInset = NSSize(width: 14, height: 14)
        requestView.string = "{\n  \"test\": \"remote_validation\"\n}"
        scroll.documentView = requestView
        root.addSubview(scroll)

        sendButton = makeButton("SEND COMMAND", #selector(sendCommand), width: 170)
        sendButton.frame = NSRect(x: 42, y: 108, width: 170, height: 38)
        root.addSubview(sendButton)

        let clear = makeButton("CLEAR EDITOR", #selector(clearEditor), width: 140)
        clear.frame = NSRect(x: 224, y: 108, width: 140, height: 38)
        clear.contentTintColor = .white
        root.addSubview(clear)

        statusLabel = makeLabel("●  DISCONNECTED — ENTER YOUR BRIDGE DETAILS", 11, .systemOrange, true)
        statusLabel.frame = NSRect(x: 42, y: 65, width: 735, height: 22)
        root.addSubview(statusLabel)

        let footer = makeLabel("SECURE REQUEST MODE  •  NO ARBITRARY CODE EXECUTION", 9, .tertiaryLabelColor, true)
        footer.frame = NSRect(x: 42, y: 28, width: 735, height: 18)
        root.addSubview(footer)

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func addPanel(_ root: NSView, _ frame: NSRect) {
        let box = NSBox(frame: frame)
        box.boxType = .custom
        box.borderType = .noBorder
        box.fillColor = panel
        box.cornerRadius = 12
        root.addSubview(box)
    }

    private func makeLabel(_ text: String, _ size: CGFloat, _ color: NSColor, _ bold: Bool) -> NSTextField {
        let v = NSTextField(labelWithString: text)
        v.font = bold ? .boldSystemFont(ofSize: size) : .systemFont(ofSize: size)
        v.textColor = color
        v.lineBreakMode = .byTruncatingTail
        return v
    }

    private func addCaption(_ text: String, _ root: NSView, _ y: CGFloat) {
        let v = makeLabel(text, 10, red, true)
        v.frame = NSRect(x: 42, y: y, width: 400, height: 17)
        root.addSubview(v)
    }

    private func styleField(_ f: NSTextField) {
        f.font = .systemFont(ofSize: 12)
        f.textColor = .white
        f.backgroundColor = NSColor(calibratedRed: 0.065, green: 0.067, blue: 0.08, alpha: 1)
        f.isBezeled = true
        f.bezelStyle = .roundedBezel
    }

    private func makeButton(_ title: String, _ action: Selector, width: CGFloat) -> NSButton {
        let b = NSButton(title: title, target: self, action: action)
        b.bezelStyle = .rounded
        b.font = .boldSystemFont(ofSize: 11)
        b.contentTintColor = .white
        b.setButtonType(.momentaryPushIn)
        return b
    }

    @objc private func clearEditor() {
        requestView.string = "{\n  \"test\": \"remote_validation\"\n}"
        setStatus("●  EDITOR CLEARED", .secondaryLabelColor)
    }

    @objc private func sendCommand() {
        let rawURL = endpointField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let token = tokenField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: rawURL), url.scheme?.lowercased() == "https", url.host != nil else {
            setStatus("●  ERROR — ENTER A VALID HTTPS ENDPOINT", .systemRed); return
        }
        guard !token.isEmpty else { setStatus("●  ERROR — ACCESS TOKEN REQUIRED", .systemRed); return }
        guard let body = requestView.string.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: body),
              let payload = object as? [String: Any],
              let action = payload["test"] as? String,
              allowedActions.contains(action) else {
            setStatus("●  REJECTED — INVALID JSON OR COMMAND NOT ALLOWED", .systemRed); return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 25
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = body

        sendButton.isEnabled = false
        setStatus("●  SENDING APPROVED COMMAND…", .systemOrange)
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.sendButton.isEnabled = true
                if let error = error {
                    self.setStatus("●  CONNECTION FAILED — \(error.localizedDescription)", .systemRed); return
                }
                guard let http = response as? HTTPURLResponse else {
                    self.setStatus("●  NO SERVER RESPONSE", .systemRed); return
                }
                let text = data.flatMap { String(data: $0, encoding: .utf8) } ?? "(empty response)"
                let safeText = String(text.prefix(180))
                self.setStatus("●  HTTP \(http.statusCode) — \(safeText)", (200...299).contains(http.statusCode) ? .systemGreen : .systemRed)
            }
        }.resume()
    }

    private func setStatus(_ text: String, _ color: NSColor) {
        statusLabel.stringValue = text
        statusLabel.textColor = color
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
