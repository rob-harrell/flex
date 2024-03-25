//
//  LoginSignupView.swift
//  Flex
//
//  Created by Rob Harrell on 3/22/24.
//

import SwiftUI

struct LoginSignupView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @State private var phoneNumber: String = ""
    @Binding var showOTPView: Bool

    var body: some View {
        VStack {
            Text("Welcome to Flex")
                .font(.largeTitle)
                .padding()

            Text("Please enter your phone number to get started")
                .font(.headline)
                .padding()

            TextField("Phone Number", text: $phoneNumber)
                .keyboardType(.phonePad)
                .padding()

            Button(action: {
                userViewModel.triggerTwilioOTP(phone: phoneNumber)
                self.showOTPView = true
            }) {
                Text("Continue")
            }
            .padding()
        }
    }
}

#Preview {
    LoginSignupView(showOTPView: .constant(false))
        .environmentObject(UserViewModel())
}
