//
//  SplashScreenView.swift
//  mobile
//
//  Created by Joon Lee on 11/26/25.
//

import SwiftUI

struct SplashScreenView: View {
    @Binding var showSplash: Bool

    var body: some View {
        VStack {
            Image("ic_s_logo")
                .resizable()
                .scaledToFit()
                .frame(width: 240, height: 240)
            Text("Skjline") // Optional app name or branding
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity) // Make VStack take full screen
        .background(Color.white) // Add white background
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.showSplash = false
            }
        }
    }
}

#Preview {
    SplashScreenView(showSplash: .constant(true))
}
