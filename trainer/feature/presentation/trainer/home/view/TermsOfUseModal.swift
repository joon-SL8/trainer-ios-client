import SwiftUI
import libfitness

struct TermsOfUseContentView: View {
    let service = TAndCService()
    let type: libfitness.TAndC
    @State private var content: String = "Loading..."
    
    var body: some View {
        ScrollView {
            Text(content)
                .padding()
        }
        .frame(maxHeight: .infinity)
        .border(Color.gray)
        .onAppear {
            content = service.getContent(type: type)
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
    let service = TAndCService()
    @State private var hasAgreed = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Terms of Use")
                .font(.title)
                .bold()
            
            TermsOfUseContentView(type: .termsOfUse)
            
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
                        await service.update(type: .termsOfUse, isAgreed: true)
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
