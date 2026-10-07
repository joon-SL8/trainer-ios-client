import SwiftUI
import MessageUI
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
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button(action: {
                    viewModel.emailFitFile()
                }) {
                    if viewModel.isEmailing {
                        ProgressView()
                    } else {
                        Image(systemName: "envelope")
                    }
                }
                .accessibilityLabel("Email FIT File")

                if viewModel.needsUpload {
                    Button(action: {
                        viewModel.upload()
                    }) {
                        if viewModel.isUploading {
                            ProgressView()
                        } else {
                            Text("Upload")
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.showMailComposer) {
            if let data = viewModel.mailAttachmentData {
                MailComposeView(
                    subject: "Workout FIT File: \(viewModel.session.name)",
                    body: "Attached is the FIT file for my indoor cycling session (\(viewModel.session.name)).",
                    attachmentData: data,
                    attachmentFilename: viewModel.mailAttachmentFilename
                ) { result in
                    switch result {
                    case .success(let mailResult):
                        print("Mail result: \(mailResult.rawValue)")
                    case .failure(let error):
                        print("Mail error: \(error.localizedDescription)")
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.showActivityView) {
            if let url = viewModel.fitFileURLForSharing {
                ActivityView(activityItems: [url])
            }
        }
        .alert("Email Error", isPresented: Binding(
            get: { viewModel.emailError != nil },
            set: { _ in viewModel.emailError = nil }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.emailError ?? "Unknown error")
        }
    }
}

