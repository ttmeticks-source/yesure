import AppKit
import Foundation

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow!
    private var endpointField: NSTextField!
    private var tokenField: NSSecureTextField!
    private var requestView: NSTextView!
    private var statusLabel: NSTextField!
    private var sendButton: NSButton!

    private let allowedTests: Set<String> = [
        "remote_validation",
        "movement_validation",
        "rate_limit_validation",
        "permission_validation"
    ]

    func applicationDidFinishLaunching(_ notification: Notification) {
        buildWindow()
    }

    private func buildWindow() {
        let rect = NSRect(x: 0, y: 0, width: 760, height: 650)
        window = NSWindow(
            contentRect: rect,
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "BOZO EXECUTER"
        window.center()
        window.minSize = NSSize(width: 650, height: 560)
        window.backgroundColor = NSColor(calibratedRed: 0.055, green: 0.055, blue: 0.065, alpha: 1)

        let root = NSView(frame: rect)
        root.wantsLayer = true
        root.layer?.backgroundColor = NSColor(calibratedRed: 0.055, green: 0.055, blue: 0.065, alpha: 1).cgColor
        window.contentView = root

        let title = label("##### BOZO EXECUTER", size: 27, color: .systemRed, bold: true)
        title.frame = NSRect(x: 28, y: 590, width: 500, height: 36)
        root.addSubview(title)

        let subtitle = label("ROBLOX SERVER TEST CONSOLE  •  CREATED BY c0olerishere", size: 11, color: .white, bold: false)
        subtitle.frame = NSRect(x: 30, y: 568, width: 600, height: 18)
        root.addSubview(subtitle)

        addLabel("AUTHORIZED HTTPS BRIDGE URL", to: root, y: 525)
        endpointField = NSTextField(string: "")
        endpointField.placeholderString = "https://your-bridge.example/api/test"
        endpointField.frame = NSRect(x: 30, y: 495, width: 700, height: 26)
        styleField(endpointField)
        root.addSubview(endpointField)

        addLabel("BRIDGE TOKEN (not saved)", to: root, y: 458)
        tokenField = NSSecureTextField(string: "")
        tokenField.placeholderString = "Paste your bridge token"
        tokenField.frame = NSRect(x: 30, y: 428, width: 700, height: 26)
        styleField(tokenField)
        root.addSubview(tokenField)

        addLabel("TEST REQUEST JSON — NOT EXECUTABLE LUAU", to: root, y: 390)
        let scroll = NSScrollView(frame: NSRect(x: 30, y: 155, width: 700, height: 220))
        scroll.hasVerticalScroller = true
        scroll.borderType = .noBorder
        requestView = NSTextView(frame: scroll.bounds)
        requestView.isRichText = false
        requestView.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        requestView.textColor = .white
        requestView.backgroundColor = NSColor(calibratedRed: 0.10, green: 0.10, blue: 0.12, alpha: 1)
        requestView.string = "{\n  \"test\": \"remote_validation\"\n}"
        scroll.documentView = requestView
        root.addSubview(scroll)

        let send = NSButton(title: "INJECT TEST", target: self, action: #selector(sendTest))
        send.frame = NSRect(x: 30, y: 105, width: 160, height: 36)
        send.bezelStyle = .rounded
        send.contentTintColor = .white
        send.layer?.backgroundColor = NSColor.systemRed.cgColor
        sendButton = send
        root.addSubview(send)

        let clear = NSButton(title: "CLEAR", target: self, action: #selector(clearFields))
        clear.frame = NSRect(x: 205, y: 105, width: 110, height: 36)
        clear.bezelStyle = .rounded
        clear.contentTintColor = .white
        root.addSubview(clear)

        statusLabel = label("STATUS: NOT CONNECTED", size: 12, color: .systemOrange, bold: true)
        statusLabel.frame = NSRect(x: 30, y: 65, width: 700, height: 22)
        root.addSubview(statusLabel)

        let foot = label("Only allowlisted test IDs are sent. No arbitrary code execution is supported.", size: 10, color: .lightGray, bold: false)
        foot.frame = NSRect(x: 30, y: 30, width: 700, height: 18)
        root.addSubview(foot)

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func label(_ text: String, size: CGFloat, color: NSColor, bold: Bool) -> NSTextField {
        let field = NSTextField(labelWithString: text)
        field.font = bold ? NSFont.boldSystemFont(ofSize: size) : NSFont.systemFont(ofSize: size)
        field.textColor = color
        return field
    }

    private func addLabel(_ text: String, to view: NSView, y: CGFloat) {
        let field = label(text, size: 11, color: .systemRed, bold: true)
        field.frame = NSRect(x: 30, y: y, width: 700, height: 18)
        view.addSubview(field)
    }

    private func styleField(_ field: NSTextField) {
        field.font = NSFont.systemFont(ofSize: 13)
        field.textColor = .white
        field.backgroundColor = NSColor(calibratedRed: 0.12, green: 0.12, blue: 0.14, alpha: 1)
        field.isBezeled = true
        field.bezelStyle = .roundedBezel
    }

    @objc private func clearFields() {
        requestView.string = "{\n  \"test\": \"remote_validation\"\n}"
        statusLabel.stringValue = "STATUS: CLEARED"
        statusLabel.textColor = .secondaryLabelColor
    }

    @objc private func sendTest() {
        let endpointText = endpointField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let token = tokenField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let url = URL(string: endpointText),
              url.scheme?.lowercased() == "https",
              url.host != nil else {
            setStatus("ERROR: ENTER A VALID HTTPS BRIDGE URL", color: .systemRed)
            return
        }
        guard !token.isEmpty else {
            setStatus("ERROR: BRIDGE TOKEN IS REQUIRED", color: .systemRed)
            return
        }
        guard let data = requestView.string.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data),
              let request = object as? [String: Any],
              let testName = request["test"] as? String,
              allowedTests.contains(testName) else {
            setStatus("ERROR: INVALID JSON OR TEST ID NOT ALLOWED", color: .systemRed)
            return
        }

        var http = URLRequest(url: url)
        http.httpMethod = "POST"
        http.timeoutInterval = 20
        http.setValue("application/json", forHTTPHeaderField: "Content-Type")
        http.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        http.httpBody = data

        sendButton.isEnabled = false
        setStatus("STATUS: SENDING AUTHORIZED TEST REQUEST…", color: .systemOrange)

        URLSession.shared.dataTask(with: http) { [weak self] responseData, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.sendButton.isEnabled = true

                if let error = error {
                    self.setStatus("CONNECTION ERROR: \(error.localizedDescription)", color: .systemRed)
                    return
                }
                guard let httpResponse = response as? HTTPURLResponse else {
                    self.setStatus("ERROR: NO HTTP RESPONSE", color: .systemRed)
                    return
                }
                let responseText = responseData.flatMap { String(data: $0, encoding: .utf8) } ?? "(empty response)"
                if (200...299).contains(httpResponse.statusCode) {
                    self.setStatus("BRIDGE RESPONSE: HTTP \(httpResponse.statusCode) — \(responseText)", color: .systemGreen)
                } else {
                    self.setStatus("BRIDGE REJECTED: HTTP \(httpResponse.statusCode) — \(responseText)", color: .systemRed)
                }
            }
        }.resume()
    }

    private func setStatus(_ text: String, color: NSColor) {
        statusLabel.stringValue = text
        statusLabel.textColor = color
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
