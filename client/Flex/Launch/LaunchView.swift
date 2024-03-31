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
                if userViewModel.hasEnteredUserDetails && userViewModel.hasCompletedAccountCreation {
                    MainTabView()
                        .environmentObject(userViewModel)
                        .environmentObject(sharedViewModel)
                        .environmentObject(budgetViewModel)
                } else if userViewModel.hasEnteredUserDetails && !userViewModel.hasCompletedAccountCreation {
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
        .onAppear {
            if userViewModel.isSignedIn {
                        print("User ID: \(userViewModel.id)")
                        print("First Name: \(userViewModel.firstName)")
                        print("Last Name: \(userViewModel.lastName)")
                        print("Date of Birth: \(userViewModel.birthDate)")
                // Load user info and all corresponding account/transaction info from core to populate views
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

