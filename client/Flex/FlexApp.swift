//
//  FlexApp.swift
//  Flex
//
//  Created by Rob Harrell on 1/27/24.
//

import SwiftUI

@main
struct FlexApp: App {
    @StateObject var sharedViewModel = SharedViewModel()
    @StateObject var userViewModel = UserViewModel()
    @StateObject var budgetViewModel = BudgetViewModel(sharedViewModel: SharedViewModel())

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(userViewModel)
                .environmentObject(sharedViewModel)
                .environmentObject(budgetViewModel)
        }
    }
}
