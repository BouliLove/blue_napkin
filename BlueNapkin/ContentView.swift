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
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
