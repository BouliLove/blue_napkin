import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            HStack(spacing: 6) {
                Text("BlueNapkin")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary.opacity(0.7))
                    .padding(.leading, 12)

                Spacer()

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
