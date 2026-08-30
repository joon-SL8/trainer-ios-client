import SwiftUI
import libfitness

struct TAndCView: View {
    let service = TAndCService()
    let types: [LibfitnessTAndC] = [
        .termsofuser,
        .safetydisclaimer,
        .privacypolicy
    ]
    
    @State private var statuses: [String: LibfitnessTAndCAgreement?] = [:]
    
    private func getName(for type: LibfitnessTAndC) -> String {
        if type == .termsofuser { return "Terms of Use" }
        if type == .safetydisclaimer { return "Safety Disclaimer" }
        if type == .privacypolicy { return "Privacy Policy" }
        return "Unknown"
    }
    
    var body: some View {
        List(types, id: \.self) { type in
            HStack {
                Text(getName(for: type))
                Spacer()
                if let status = statuses[getName(for: type)], let s = status {
                    Toggle("", isOn: Binding(
                        get: { s.isAgreed },
                        set: { newValue in
                            Task {
                                await service.update(type: type, isAgreed: newValue)
                                await loadStatuses()
                            }
                        }
                    ))
                } else {
                    ProgressView()
                }
            }
        }
        .onAppear(perform: {
            Task {
                await loadStatuses()
            }
        })
    }
    
    private func loadStatuses() async {
        for type in types {
            let status = await service.getStatus(type: type)
            await MainActor.run {
                statuses[getName(for: type)] = status
            }
        }
    }
}
