//
//  BudgetView.swift
//  Flex
//
//  Created by Rob Harrell on 1/27/24.
//

import SwiftUI

struct BudgetView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @EnvironmentObject var sharedViewModel: DateViewModel
    @EnvironmentObject var budgetViewModel: BudgetViewModel
    @Binding var selectedBudgetConfigTab: BudgetConfigTab
    @Binding var showingBudgetConfigSheet: Bool

        
    var body: some View {
        VStack {
            if budgetViewModel.isCalculatingMetrics {
                ProgressView()
            }
            BudgetHeaderView()
                .padding(.horizontal)
            BudgetBarView(selectedBudgetConfigTab: $selectedBudgetConfigTab, showingBudgetConfigSheet: $showingBudgetConfigSheet, selectedMonth: sharedViewModel.selectedMonth)
                .padding(.bottom, 30)
                .padding(.top, -4)
            BudgetCalendarView()
        }
        .padding(.top, 20)
        .padding(.bottom, 2)
        .onChange(of: sharedViewModel.selectedMonth) {
            budgetViewModel.calculateSelectedMonthBudgetMetrics(for: sharedViewModel.selectedMonth, monthlyIncome: userViewModel.monthlyIncome, monthlyFixedSpend: userViewModel.monthlyFixedSpend)
        }
        .id(sharedViewModel.dates)
    }
}

#Preview {
    BudgetView(selectedBudgetConfigTab: .constant(.income), showingBudgetConfigSheet: .constant(false))
        .environmentObject(UserViewModel())
        .environmentObject(DateViewModel())
        .environmentObject(BudgetViewModel())
}
