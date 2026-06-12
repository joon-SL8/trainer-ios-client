import SwiftUI

struct ParsingProgressModal: View {
    let progress: Double
    let onCancel: () -> Void
    
    var body: some View {
        ZStack {
            // Background dim
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    // Prevent dismiss on tap outside if blocking is intended, 
                    // but here we have a cancel button.
                }
            
            // Modal Content
            VStack(spacing: 20) {
                Text("We're parsing selected training file...")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                
                ProgressView(value: progress, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle())
                    .padding(.horizontal)
                
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button(action: onCancel) {
                    Text("Cancel")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 30)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(radius: 10)
            .padding(.horizontal, 40)
        }
    }
}

#Preview {
    ParsingProgressModal(progress: 0.45) {
        print("Cancelled")
    }
}
