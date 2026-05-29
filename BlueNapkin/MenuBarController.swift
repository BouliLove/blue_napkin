import AppKit
import SwiftUI

// MARK: - Window resizing (AppKit, bypasses SwiftUI hit-testing)

enum ResizeRegion {
    case top, bottom, left, right
    case topLeft, topRight, bottomLeft, bottomRight

    var nsCursor: NSCursor {
        if #available(macOS 15.0, *) {
            switch self {
            case .top, .bottom: return .resizeUpDown
            case .left, .right: return .resizeLeftRight
            case .topLeft:      return .frameResize(position: .topLeft,     directions: .all)
            case .topRight:     return .frameResize(position: .topRight,    directions: .all)
            case .bottomLeft:   return .frameResize(position: .bottomLeft,  directions: .all)
            case .bottomRight:  return .frameResize(position: .bottomRight, directions: .all)
            }
        }
        switch self {
        case .top, .bottom: return .resizeUpDown
        default:            return .resizeLeftRight
        }
    }
}

/// A transparent NSView pinned over the whole window that handles edge/corner
/// resizing. It only claims mouse events within `edgeSize`/`cornerSize` of the
/// border (via hitTest) and passes everything else through to the SwiftUI grid.
/// Lives in pure AppKit so SwiftUI gesture/hit-testing never shadows mouseDown.
final class ResizeBorderView: NSView {
    private let edgeSize: CGFloat = 8
    private let cornerSize: CGFloat = 20

    private var activeRegion: ResizeRegion?
    private var initialFrame: NSRect = .zero
    private var initialMouse: NSPoint = .zero

    // Bounds are unflipped (origin bottom-left, y up) — matches screen coords.
    private func region(at p: NSPoint) -> ResizeRegion? {
        let b = bounds
        guard b.contains(p) else { return nil }
        let fromLeft   = p.x - b.minX
        let fromRight  = b.maxX - p.x
        let fromBottom = p.y - b.minY
        let fromTop    = b.maxY - p.y

        // Corners first (larger target)
        if fromTop    < cornerSize && fromLeft  < cornerSize { return .topLeft }
        if fromTop    < cornerSize && fromRight < cornerSize { return .topRight }
        if fromBottom < cornerSize && fromLeft  < cornerSize { return .bottomLeft }
        if fromBottom < cornerSize && fromRight < cornerSize { return .bottomRight }
        // Edges
        if fromTop    < edgeSize { return .top }
        if fromBottom < edgeSize { return .bottom }
        if fromLeft   < edgeSize { return .left }
        if fromRight  < edgeSize { return .right }
        return nil
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        // `point` is in our superview's coordinate space.
        let local = convert(point, from: superview)
        return region(at: local) == nil ? nil : self
    }

    override func resetCursorRects() {
        let b = bounds
        // Edges (exclude corner zones so corner cursors win there)
        addCursorRect(NSRect(x: cornerSize, y: b.maxY - edgeSize, width: b.width - 2*cornerSize, height: edgeSize), cursor: ResizeRegion.top.nsCursor)
        addCursorRect(NSRect(x: cornerSize, y: 0, width: b.width - 2*cornerSize, height: edgeSize), cursor: ResizeRegion.bottom.nsCursor)
        addCursorRect(NSRect(x: 0, y: cornerSize, width: edgeSize, height: b.height - 2*cornerSize), cursor: ResizeRegion.left.nsCursor)
        addCursorRect(NSRect(x: b.maxX - edgeSize, y: cornerSize, width: edgeSize, height: b.height - 2*cornerSize), cursor: ResizeRegion.right.nsCursor)
        // Corners
        addCursorRect(NSRect(x: 0, y: b.maxY - cornerSize, width: cornerSize, height: cornerSize), cursor: ResizeRegion.topLeft.nsCursor)
        addCursorRect(NSRect(x: b.maxX - cornerSize, y: b.maxY - cornerSize, width: cornerSize, height: cornerSize), cursor: ResizeRegion.topRight.nsCursor)
        addCursorRect(NSRect(x: 0, y: 0, width: cornerSize, height: cornerSize), cursor: ResizeRegion.bottomLeft.nsCursor)
        addCursorRect(NSRect(x: b.maxX - cornerSize, y: 0, width: cornerSize, height: cornerSize), cursor: ResizeRegion.bottomRight.nsCursor)
    }

    override func mouseDown(with event: NSEvent) {
        let local = convert(event.locationInWindow, from: nil)
        guard let r = region(at: local), let window = window else {
            super.mouseDown(with: event)
            return
        }
        activeRegion = r
        initialFrame = window.frame
        initialMouse = NSEvent.mouseLocation
    }

    override func mouseDragged(with event: NSEvent) {
        guard let region = activeRegion, let window = window else {
            super.mouseDragged(with: event)
            return
        }
        let mouse = NSEvent.mouseLocation
        let dx = mouse.x - initialMouse.x
        let dy = mouse.y - initialMouse.y   // screen coords: dy > 0 == upward

        let minW = window.minSize.width,  maxW = window.maxSize.width
        let minH = window.minSize.height, maxH = window.maxSize.height
        func clampW(_ v: CGFloat) -> CGFloat { max(minW, min(maxW, v)) }
        func clampH(_ v: CGFloat) -> CGFloat { max(minH, min(maxH, v)) }

        let x0 = initialFrame.origin.x, y0 = initialFrame.origin.y
        let w0 = initialFrame.width,    h0 = initialFrame.height
        let maxX = initialFrame.maxX,   maxY = initialFrame.maxY

        var frame = initialFrame
        switch region {
        case .right:
            let w = clampW(w0 + dx); frame = NSRect(x: x0, y: y0, width: w, height: h0)
        case .left:
            let w = clampW(w0 - dx); frame = NSRect(x: maxX - w, y: y0, width: w, height: h0)
        case .top:
            let h = clampH(h0 + dy); frame = NSRect(x: x0, y: y0, width: w0, height: h)
        case .bottom:
            let h = clampH(h0 - dy); frame = NSRect(x: x0, y: maxY - h, width: w0, height: h)
        case .topRight:
            let w = clampW(w0 + dx), h = clampH(h0 + dy); frame = NSRect(x: x0, y: y0, width: w, height: h)
        case .topLeft:
            let w = clampW(w0 - dx), h = clampH(h0 + dy); frame = NSRect(x: maxX - w, y: y0, width: w, height: h)
        case .bottomRight:
            let w = clampW(w0 + dx), h = clampH(h0 - dy); frame = NSRect(x: x0, y: maxY - h, width: w, height: h)
        case .bottomLeft:
            let w = clampW(w0 - dx), h = clampH(h0 - dy); frame = NSRect(x: maxX - w, y: maxY - h, width: w, height: h)
        }
        window.setFrame(frame, display: true, animate: false)
    }

    override func mouseUp(with event: NSEvent) {
        activeRegion = nil
    }
}

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
        panel.appearance = NSAppearance(named: .aqua)

        // Container content view: SwiftUI hosting view (bottom) + resize border (top).
        // The border view is a real AppKit sibling above the hosting view, so its
        // mouseDown is never shadowed by SwiftUI hit-testing.
        let initialFrame = NSRect(origin: .zero, size: NSSize(width: 600, height: 400))
        let hosting = NSHostingView(rootView: ContentView())
        hosting.frame = initialFrame
        hosting.autoresizingMask = [.width, .height]

        let container = NSView(frame: initialFrame)
        container.addSubview(hosting)

        let border = ResizeBorderView(frame: initialFrame)
        border.autoresizingMask = [.width, .height]
        container.addSubview(border, positioned: .above, relativeTo: hosting)

        panel.contentView = container
        panel.setContentSize(NSSize(width: 600, height: 400))
        panel.minSize = NSSize(width: 400, height: 300)
        panel.maxSize = NSSize(width: 1800, height: 1200)
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
