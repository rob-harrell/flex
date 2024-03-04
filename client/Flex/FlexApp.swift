//
//  FlexApp.swift
//  Flex
//
//  Created by Rob Harrell on 1/27/24.
//

import SwiftUI

@main
struct FlexApp: App {
    @StateObject var sharedViewModel = DateViewModel()
    @StateObject var userViewModel = UserViewModel()
    @StateObject var budgetViewModel = BudgetViewModel(sharedViewModel: DateViewModel())

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(userViewModel)
                .environmentObject(sharedViewModel)
                .environmentObject(budgetViewModel)
        }
    }
}
