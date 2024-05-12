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
    @State private var budgetCustomizationStep: BudgetCustomizationStep = .income
    
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
                UITabBarItem.appearance().setTitleTextAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12)], for: .normal)
                UITabBarItem.appearance().setTitleTextAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12)], for: .selected)
                budgetViewModel.fetchTransactionHistoryFromServer(userId: userViewModel.id, bankAccounts: userViewModel.bankAccounts, monthlyIncome: userViewModel.monthlyIncome, monthlyFixedSpend: userViewModel.monthlyFixedSpend)
                budgetViewModel.fetchNewTransactionsFromServer(userId: userViewModel.id, monthlyIncome: userViewModel.monthlyIncome, monthlyFixedSpend: userViewModel.monthlyFixedSpend)
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    DispatchQueue.main.async {
                        if !sharedViewModel.isFirstTransactionDateAvailable {
                            print("using transactions history to load dates array")
                            sharedViewModel.updateDates()
                        }
                        budgetViewModel.calculateSelectedMonthBudgetMetrics(for: sharedViewModel.selectedMonth, monthlyIncome: userViewModel.monthlyIncome, monthlyFixedSpend: userViewModel.monthlyFixedSpend)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack {
                        Button(action: {
                            showingMonthSelection.toggle()
                        }) {
                            HStack {
                                Image("Calendar")
                                Text(sharedViewModel.stringForDate(sharedViewModel.selectedMonth, format: "MMM"))
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
                                Text("\(formatBudgetNumber(budgetViewModel.selectedMonthIncome)) \(sharedViewModel.selectedMonth == sharedViewModel.currentMonth ? "est. " : "")income")
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
    
    enum Tab {
        case budget
        case balances
        case trends
        case settings
    }
    
    enum BudgetCustomizationStep {
        case income
        case fixedSpend
        case final
    }
}

#Preview {
    MainTabView()
        .environmentObject(UserViewModel())
        .environmentObject(BudgetViewModel())
        .environmentObject(DateViewModel())
}
