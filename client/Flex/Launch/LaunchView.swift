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
    @StateObject private var budgetViewModel = BudgetViewModel()
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
                        .environmentObject(budgetViewModel)
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
        .onAppear {
            if userViewModel.isSignedIn && userViewModel.hasCompletedNotificationSelection {
                // Update BudgetViewModel when the user is signed in and has completed the notification selection
                budgetViewModel.update(sharedViewModel: sharedViewModel, userViewModel: userViewModel)
            }
        }
    }
}

#Preview {
    LaunchView()
        .environmentObject(UserViewModel())
        .environmentObject(DateViewModel())
        .environmentObject(BudgetViewModel(sharedViewModel: DateViewModel(), userViewModel: UserViewModel()))
}

