import SwiftUI
import libfitness

struct CalendarListView: View {
    @StateObject var viewModel: CalendarListViewModel
    
    init(date: Date) {
        _viewModel = StateObject(wrappedValue: CalendarListViewModel(date: date))
    }
    
    var body: some View {
        List {
            if viewModel.isLoading {
                ProgressView("Loading sessions...")
            } else if viewModel.sessions.isEmpty {
                Text("No sessions for this date")
            } else {
                if viewModel.needsUpload {
                    Button("Upload all") {
                        viewModel.uploadAll()
                    }
                    .foregroundColor(.blue)
                }
                ForEach(viewModel.sessions, id: \.self) { session in
                    sessionCard(for: session)
                }
            }
        }
        .navigationTitle("My Workout for \(viewModel.dateString)")
    }
    
    @ViewBuilder
    private func sessionCard(for session: libfitness.Session) -> some View {
        NavigationLink(destination: CalendarDetailView(session: session)) {
            VStack(alignment: .leading, spacing: 24) {
                Text(session.name)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        return "\(minutes) mins"
    }
}
