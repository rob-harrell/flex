//
//  FlexApp.swift
//  Flex
//
//  Created by Rob Harrell on 1/27/24.
//

import SwiftUI
import CoreData

class AppViewModel: ObservableObject {
    @Published var sharedViewModel: DateViewModel
    @Published var userViewModel = UserViewModel()
    @Published var budgetViewModel: BudgetViewModel
    @Published var plaidLinkViewModel = PlaidLinkViewModel()

    init() {
        let sharedViewModel = DateViewModel()
        self.sharedViewModel = sharedViewModel
        self.budgetViewModel = BudgetViewModel(sharedViewModel: sharedViewModel)
    }
}

@main
struct FlexApp: App {
    @StateObject var appViewModel = AppViewModel()
    @StateObject var coreDataStack = CoreDataStack.shared

    var body: some Scene {
        WindowGroup {
            if appViewModel.userViewModel.isSignedIn {
                MainTabView()
            } else {
                LaunchView()
            }
        }
        .environmentObject(appViewModel.userViewModel)
        .environmentObject(appViewModel.sharedViewModel)
        .environmentObject(appViewModel.budgetViewModel)
        .environmentObject(appViewModel.plaidLinkViewModel)
        .environment(\.managedObjectContext, coreDataStack.persistentContainer.viewContext)
    }
}
