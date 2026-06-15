import SwiftUI

struct RawMRCView: View {
    let filePath: String
    @State private var content: String = ""
    @State private var isLoading: Bool = true
    
    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            HStack(alignment: .top, spacing: 10) {
                // Line numbers gutter
                VStack(alignment: .trailing, spacing: 0) {
                    ForEach(1..<max(2, content.components(separatedBy: .newlines).count + 1), id: \.self) { index in
                        Text("\(index)")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.trailing, 5)
                .background(Color.gray.opacity(0.1))
                
                // File content
                Text(content)
                    .font(.system(.caption, design: .monospaced))
            }
            .padding()
        }
        .navigationTitle("Raw MRC")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadContent()
        }
    }
    
    private func loadContent() {
        do {
            content = try String(contentsOfFile: filePath, encoding: .utf8)
        } catch {
            content = "Error loading file content."
        }
        isLoading = false
    }
}
