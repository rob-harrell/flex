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
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack {
                        //Date button
                        Button(action: {
                            showingMonthSelection.toggle()
                        }) {
                            HStack {
                                Image("calendaricon")
                                    .padding(.leading, 4)
                                    .padding(.trailing, -2)
                                Text(sharedViewModel.stringForDate(sharedViewModel.selectedMonth, format: "MMM"))
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(RoundedRectangle(cornerRadius: 24).stroke(Color.slate200, lineWidth: 0.5))
                        .sheet(isPresented: $showingMonthSelection) {
                            MonthSelectorView(showingMonthSelection: $showingMonthSelection)
                                .presentationContentInteraction(.scrolls)
                        }
                        
                        //Income button
                        Button(action: {
                            //showingBudgetConfigSheet.toggle()
                        }) {
                            HStack{
                                Text("Edit Budget")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .padding(.leading, 6)
                                Image("editicon")
                                    .padding(.trailing, -2)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(RoundedRectangle(cornerRadius: 24).stroke(Color.slate200, lineWidth: 0.5))
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
            .onAppear {
                UITabBarItem.appearance().setTitleTextAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12)], for: .normal)
                UITabBarItem.appearance().setTitleTextAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12)], for: .selected)
                budgetViewModel.isCalculatingMetrics = true
                budgetViewModel.fetchNewTransactionsFromServer(userId: userViewModel.id) { success in
                    if success {
                        print("hasFetchedFullTransactionHistory \(UserDefaults.standard.bool(forKey: "hasFetchedFullTransactionHistory"))")
                        if !UserDefaults.standard.bool(forKey: "hasFetchedFullTransactionHistory") {
                            budgetViewModel.fetchTransactionHistoryFromServer(userId: userViewModel.id, bankAccounts: userViewModel.bankAccounts) { _ in
                                print("fetching full transaction history")
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
