import SwiftUI

struct BluetoothHardwareUnsupportedView: View {
    var onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "exclamationmark.shield.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .foregroundColor(.orange)
                .padding(.top, 40)
            
            Text("Limited Access Mode")
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("Bluetooth connectivity is a core requirement for Skjline's sensor-driven tracking. As your device does not currently support the necessary hardware, the application will operate on a limited basis. You may still access your historical data and profile, but workout sessions will be unavailable.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            
            Spacer()
            
            Button(action: {
                onDismiss()
            }) {
                Text("Continue to Limited App")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 60)
        }
        .padding()
    }
}

#Preview {
    BluetoothHardwareUnsupportedView(onDismiss: {})
}
