//
//  OTPView.swift
//  Flex
//
//  Created by Rob Harrell on 3/22/24.
//

import SwiftUI

struct OTPView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @State private var otp: String = ""
    @State private var isExistingUser: Bool = false
    @Binding var showUserDetailsView: Bool
    @Binding var showMainTabView: Bool
    
    var tempPhone = "7138062459"

    var body: some View {
        VStack {
            Text("Enter the 4-digit code sent to \(tempPhone)")
                .font(.title3)
                .bold()
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            HStack {
                ForEach(0..<4, id: \.self) { index in
                    OTPDigitView(digit: otp.count > index ? String(otp[otp.index(otp.startIndex, offsetBy: index)]) : "")
                }
            }
            
            Button(action: {
                // Resend code action
            }) {
                Text("Didn't receive a code? Resend code")
                    .font(.body)
                    .foregroundColor(.blue)
            }

            Button(action: {
                userViewModel.verifyTwilioOTP(code: otp, forPhone: userViewModel.phone) { isUserExisting in
                    self.isExistingUser = isUserExisting
                    if isUserExisting {
                        self.showMainTabView = true
                    } else {
                        self.showUserDetailsView = true
                    }
                }
            }) {
                Text("Verify OTP")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(otp.count == 4 ? Color.blue : Color.gray)
                    .cornerRadius(8)
                    .disabled(otp.count < 4)
            }
            .padding(.horizontal, 24)
        }
    }
}

struct OTPDigitView: View {
    var digit: String
    
    var body: some View {
        Text(digit)
            .font(.title)
            .frame(width: 64, height: 64)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray, lineWidth: 1)
            )
            .padding(4)
    }
}

#Preview {
    OTPView(showUserDetailsView: .constant(false), showMainTabView: .constant(false))
}
