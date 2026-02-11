import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            HStack {
                Text("BlueNapkin")
                    .font(.headline)
                    .padding(.leading, 12)

                Spacer()

                Button(action: {
                    NSApplication.shared.keyWindow?.orderOut(nil)
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .imageScale(.medium)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.trailing, 12)
            }
            .frame(height: 36)
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // Grid view
            GridView()
                .background(Color(NSColor.controlBackgroundColor))

        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
