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
    func makeNSView(context: Context) -> NSView { DraggableView() }
    func updateNSView(_ nsView: NSView, context: Context) {}

    private class DraggableView: NSView {
        override func mouseDown(with event: NSEvent) {
            window?.performDrag(with: event)
        }
    }
}

struct ContentView: View {
    private static let brandBlue  = Color(red: 0.38, green: 0.56, blue: 0.82)
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

            GridView()
                .background(Color(red: 0.985, green: 0.988, blue: 0.993))
        }
        .background(Self.titleBarBg)
        .frame(minWidth: 400, maxWidth: .infinity, minHeight: 300, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Self.brandBlue.opacity(0.2), lineWidth: 0.5))
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View { ContentView() }
}
