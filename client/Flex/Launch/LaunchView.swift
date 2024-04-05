//
//  LaunchView.swift
//  Flex
//
//  Created by Rob Harrell on 3/24/24.
//

import SwiftUI

struct LaunchView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @EnvironmentObject var sharedViewModel: DateViewModel
    @EnvironmentObject var budgetViewModel: BudgetViewModel
    @State private var showOTPView: Bool = false
    
    @ViewBuilder
    var body: some View {
        Group {
            if userViewModel.isSignedIn {
                if userViewModel.hasCompletedNotificationSelection {
                    MainTabView()
                        .environmentObject(userViewModel)
                        .environmentObject(sharedViewModel)
                        .environmentObject(budgetViewModel)
                } else if userViewModel.hasCompletedAccountCreation {
                    NotificationView()
                        .environmentObject(userViewModel)
                } else if userViewModel.hasEnteredUserDetails {
                    AccountConnectionView()
                        .environmentObject(userViewModel)
                } else {
                    UserDetailsView()
                        .environmentObject(userViewModel)
                }
            } else {
                if showOTPView {
                    OTPView()
                        .environmentObject(userViewModel)
                } else {
                    LoginSignupView(showOTPView: $showOTPView)
                }
            }
        }
    }
}

#Preview {
    LaunchView()
        .environmentObject(UserViewModel())
        .environmentObject(DateViewModel())
        .environmentObject(BudgetViewModel(sharedViewModel: DateViewModel()))
}

