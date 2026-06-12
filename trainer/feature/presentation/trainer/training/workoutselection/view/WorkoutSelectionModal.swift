import SwiftUI

struct WorkoutSelectionModal: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: WorkoutSelectionViewModel
    
    var body: some View {
        VStack {
            Text("Choose Your Workout")
                .font(.title2)
                .fontWeight(.bold)
                .padding()
            
            Spacer()
            
            Button(action: {
                viewModel.selectTodaysWorkout()
            }) {
                Label("Today's Workout", systemImage: "bolt.fill")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(15)
            }
            .padding(.horizontal)
            
            Button(action: {
                viewModel.chooseFromLibrary()
            }) {
                Label("Choose from Library", systemImage: "books.vertical.fill")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(15)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .presentationDetents([.medium]) // Half-sheet presentation
        // PRD specifies modal should not be dismissible without selection
        .interactiveDismissDisabled(true)
        .onChange(of: viewModel.showSensorSelection) { shouldShow in
            if shouldShow {
                dismiss() // Dismiss this modal to proceed
            }
        }
        .onChange(of: viewModel.showLibrary) { shouldShow in
            if shouldShow {
                dismiss() // Dismiss this modal to proceed
            }
        }
    }
}

#Preview {
    WorkoutSelectionModal(viewModel: WorkoutSelectionViewModel())
}