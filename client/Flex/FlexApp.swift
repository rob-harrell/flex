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
    @StateObject var dateViewModel = DateViewModel()
    @StateObject var userViewModel = UserViewModel()
    @StateObject var plaidLinkViewModel = PlaidLinkViewModel()
    @StateObject var budgetViewModel = BudgetViewModel()
    @StateObject var coreDataStack = CoreDataStack.shared

    var body: some Scene {
        WindowGroup {
            LaunchView()
                .environmentObject(userViewModel)
                .environmentObject(dateViewModel)
                .environmentObject(plaidLinkViewModel)
                .environmentObject(budgetViewModel)
                .environment(\.managedObjectContext, coreDataStack.persistentContainer.viewContext)
        }
    }
}
