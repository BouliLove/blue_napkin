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
                    NSApplication.shared.keyWindow?.close()
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

            Divider()

            // Footer with info
            HStack {
                Text("Tip: Use formulas like =A1+B2 or functions like =SUM(A1:A10), =AVERAGE(B1:B5), =PRODUCT(C1:C3)")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .padding(.leading, 12)

                Spacer()
            }
            .frame(height: 24)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: 600, height: 400)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
