import AppKit
import SwiftUI

class MenuBarController: NSObject, ObservableObject {
    private var statusItem: NSStatusItem?
    private var panel: NSPanel?

    override init() {
        super.init()
        setupMenuBar()
        setupPanel()
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            button.image = makeMenuBarIcon()
            button.action = #selector(togglePanel)
            button.target = self
        }
    }

    /// Creates a 18x18 template image of a small spreadsheet grid.
    private func makeMenuBarIcon() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            let inset = rect.insetBy(dx: 1, dy: 1)
            let path = NSBezierPath(roundedRect: inset, xRadius: 2, yRadius: 2)
            path.lineWidth = 1.2
            NSColor.black.setStroke()
            path.stroke()

            for i in 1...2 {
                let y = inset.minY + inset.height * CGFloat(i) / 3
                let line = NSBezierPath()
                line.move(to: NSPoint(x: inset.minX, y: y))
                line.line(to: NSPoint(x: inset.maxX, y: y))
                line.lineWidth = 0.8
                line.stroke()
            }

            for i in 1...2 {
                let x = inset.minX + inset.width * CGFloat(i) / 3
                let line = NSBezierPath()
                line.move(to: NSPoint(x: x, y: inset.minY))
                line.line(to: NSPoint(x: x, y: inset.maxY))
                line.lineWidth = 0.8
                line.stroke()
            }

            return true
        }
        image.isTemplate = true
        return image
    }

    private func setupPanel() {
        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: NSSize(width: 600, height: 400)),
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.level = .floating
        panel.hasShadow = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        let hostingController = NSHostingController(rootView: ContentView())
        hostingController.preferredContentSize = NSSize(width: 600, height: 400)
        panel.contentViewController = hostingController
        panel.setContentSize(NSSize(width: 600, height: 400))
        panel.minSize = NSSize(width: 400, height: 300)
        panel.maxSize = NSSize(width: 1200, height: 800)
        panel.standardWindowButton(.closeButton)?.isHidden = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true
        self.panel = panel
    }

    @objc func togglePanel() {
        guard let button = statusItem?.button, let panel = panel else { return }

        if panel.isVisible {
            panel.orderOut(nil)
        } else {
            positionPanelBelowStatusItem(button: button)
            panel.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    private func positionPanelBelowStatusItem(button: NSStatusBarButton) {
        guard let panel = panel,
              let buttonWindow = button.window else { return }

        let buttonRect = buttonWindow.convertToScreen(button.convert(button.bounds, to: nil))
        let panelSize = panel.frame.size
        let x = buttonRect.midX - panelSize.width / 2
        let y = buttonRect.minY - panelSize.height

        let screen = buttonWindow.screen ?? NSScreen.main ?? NSScreen.screens[0]
        let screenFrame = screen.visibleFrame
        let clampedX = max(screenFrame.minX, min(x, screenFrame.maxX - panelSize.width))
        let clampedY = max(screenFrame.minY, y)

        panel.setFrameOrigin(NSPoint(x: clampedX, y: clampedY))
    }
}
