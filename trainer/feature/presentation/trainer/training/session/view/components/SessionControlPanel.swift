import SwiftUI

struct SessionControlPanel: View {
    @ObservedObject var viewModel: SessionViewModel
    var onExit: () -> Void
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 24) {
            // Only show Exit button if not active or if paused
            if viewModel.state != .active {
                Button(action: onExit) {
                    VStack(spacing: 4) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                        Text("EXIT")
                            .font(.caption2)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                    .frame(width: 72, height: 72)
                    .background(Color.gray)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .transition(.scale.combined(with: .opacity))
            }

            Button(action: {
                if viewModel.state == .active {
                    viewModel.pauseSession()
                } else {
                    viewModel.startSession()
                }
            }) {
                VStack(spacing: 4) {
                    Image(systemName: viewModel.state == .active ? "pause.fill" : "play.fill")
                        .font(.title2)
                    Text(viewModel.state == .active ? "PAUSE" : "START")
                        .font(.caption2)
                        .fontWeight(.bold)
                }
                .foregroundColor(.white)
                .frame(width: 72, height: 72)
                .background(Color.blue)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            
            Button(action: {
                viewModel.pauseSession()
            }) {
                VStack(spacing: 4) {
                    Image(systemName: "stop.fill")
                        .font(.title3)
                    Text("STOP")
                        .font(.caption2)
                        .fontWeight(.bold)
                }
                .foregroundColor(.white)
                .frame(width: 72, height: 72)
                .background(Color.red)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .red.opacity(0.3), radius: 8, x: 0, y: 4)
            }
        }
    }
}
