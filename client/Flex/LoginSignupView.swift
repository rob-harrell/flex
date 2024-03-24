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
            }) {
                Text("Continue")
            }
            .padding()
        }
    }
}

#Preview {
    LoginSignupView()
        .environmentObject(UserViewModel())
}
