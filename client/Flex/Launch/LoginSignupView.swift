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
            Spacer()
            
            //CTA
            Text("Sign in or create a new account")
                .font(.title)
                .fontWeight(.semibold)
                .padding(.bottom, 32)

            // Phone number input
            HStack {
                Image(systemName: "flag.us.fill") // Replace with your flag icon
                    .resizable()
                    .frame(width: 24, height: 24)
                    .padding(.leading, 12)
                
                TextField("Phone number", text: $phoneNumber)
                    .keyboardType(.phonePad)
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground)) // Use UIColor.systemGroupedBackground for grouped style
                    .cornerRadius(8)
            }
            .frame(height: 56)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray, lineWidth: 1)
            )
            .padding(.horizontal)

            Text("We'll send a text to confirm your number. Standard messaging rates may apply.")
                .font(.footnote)
                .foregroundColor(.gray)
                .padding(.top, 4)
                .padding(.bottom, 32)
            
            // Continue button
            Button(action: {
                userViewModel.triggerTwilioOTP(phone: phoneNumber)
                userViewModel.phone = phoneNumber
                self.showOTPView = true
            }) {
                Text("Continue")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black) // Update to match your app's theme color
                    .cornerRadius(8)
            }
            .padding(.horizontal)
            
            HStack {
                Text("By entering here I agree to all the language in Flex's")
                    .font(.footnote)
                    .foregroundColor(.gray)
                Button("terms of service") {
                    // Handle terms of service action
                }
                .font(.footnote)
                .foregroundColor(.blue)
            }
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemGroupedBackground)) // Light gray background
        .edgesIgnoringSafeArea(.all)
    }
}

#Preview {
    LoginSignupView(showOTPView: .constant(false))
        .environmentObject(UserViewModel())
}
