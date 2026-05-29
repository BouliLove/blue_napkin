import SwiftUI
import AppKit

extension Notification.Name {
    static let exportCSV = Notification.Name("BlueNapkin.exportCSV")
    static let setCellFormat = Notification.Name("BlueNapkin.setCellFormat")
    static let increaseDecimals = Notification.Name("BlueNapkin.increaseDecimals")
    static let decreaseDecimals = Notification.Name("BlueNapkin.decreaseDecimals")
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

enum ResizeRegion {
    case top, bottom, left, right
    case topLeft, topRight, bottomLeft, bottomRight

    var nsCursor: NSCursor {
        if #available(macOS 15.0, *) {
            switch self {
            case .top, .bottom:    return .resizeUpDown
            case .left, .right:    return .resizeLeftRight
            case .topLeft:         return .frameResize(position: .topLeft, directions: .all)
            case .topRight:        return .frameResize(position: .topRight, directions: .all)
            case .bottomLeft:      return .frameResize(position: .bottomLeft, directions: .all)
            case .bottomRight:     return .frameResize(position: .bottomRight, directions: .all)
            }
        }
        switch self {
        case .top, .bottom: return .resizeUpDown
        default:            return .resizeLeftRight
        }
    }
}

/// Invisible resize handle for a window edge or corner. Drag to resize.
struct WindowResizeHandle: NSViewRepresentable {
    let region: ResizeRegion

    func makeNSView(context: Context) -> NSView { ResizeView(region: region) }
    func updateNSView(_ nsView: NSView, context: Context) {}

    private class ResizeView: NSView {
        let region: ResizeRegion
        private var initialFrame: NSRect = .zero
        private var initialMouse: NSPoint = .zero

        init(region: ResizeRegion) {
            self.region = region
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
            let minW = window.minSize.width, maxW = window.maxSize.width
            let minH = window.minSize.height, maxH = window.maxSize.height

            switch region {
            case .right:
                frame.size.width = max(minW, min(maxW, initialFrame.width + dx))
            case .left:
                let newW = max(minW, min(maxW, initialFrame.width - dx))
                frame.origin.x = initialFrame.maxX - newW
                frame.size.width = newW
            case .bottom:
                let newH = max(minH, min(maxH, initialFrame.height - dy))
                frame.origin.y = initialFrame.maxY - newH
                frame.size.height = newH
            case .top:
                frame.size.height = max(minH, min(maxH, initialFrame.height + dy))
            case .bottomRight:
                frame.size.width = max(minW, min(maxW, initialFrame.width + dx))
                let newH = max(minH, min(maxH, initialFrame.height - dy))
                frame.origin.y = initialFrame.maxY - newH
                frame.size.height = newH
            case .bottomLeft:
                let newW = max(minW, min(maxW, initialFrame.width - dx))
                frame.origin.x = initialFrame.maxX - newW
                frame.size.width = newW
                let newH = max(minH, min(maxH, initialFrame.height - dy))
                frame.origin.y = initialFrame.maxY - newH
                frame.size.height = newH
            case .topRight:
                frame.size.width = max(minW, min(maxW, initialFrame.width + dx))
                frame.size.height = max(minH, min(maxH, initialFrame.height + dy))
            case .topLeft:
                let newW = max(minW, min(maxW, initialFrame.width - dx))
                frame.origin.x = initialFrame.maxX - newW
                frame.size.width = newW
                frame.size.height = max(minH, min(maxH, initialFrame.height + dy))
            }

            window.setFrame(frame, display: true, animate: false)
        }
    }
}

struct ContentView: View {
    private static let brandBlue = Color(red: 0.38, green: 0.56, blue: 0.82)
    private static let titleBarBg = Color(red: 0.96, green: 0.97, blue: 0.98)

    var body: some View {
        VStack(spacing: 0) {
            // Title bar (draggable)
            ZStack {
                WindowDragArea()

                HStack(spacing: 6) {
                    Text("BlueNapkin")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Self.brandBlue)
                        .padding(.leading, 12)

                    Spacer()

                    HStack(spacing: 3) {
                        ForEach([("€", "currencyEUR"), ("$", "currencyUSD"), ("1,0", "number"), ("%", "percentage")], id: \.0) { label, format in
                            Button(action: {
                                NotificationCenter.default.post(name: .setCellFormat, object: nil, userInfo: ["format": format])
                            }) {
                                Text(label)
                                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                                    .foregroundColor(Color(NSColor.tertiaryLabelColor))
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 2)
                                    .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                                    .clipShape(RoundedRectangle(cornerRadius: 3))
                            }
                            .buttonStyle(PlainButtonStyle())
                            .help(format.replacingOccurrences(of: "currency", with: ""))
                        }
                    }
                    .padding(.trailing, 2)

                    HStack(spacing: 2) {
                        Button(action: {
                            NotificationCenter.default.post(name: .decreaseDecimals, object: nil)
                        }) {
                            Text(".0")
                                .font(.system(size: 9, weight: .medium, design: .monospaced))
                                .foregroundColor(Color(NSColor.tertiaryLabelColor))
                                .padding(.horizontal, 3)
                                .padding(.vertical, 2)
                                .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                                .clipShape(RoundedRectangle(cornerRadius: 3))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .help("Decrease decimals")

                        Button(action: {
                            NotificationCenter.default.post(name: .increaseDecimals, object: nil)
                        }) {
                            Text(".00")
                                .font(.system(size: 9, weight: .medium, design: .monospaced))
                                .foregroundColor(Color(NSColor.tertiaryLabelColor))
                                .padding(.horizontal, 3)
                                .padding(.vertical, 2)
                                .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                                .clipShape(RoundedRectangle(cornerRadius: 3))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .help("Increase decimals")
                    }
                    .padding(.trailing, 6)

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
            .background(Self.titleBarBg)

            Self.brandBlue.opacity(0.3).frame(height: 1)

            // Grid view
            GridView()
                .background(Color(red: 0.985, green: 0.988, blue: 0.993))

        }
        .background(Self.titleBarBg)
        .frame(minWidth: 400, maxWidth: .infinity, minHeight: 300, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Self.brandBlue.opacity(0.2), lineWidth: 0.5)
        )
        // Edge strips — 5pt, full span
        .overlay(alignment: .top) {
            WindowResizeHandle(region: .top)
                .frame(height: 5).frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .cursor(ResizeRegion.top.nsCursor)
        }
        .overlay(alignment: .bottom) {
            WindowResizeHandle(region: .bottom)
                .frame(height: 5).frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .cursor(ResizeRegion.bottom.nsCursor)
        }
        .overlay(alignment: .leading) {
            WindowResizeHandle(region: .left)
                .frame(width: 5).frame(maxHeight: .infinity)
                .contentShape(Rectangle())
                .cursor(ResizeRegion.left.nsCursor)
        }
        .overlay(alignment: .trailing) {
            WindowResizeHandle(region: .right)
                .frame(width: 5).frame(maxHeight: .infinity)
                .contentShape(Rectangle())
                .cursor(ResizeRegion.right.nsCursor)
        }
        // Corners — 14×14pt, placed after edges for hit-test priority
        .overlay(alignment: .topLeading) {
            WindowResizeHandle(region: .topLeft)
                .frame(width: 14, height: 14)
                .contentShape(Rectangle())
                .cursor(ResizeRegion.topLeft.nsCursor)
        }
        .overlay(alignment: .topTrailing) {
            WindowResizeHandle(region: .topRight)
                .frame(width: 14, height: 14)
                .contentShape(Rectangle())
                .cursor(ResizeRegion.topRight.nsCursor)
        }
        .overlay(alignment: .bottomLeading) {
            WindowResizeHandle(region: .bottomLeft)
                .frame(width: 14, height: 14)
                .contentShape(Rectangle())
                .cursor(ResizeRegion.bottomLeft.nsCursor)
        }
        .overlay(alignment: .bottomTrailing) {
            WindowResizeHandle(region: .bottomRight)
                .frame(width: 14, height: 14)
                .contentShape(Rectangle())
                .cursor(ResizeRegion.bottomRight.nsCursor)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
