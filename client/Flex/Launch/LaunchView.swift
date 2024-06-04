//
//  LaunchView.swift
//  Flex
//
//  Created by Rob Harrell on 3/24/24.
//

import SwiftUI

struct LaunchView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @State private var showOTPview: Bool = false

    @ViewBuilder
    var body: some View {
        if userViewModel.isSignedIn {
            if userViewModel.hasEnteredUserDetails {
                MainTabView()
                    .environmentObject(userViewModel)
            } else {
                UserDetailsView()
                    .environmentObject(userViewModel)
            }
        } else {
            Group {
                if showOTPview {
                    OTPView()
                } else {
                    LoginSignupView(showOTPView: $showOTPview)
                }
            }
            .environmentObject(userViewModel)
        }
    }
}

#Preview {
    LaunchView()
        .environmentObject(UserViewModel())
}

