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
    @State private var isShowingOTPView: Bool = false
    @State private var isShowingUserDetailsView: Bool = false
    @State private var isShowingInitialAccountConnectionView: Bool = false
    @State private var isShowingAdditionalAccountConnectionView: Bool = false
    @State private var isShowingMainTabView: Bool = false

    @ViewBuilder
    var body: some View {
        Group {
            if isShowingMainTabView {
                MainTabView()
                    .environmentObject(userViewModel)
                    .environmentObject(sharedViewModel)
                    .environmentObject(budgetViewModel)
            } else if isShowingOTPView {
                OTPView(showUserDetailsView: $isShowingUserDetailsView, showMainTabView: $isShowingMainTabView)
                    .environmentObject(userViewModel)
            } else if isShowingUserDetailsView {
                UserDetailsView(showInitialAccountConnectionView: $isShowingInitialAccountConnectionView)
                    .environmentObject(userViewModel)
            } else if isShowingInitialAccountConnectionView {
                InitialAccountConnectionView(showAdditionalAccountConnectionView: $isShowingAdditionalAccountConnectionView)
                    .environmentObject(userViewModel)
            } else if isShowingAdditionalAccountConnectionView {
                AdditionalAccountConnectionView(showMainTabView: $isShowingMainTabView)
                    .environmentObject(userViewModel)
            } else {
                LoginSignupView(showOTPView: $isShowingOTPView)
            }
        }
        .onAppear {
            if userViewModel.isSignedIn {
                // Load user info and all corresponding account/transaction info from core to populate views
                isShowingMainTabView = true
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

