import SwiftUI
import libfitness

struct TAndCView: View {
    let service = TAndCService()
    let types: [libfitness.TAndC] = [
        .termsOfUse,
        .safetyDisclaimer,
        .privacyPolicy
    ]
    
    @State private var statuses: [String: libfitness.TAndCAgreement?] = [:]
    
    private func getName(for type: libfitness.TAndC) -> String {
        if type == .termsOfUse { return "Terms of Use" }
        if type == .safetyDisclaimer { return "Safety Disclaimer" }
        if type == .privacyPolicy { return "Privacy Policy" }
        return "Unknown"
    }
    
    var body: some View {
        List(types, id: \.self) { type in
            if type == .termsOfUse {
                NavigationLink(destination: TermsOfUseView()) {
                    rowContent(for: type)
                }
            } else {
                rowContent(for: type)
            }
        }
        .onAppear(perform: {
            Task {
                await loadStatuses()
            }
        })
    }
    
    @ViewBuilder
    private func rowContent(for type: libfitness.TAndC) -> some View {
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
                .onTapGesture {
                    // Prevent toggle from triggering navigation
                }
            } else {
                ProgressView()
            }
        }
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
