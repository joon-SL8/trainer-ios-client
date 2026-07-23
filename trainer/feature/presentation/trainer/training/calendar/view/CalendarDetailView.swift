import SwiftUI
import libfitness

struct CalendarDetailView: View {
    @StateObject var viewModel: CalendarDetailViewModel

    init(session: libfitness.Session) {
        _viewModel = StateObject(wrappedValue: CalendarDetailViewModel(session: session))
    }

    var body: some View {
        ScrollView {
            if viewModel.isLoading {
                ProgressView("Loading details...")
            } else {
                VStack(spacing: 20) {
                    Text(viewModel.session.name)
                        .font(.largeTitle)

                    if let tss = viewModel.tss, let np = viewModel.np {
                        HStack(spacing: 0) {
                            VStack(spacing: 4) {
                                Text("TSS").font(.caption).foregroundColor(.secondary)
                                let data = tss > 0 && tss < 2000 ? String(format: "%.0f W", tss) : "-"
                                Text(data).font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            
                            VStack(spacing: 4) {
                                Text("NP").font(.caption).foregroundColor(.secondary)
                                let data = np > 0 && np < 2000 ? String(format: "%.0f W", np) : "-"
                                Text(data).font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal, 48)
                    }

                    LineGraphView(title: "Power", data: viewModel.sessionEntries.map { Double($0.power) })
                    LineGraphView(title: "Heart Rate", data: viewModel.sessionEntries.map { Double($0.heart) })
                    LineGraphView(title: "Cadence", data: viewModel.sessionEntries.map { Double($0.cadence) })
                    LineGraphView(title: "Speed", data: viewModel.sessionEntries.map { Double($0.speed) })
                }
                .padding(.horizontal, 48)
                .padding(.vertical)
            }
        }
        .navigationTitle("Session Details")
    }
}

