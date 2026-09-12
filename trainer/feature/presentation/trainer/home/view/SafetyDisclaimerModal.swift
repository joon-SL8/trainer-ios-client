import SwiftUI
import libfitness

struct SafetyDisclaimerModal: View {
    @Environment(\.dismiss) var dismiss
    let service = TAndCService()
    let onConfirm: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Safety Disclaimer")
                .font(.title)
                .bold()
            
            TermsOfUseContentView(type: .safetyDisclaimer)
            
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
