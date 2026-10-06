import SwiftUI
import WebKit
import libfitness

struct HTMLWebView: UIViewRepresentable {
    let htmlContent: String

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.backgroundColor = .clear
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let styledHTML = """
        <html>
        <head>
        <style>
            body { font-family: -apple-system, Helvetica, Arial, sans-serif; font-size: 13pt; color: #333; padding: 10px; background-color: transparent; }
            h1, h2, h3 { color: #111; }
            @media (prefers-color-scheme: dark) {
                body { color: #f0f0f0; }
                h1, h2, h3 { color: #ffffff; }
            }
        </style>
        </head>
        <body>
        \(htmlContent)
        </body>
        </html>
        """
        webView.loadHTMLString(styledHTML, baseURL: nil)
    }
}

struct TermsOfUseContentView: View {
    let service = TAndCService()
    let type: libfitness.TAndC
    @State private var content: String = "Loading..."
    
    var body: some View {
        HTMLWebView(htmlContent: content)
            .frame(maxHeight: .infinity)
            .border(Color.gray)
            .onAppear {
                let rawContent = service.getContent(type: type)
                content = rawContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Content not available." : rawContent
            }
    }
}

struct TermsOfUseView: View {
    var body: some View {
        TermsOfUseContentView(type: .termsOfUse)
            .navigationTitle("Terms of Use")
            .padding()
    }
}

struct TermsOfUseModal: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        LegalAgreementModal(isPresented: $isPresented, type: .termsOfUse, title: "Terms of Use")
    }
}
