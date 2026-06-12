import SwiftUI

struct BluetoothPermissionExplanationView: View {
    var onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "bolt.horizontal.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .foregroundColor(.blue)
                .padding(.top, 40)
            
            Text("Bluetooth is Required")
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("Skjline needs Bluetooth to connect to your fitness sensors (Heart Rate, Power, etc.) and accurately track your workouts. This is a core feature of the app.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            
            Spacer()
            
            Button(action: {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }) {
                Text("Open Settings")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            
            Button(action: {
                onDismiss()
            }) {
                Text("Later")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
            .padding(.bottom, 40)
        }
        .padding()
    }
}

#Preview {
    BluetoothPermissionExplanationView(onDismiss: {})
}
