import SwiftUI
import libfitness

struct CalendarView: View {
    @StateObject var viewModel: CalendarViewModel
    
    init(session: libfitness.Session) {
        _viewModel = StateObject(wrappedValue: CalendarViewModel(session: session))
    }
    
    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView("Loading session...")
            } else if let workout = viewModel.workout {
                // Similar to LibraryDetailView structure
                Text(workout.name)
                    .font(.largeTitle)
                // Add more details from workout
            } else if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
            } else {
                Text("No session data")
            }
        }
        .navigationTitle("Session Details")
    }
}
