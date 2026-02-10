import AppKit
import SwiftUI

class MenuBarController: ObservableObject {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?

    init() {
        setupMenuBar()
        setupPopover()
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            button.image = makeMenuBarIcon()
            button.action = #selector(togglePopover)
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

            // Horizontal lines (2 lines → 3 rows)
            for i in 1...2 {
                let y = inset.minY + inset.height * CGFloat(i) / 3
                let line = NSBezierPath()
                line.move(to: NSPoint(x: inset.minX, y: y))
                line.line(to: NSPoint(x: inset.maxX, y: y))
                line.lineWidth = 0.8
                line.stroke()
            }

            // Vertical lines (2 lines → 3 columns)
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

    private func setupPopover() {
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 600, height: 400)
        popover?.behavior = .transient
        popover?.contentViewController = NSHostingController(rootView: ContentView())
    }

    @objc func togglePopover() {
        guard let button = statusItem?.button else { return }

        if let popover = popover {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                popover.contentViewController?.view.window?.makeKey()
            }
        }
    }
}
