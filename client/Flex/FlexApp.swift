//
//  FlexApp.swift
//  Flex
//
//  Created by Rob Harrell on 1/27/24.
//

import SwiftUI
import CoreData

@main
struct FlexApp: App {
    @StateObject var sharedViewModel = DateViewModel()
    @StateObject var userViewModel = UserViewModel()
    @StateObject var plaidLinkViewModel = PlaidLinkViewModel()
    @StateObject var budgetViewModel = BudgetViewModel()
    @StateObject var coreDataStack = CoreDataStack.shared

    var body: some Scene {
        WindowGroup {
            LaunchView()
                .environmentObject(userViewModel)
                .environmentObject(sharedViewModel)
                .environmentObject(plaidLinkViewModel)
                .environmentObject(budgetViewModel)
                .environment(\.managedObjectContext, coreDataStack.persistentContainer.viewContext)
        }
    }
}
