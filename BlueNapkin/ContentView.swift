import SwiftUI
import AppKit

extension Notification.Name {
    static let exportCSV = Notification.Name("BlueNapkin.exportCSV")
}

/// Transparent view that enables window dragging when placed in the title bar.
struct WindowDragArea: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = DraggableView()
        return view
    }
    func updateNSView(_ nsView: NSView, context: Context) {}

    private class DraggableView: NSView {
        override func mouseDown(with event: NSEvent) {
            window?.performDrag(with: event)
        }
    }
}

/// Invisible resize handle at a window corner. Drag to resize.
struct WindowResizeHandle: NSViewRepresentable {
    enum Corner { case bottomLeft, bottomRight }
    let corner: Corner

    func makeNSView(context: Context) -> NSView { ResizeView(corner: corner) }
    func updateNSView(_ nsView: NSView, context: Context) {}

    private class ResizeView: NSView {
        let corner: Corner
        private var initialFrame: NSRect = .zero
        private var initialMouse: NSPoint = .zero

        init(corner: Corner) {
            self.corner = corner
            super.init(frame: .zero)
        }
        required init?(coder: NSCoder) { fatalError() }

        override func mouseDown(with event: NSEvent) {
            guard let window = window else { return }
            initialFrame = window.frame
            initialMouse = NSEvent.mouseLocation
        }

        override func mouseDragged(with event: NSEvent) {
            guard let window = window else { return }
            let mouse = NSEvent.mouseLocation
            let dx = mouse.x - initialMouse.x
            let dy = mouse.y - initialMouse.y

            var frame = initialFrame
            let newH = max(window.minSize.height, min(window.maxSize.height, initialFrame.height - dy))
            frame.origin.y = initialFrame.maxY - newH
            frame.size.height = newH

            switch corner {
            case .bottomRight:
                frame.size.width = max(window.minSize.width, min(window.maxSize.width, initialFrame.width + dx))
            case .bottomLeft:
                let newW = max(window.minSize.width, min(window.maxSize.width, initialFrame.width - dx))
                frame.origin.x = initialFrame.maxX - newW
                frame.size.width = newW
            }

            window.setFrame(frame, display: true, animate: false)
        }
    }
}

struct ContentView: View {
    var body: some View {
        VStack(spacing: 0) {
            // Title bar (draggable)
            ZStack {
                WindowDragArea()

                HStack(spacing: 6) {
                    Text("BlueNapkin")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primary.opacity(0.7))
                        .padding(.leading, 12)

                    Spacer()

                    Button(action: {
                        NotificationCenter.default.post(name: .exportCSV, object: nil)
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 11))
                            .foregroundColor(Color(NSColor.tertiaryLabelColor))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Export CSV (⌘E)")

                    Button(action: {
                        NSApplication.shared.keyWindow?.orderOut(nil)
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 13))
                            .foregroundColor(Color(NSColor.tertiaryLabelColor))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.trailing, 10)
                }
            }
            .frame(height: 32)
            .background(Color(NSColor.windowBackgroundColor))

            Color(NSColor.separatorColor).opacity(0.5).frame(height: 0.5)

            // Grid view
            GridView()
                .background(Color(NSColor.controlBackgroundColor))

        }
        .frame(minWidth: 400, maxWidth: .infinity, minHeight: 300, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color(NSColor.separatorColor).opacity(0.5), lineWidth: 0.5)
        )
        .overlay(alignment: .bottomLeading) {
            WindowResizeHandle(corner: .bottomLeft)
                .frame(width: 16, height: 16)
                .cursor(.resizeUpDown)
        }
        .overlay(alignment: .bottomTrailing) {
            WindowResizeHandle(corner: .bottomRight)
                .frame(width: 16, height: 16)
                .cursor(.resizeUpDown)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
