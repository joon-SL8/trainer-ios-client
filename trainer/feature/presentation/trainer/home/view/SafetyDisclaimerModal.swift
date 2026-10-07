import SwiftUI
import libfitness

struct LegalAgreementModal: View {
    @Binding var isPresented: Bool
    let type: libfitness.TAndC
    let title: String
    let service = TAndCService()
    @State private var hasAgreed = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text(title)
                .font(.title)
                .bold()
            
            TermsOfUseContentView(type: type)
            
            Toggle(isOn: $hasAgreed) {
                Text("I agree")
            }
            .padding()
            
            HStack(spacing: 20) {
                Button("Cancel") {
                    exit(0)
                }
                .foregroundColor(.red)
                
                Button("OK") {
                    Task {
                        await service.update(type: type, isAgreed: true)
                        isPresented = false
                    }
                }
                .disabled(!hasAgreed)
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .padding()
        .interactiveDismissDisabled()
    }
}

struct SafetyDisclaimerAgreementModal: View {
    @Binding var isPresented: Bool
    var body: some View {
        LegalAgreementModal(isPresented: $isPresented, type: .safetyDisclaimer, title: "Safety Disclaimer")
    }
}

struct SessionBeginWarningModal: View {
    @Environment(\.dismiss) var dismiss
    let service = TAndCService()
    let onConfirm: () -> Void
    @State private var content: String = "Loading..."
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Session Begin Warning")
                .font(.title)
                .bold()
            
            HTMLWebView(htmlContent: content)
                .frame(maxHeight: .infinity)
                .border(Color.gray)
                .onAppear {
                    let rawContent = service.getSessionBeginWarningContent()
                    content = rawContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Content not available." : rawContent
                }
            
            HStack(spacing: 20) {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.red)
                
                Button("Confirm") {
                    onConfirm()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .padding()
        .interactiveDismissDisabled()
    }
}

// Backwards compatibility alias if referenced elsewhere
typealias SafetyDisclaimerModal = SessionBeginWarningModal
