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

    var body: some View {
        VStack {
            // ... rest of your code ...

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
            }
            .padding()
        }
    }
}

#Preview {
    OTPView(showUserDetailsView: .constant(false), showMainTabView: .constant(false))
}
