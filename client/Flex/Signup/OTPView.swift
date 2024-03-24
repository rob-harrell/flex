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
    @State private var showNextView: Bool = false

    var body: some View {
        VStack {
            // ... rest of your code ...

            Button(action: {
                userViewModel.verifyTwilioOTP(code: otp, forPhone: userViewModel.phone) { isUserExisting in
                    self.isExistingUser = isUserExisting
                    self.showNextView = true
                }
            }) {
                Text("Verify OTP")
            }
            .padding()
            .fullScreenCover(isPresented: $showNextView) {
                if isExistingUser {
                    MainTabView()
                } else {
                    UserDetailsView()
                }
            }
        }
    }
}

#Preview {
    OTPView()
}
