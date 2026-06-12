//
//  DeeplinkSimulationSheet.swift
//  mobile
//
//  Created by Gemini on 4/13/26.
//

import SwiftUI

struct DeeplinkOption: Identifiable {
    let id = UUID()
    let label: String
    let url: URL?
}

struct DeeplinkSimulationSheet: View {
    @Environment(\.dismiss) var dismiss
    let options: [DeeplinkOption]
    let onSelect: (DeeplinkOption) -> Void

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 10) {
                Text("Select a destination from below")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)

                List(options) { option in
                    Button {
                        onSelect(option)
                        dismiss()
                    } label: {
                        Text(option.label)
                            .foregroundColor(.primary)
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle("Deeplink Simulation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    DeeplinkSimulationSheet(options: [
        DeeplinkOption(label: "Main View", url: URL(string: "skjline://main")),
        DeeplinkOption(label: "Mock Session", url: URL(string: "skjline://session?mock=true"))
    ]) { option in
        print("Selected: \(option.label)")
    }
}
