import SwiftUI

struct VividButtonStyle: ButtonStyle {
    var backgroundColor: Color
    var isEnabled: Bool = true
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title2)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .background(isEnabled ? backgroundColor : Color.gray)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .brightness(configuration.isPressed ? -0.05 : 0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

extension View {
    func vividButtonStyle(color: Color, isEnabled: Bool = true) -> some View {
        self.buttonStyle(VividButtonStyle(backgroundColor: color, isEnabled: isEnabled))
    }
}
