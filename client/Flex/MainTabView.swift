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
    @State private var showingBudgetConfigSheet = false
    @State private var selectedBudgetConfigTab: BudgetConfigTab = .income
    
    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                BudgetView(selectedBudgetConfigTab: $selectedBudgetConfigTab, showingBudgetConfigSheet: $showingBudgetConfigSheet)
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
                print("Has completed notification selection: \(userViewModel.hasCompletedNotificationSelection)")
                budgetViewModel.isCalculatingMetrics = true
                budgetViewModel.fetchNewTransactionsFromServer(userId: userViewModel.id) { success in
                    if success {
                        print("hasFetchFullTransactionHistory \(UserDefaults.standard.bool(forKey: "hasFetchedFullTransactionHistory"))")
                        if !UserDefaults.standard.bool(forKey: "hasFetchedFullTransactionHistory") {
                            budgetViewModel.fetchTransactionHistoryFromServer(userId: userViewModel.id, bankAccounts: userViewModel.bankAccounts) { _ in
                                self.updateAndCalculateBudgetMetrics()
                            }
                        } else {
                            self.updateAndCalculateBudgetMetrics()
                        }
                    } else {
                        // Display warning to user that they're disconnected
                        self.updateAndCalculateBudgetMetrics()
                    }
                }
            }
            .onChange(of: userViewModel.bankAccounts) {
                self.updateAndCalculateBudgetMetrics()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack {
                        //Date button
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
                        
                        //Income button
                        Button(action: {
                            //showingBudgetConfigSheet.toggle()
                        }) {
                            HStack{
                                Image("Money")
                                Text("\(sharedViewModel.selectedMonth == sharedViewModel.currentMonth ? formatBudgetNumber(userViewModel.monthlyIncome) : formatBudgetNumber(budgetViewModel.selectedMonthIncome)) \(sharedViewModel.selectedMonth == sharedViewModel.currentMonth ? "est. " : "")income")
                            }
                        }
                        .padding(.horizontal, 4)
                        .background(RoundedRectangle(cornerRadius: 24).stroke(Color.slate200, lineWidth: 1))
                        .sheet(isPresented: $showingBudgetConfigSheet, onDismiss: {
                        }) {
                            BudgetConfigTabView(selectedTab: $selectedBudgetConfigTab)
                        }
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
        .sheet(isPresented: Binding<Bool>(
            get: { !self.userViewModel.hasCompletedNotificationSelection },
            set: { _ in }
        )) {
            VStack {
                switch budgetCustomizationStep {
                case .income:
                    IncomeConfirmationView(nextAction: { budgetCustomizationStep = .connectAccounts })
                case .connectAccounts:
                    AccountConnectionView(nextAction: { budgetCustomizationStep = .fixedSpend }, backAction: {budgetCustomizationStep = .income })
                case .fixedSpend:
                    FixedSpendConfirmationView(nextAction: { budgetCustomizationStep = .confirmBudget }, backAction: { budgetCustomizationStep = .connectAccounts })
                case .confirmBudget:
                    FinalConfirmationView(nextAction: {budgetCustomizationStep = .notifications}, backAction: { budgetCustomizationStep = .fixedSpend }, editIncome: { budgetCustomizationStep = .income})
                case .notifications:
                    NotificationView(doneAction: { userViewModel.hasCompletedNotificationSelection = true}, backAction: { budgetCustomizationStep = .confirmBudget})
                }
                
            }
            .padding(16)
            .padding(.top, 12)
            .interactiveDismissDisabled()
            .presentationDetents([.fraction(0.9)])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(24)
        }
    }
    
    enum Tab {
        case budget
        case balances
        case trends
        case settings
    }
    
    enum BudgetCustomizationStep {
        case income
        case connectAccounts
        case fixedSpend
        case confirmBudget
        case notifications
    }
    
    private func updateAndCalculateBudgetMetrics() {
        DispatchQueue.main.async {
            if UserDefaults.standard.object(forKey: "FirstTransactionDate") == nil {
                print("First transaction date not found in user defaults; checking transactions history to store it")
                sharedViewModel.updateDates()
            }
            budgetViewModel.calculateSelectedMonthBudgetMetrics(for: sharedViewModel.selectedMonth, monthlyIncome: userViewModel.monthlyIncome, monthlyFixedSpend: userViewModel.monthlyFixedSpend)
            budgetViewModel.calculateRecentBudgetStats()
            if !userViewModel.hasCompletedBudgetCustomization {
                userViewModel.monthlyIncome = budgetViewModel.avgTotalRecentIncome
                userViewModel.monthlyFixedSpend = budgetViewModel.avgTotalRecentFixedSpend
            }
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(UserViewModel())
        .environmentObject(BudgetViewModel())
        .environmentObject(DateViewModel())
}
