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
                budgetViewModel.fetchTransactionsFromServer(userId: userViewModel.id)
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
                                Text(formatBudgetNumber(budgetViewModel.monthlyIncome))
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
    
    func formatBudgetNumber(_ n: Double) -> String {
        let absN = abs(n)
        let suffix: String

        switch absN {
        case 1_000_000...:
            suffix = "m"
        case 1_000...:
            suffix = "k"
        default:
            return String(format: "$%.0f", round(n / 10) * 10)
        }

        let number = n / pow(10, (suffix == "m") ? 6 : 3)
        let formattedNumber = String(format: "%.1f", number)
        let finalNumber = formattedNumber.hasSuffix(".0") ? String(formattedNumber.dropLast(2)) : formattedNumber

        return "$\(finalNumber)\(suffix)"
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
