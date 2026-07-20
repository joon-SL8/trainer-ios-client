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
//                Text("Total Time: \(formatDuration(session.totalTime))")
//                    .font(.subheadline)
//                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
//            .background(
//                RoundedRectangle(cornerRadius: 10)
//                    .stroke(Color.accentColor, lineWidth: 2)
//                    .background(Color(.systemBackground).cornerRadius(10))
//            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        return "\(minutes) mins"
    }
}
