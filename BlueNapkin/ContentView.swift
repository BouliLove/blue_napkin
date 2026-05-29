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

/// Pure-SwiftUI resize handle for a window edge or corner.
/// Uses DragGesture + contentShape so hit-testing works even on a
/// transparent non-opaque panel where AppKit would let clicks fall through.
struct ResizeHandle: View {
    let region: ResizeRegion
    @State private var isDragging = false
    @State private var initialFrame: NSRect = .zero

    var body: some View {
        Color.clear
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { value in
                        guard let window = NSApp.windows.first(where: { $0 is NSPanel && $0.isVisible }) else { return }
                        if !isDragging {
                            isDragging = true
                            initialFrame = window.frame
                        }
                        applyResize(to: window, translation: value.translation)
                    }
                    .onEnded { _ in isDragging = false }
            )
            .cursor(region.nsCursor)
    }

    private func applyResize(to window: NSWindow, translation: CGSize) {
        var frame = initialFrame
        let tx = translation.width
        // SwiftUI y is downward; screen y is upward — sign is intentionally
        // positive for bottom (drag down → taller) and negative for top.
        let ty = translation.height
        let minW = window.minSize.width, maxW = window.maxSize.width
        let minH = window.minSize.height, maxH = window.maxSize.height

        switch region {
        case .right:
            frame.size.width = max(minW, min(maxW, initialFrame.width + tx))
        case .left:
            let newW = max(minW, min(maxW, initialFrame.width - tx))
            frame.origin.x = initialFrame.maxX - newW
            frame.size.width = newW
        case .bottom:
            let newH = max(minH, min(maxH, initialFrame.height + ty))
            frame.origin.y = initialFrame.maxY - newH
            frame.size.height = newH
        case .top:
            let newH = max(minH, min(maxH, initialFrame.height - ty))
            frame.size.height = newH
        case .bottomRight:
            frame.size.width = max(minW, min(maxW, initialFrame.width + tx))
            let newH = max(minH, min(maxH, initialFrame.height + ty))
            frame.origin.y = initialFrame.maxY - newH
            frame.size.height = newH
        case .bottomLeft:
            let newW = max(minW, min(maxW, initialFrame.width - tx))
            frame.origin.x = initialFrame.maxX - newW
            frame.size.width = newW
            let newH = max(minH, min(maxH, initialFrame.height + ty))
            frame.origin.y = initialFrame.maxY - newH
            frame.size.height = newH
        case .topRight:
            frame.size.width = max(minW, min(maxW, initialFrame.width + tx))
            let newH = max(minH, min(maxH, initialFrame.height - ty))
            frame.size.height = newH
        case .topLeft:
            let newW = max(minW, min(maxW, initialFrame.width - tx))
            frame.origin.x = initialFrame.maxX - newW
            frame.size.width = newW
            let newH = max(minH, min(maxH, initialFrame.height - ty))
            frame.size.height = newH
        }

        window.setFrame(frame, display: true, animate: false)
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
            ResizeHandle(region:.top)
                .frame(height: 5).frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .cursor(ResizeRegion.top.nsCursor)
        }
        .overlay(alignment: .bottom) {
            ResizeHandle(region:.bottom)
                .frame(height: 5).frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .cursor(ResizeRegion.bottom.nsCursor)
        }
        .overlay(alignment: .leading) {
            ResizeHandle(region:.left)
                .frame(width: 5).frame(maxHeight: .infinity)
                .contentShape(Rectangle())
                .cursor(ResizeRegion.left.nsCursor)
        }
        .overlay(alignment: .trailing) {
            ResizeHandle(region:.right)
                .frame(width: 5).frame(maxHeight: .infinity)
                .contentShape(Rectangle())
                .cursor(ResizeRegion.right.nsCursor)
        }
        // Corners — 14×14pt, placed after edges for hit-test priority
        .overlay(alignment: .topLeading) {
            ResizeHandle(region:.topLeft)
                .frame(width: 14, height: 14)
                .contentShape(Rectangle())
                .cursor(ResizeRegion.topLeft.nsCursor)
        }
        .overlay(alignment: .topTrailing) {
            ResizeHandle(region:.topRight)
                .frame(width: 14, height: 14)
                .contentShape(Rectangle())
                .cursor(ResizeRegion.topRight.nsCursor)
        }
        .overlay(alignment: .bottomLeading) {
            ResizeHandle(region:.bottomLeft)
                .frame(width: 14, height: 14)
                .contentShape(Rectangle())
                .cursor(ResizeRegion.bottomLeft.nsCursor)
        }
        .overlay(alignment: .bottomTrailing) {
            ResizeHandle(region:.bottomRight)
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
