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
    @EnvironmentObject var dateViewModel: DateViewModel
    @EnvironmentObject var budgetViewModel: BudgetViewModel
    @State private var selectedTab: Tab = .budget
    @State private var showingMonthSelection = false
    @State private var budgetCustomizationStep: BudgetCustomizationStep = .start
    @State private var showingEditBudgetSheet = false
    
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
                                Text(dateViewModel.stringForDate(dateViewModel.selectedMonth, format: "MMM"))
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
                        
                        Button(action: {
                            showingEditBudgetSheet.toggle()
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
                        .sheet(isPresented: $showingEditBudgetSheet, onDismiss: {
                        }) {
                            EditBudgetView(showingEditBudgetSheet: $showingEditBudgetSheet)
                                .padding(16)
                                .presentationDetents([.fraction(0.8)])
                                .presentationDragIndicator(.visible)
                                .presentationCornerRadius(24)
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
                if(userViewModel.hasCompletedBudgetCustomization) {
                    budgetViewModel.isCalculatingMetrics = true
                    budgetViewModel.fetchNewTransactionsFromServer(userId: userViewModel.id) { success in
                        if success {
                            print("hasFetchedFullTransactionHistory \(UserDefaults.standard.bool(forKey: "hasFetchedFullTransactionHistory"))")
                            if !UserDefaults.standard.bool(forKey: "hasFetchedFullTransactionHistory") {
                                budgetViewModel.fetchTransactionHistoryFromServer(userId: userViewModel.id, bankAccounts: userViewModel.bankAccounts) { _ in
                                    print("fetching full transaction history")
                                    budgetViewModel.calculateSelectedMonthBudgetMetrics(for: dateViewModel.selectedMonth, monthlyIncome: userViewModel.monthlyIncome, monthlyFixedSpend: userViewModel.monthlyFixedSpend)
                                }
                            } else {
                                budgetViewModel.calculateSelectedMonthBudgetMetrics(for: dateViewModel.selectedMonth, monthlyIncome: userViewModel.monthlyIncome, monthlyFixedSpend: userViewModel.monthlyFixedSpend)
                            }
                        } else {
                            // Display warning to user that they're disconnected
                            budgetViewModel.calculateSelectedMonthBudgetMetrics(for: dateViewModel.selectedMonth, monthlyIncome: userViewModel.monthlyIncome, monthlyFixedSpend: userViewModel.monthlyFixedSpend)
                        }
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
                case .start:
                    BudgetCustomizationStart(nextAction: {budgetCustomizationStep = .income})
                case .income:
                    EditIncomeView(nextAction: { budgetCustomizationStep = .connectAccounts }, backAction: {budgetCustomizationStep = .start})
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
        case start
        case income
        case connectAccounts
        case fixedSpend
        case confirmBudget
        case notifications
    }
}

#Preview {
    MainTabView()
        .environmentObject(UserViewModel())
        .environmentObject(BudgetViewModel())
        .environmentObject(DateViewModel())
}
