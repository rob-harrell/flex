//
//  NavigationView.swift
//  Flex
//
//  Created by Rob Harrell on 1/27/24.
//

import SwiftUI
import CoreData

struct MainTabView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @EnvironmentObject var sharedViewModel: DateViewModel
    @EnvironmentObject var budgetViewModel: BudgetViewModel
    @State private var selectedTab: Tab = .budget
    @State private var showingMonthSelection = false
    
    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                BudgetView()
                    .tabItem {
                        Label("Budget", image: "Budget")
                    }
                    .tag(Tab.budget)

                BalancesView()
                    .tabItem {
                        Label("Balances", image: "Balances")
                    }
                    .tag(Tab.balances)
                
                TrendsView()
                    .tabItem {
                        Label("Trends", image: "Trends")
                    }
                    .tag(Tab.trends)
                
                SettingsView()
                    .tabItem {
                        Label("Settings", image: "Settings")
                    }
                    .tag(Tab.settings)
            }
            .onAppear {
                // Initialize budgetviewmodel
                loadBudgetPreferences()
                budgetViewModel.fetchTransactionsFromServer(userId: userViewModel.id, monthlyIncome: userViewModel.monthlyIncome, monthlyFixedSpend: userViewModel.monthlyFixedSpend)
                print("made it here without error")
                
                UITabBarItem.appearance().setTitleTextAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12)], for: .normal)
                UITabBarItem.appearance().setTitleTextAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12)], for: .selected)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack {
                        Button(action: {
                            showingMonthSelection.toggle()
                        }) {
                            HStack {
                                Image("Calendar")
                                Text(sharedViewModel.stringForDate(sharedViewModel.selectedMonth, format: "MMMM"))
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                        }
                        .padding(.horizontal, 4)
                        .background(RoundedRectangle(cornerRadius: 24).stroke(Color.slate200, lineWidth: 1))
                        .sheet(isPresented: $showingMonthSelection) {
                            MonthSelectorView(showingMonthSelection: $showingMonthSelection)
                        }
                        Button(action: {
                                    // Handle the button tap
                        }) {
                            HStack{
                                Image("Money")
                                Text(formatBudgetNumber(userViewModel.monthlyIncome))
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                        }
                        .padding(.horizontal, 4)
                        .background(RoundedRectangle(cornerRadius: 24).stroke(Color.slate200, lineWidth: 1))
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            // Handle the button tap
                        }) {
                            Image("Bell")
                        }
                }
            }
        }
        .padding(.top, 4)
    }
    
    private func loadBudgetPreferences() {
        let fetchRequest: NSFetchRequest<BudgetPreference> = BudgetPreference.fetchRequest()
        do {
            let context = CoreDataStack.shared.persistentContainer.viewContext
            let budgetPreferences = try context.fetch(fetchRequest)
            if budgetPreferences.isEmpty {
                // If the user has not edited budget preferences, load from the default CSV file
                if !userViewModel.hasEditedBudgetPreferences {
                    if let defaultBudgetPreferences = budgetViewModel.loadDefaultBudgetPreferencesFromJSON() {
                        budgetViewModel.budgetPreferences = defaultBudgetPreferences
                        budgetViewModel.saveBudgetPreferencesToCoreData(defaultBudgetPreferences, userId: userViewModel.id) // Save to Core Data
                    }
                } else {
                    // Otherwise, fetch from the server
                    budgetViewModel.fetchBudgetPreferencesFromServer(userId: userViewModel.id)
                }
            } else {
                // If budget preferences exist in Core Data, hydrate state with them
                budgetViewModel.budgetPreferences = budgetPreferences.map { BudgetViewModel.BudgetPreferenceViewModel(from: $0) }
            }
        } catch {
            print("Failed to fetch BudgetPreference: \(error)")
        }
    }
        
    enum Tab {
        case budget
        case balances
        case trends
        case settings
    }
}

#Preview {
    MainTabView()
        .environmentObject(UserViewModel())
        .environmentObject(BudgetViewModel())
        .environmentObject(DateViewModel())
}
