//
//  BudgetBarView.swift
//  Flex
//
//  Created by Rob Harrell on 2/13/24.
//

import SwiftUI

struct BudgetBarView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @EnvironmentObject var sharedViewModel: DateViewModel
    @EnvironmentObject var budgetViewModel: BudgetViewModel
    @Binding var selectedSpendFilter: SpendFilter
    //@State var selectedMonth: Date
    
    var body: some View {
        /*
        let totalBudget: Double = isCurrentMonth ? max(userViewModel.monthlyIncome, userViewModel.monthlyFixedSpend + selectedMonthFlex, selectedMonthFixed + selectedMonthFlex, 1.0) : max(selectedMonthIncome, selectedMonthFixed + selectedMonthFlex, 1.0)
        let allSpendOffset: Double = isCurrentMonth ? (userViewModel.monthlyFixedSpend + selectedMonthFlex)/totalBudget : (selectedMonthFixed + selectedMonthFlex)/totalBudget
        let overSpend: Double = isCurrentMonth ? max(0, selectedMonthFlex - (userViewModel.monthlyIncome - userViewModel.monthlyFixedSpend)) : max(0, selectedMonthFlex - (selectedMonthIncome - selectedMonthFixed))
        let percentageIncome: Double = min(selectedMonthIncome / userViewModel.monthlyIncome, 1)
        let percentageFixed: Double = max(selectedMonthFixed / (totalBudget + overSpend), 0.0)
        let percentageFlex: Double = max(selectedMonthFlex / (totalBudget + overSpend), 0.0)
         */

        switch selectedSpendFilter {
        case .income:
            IncomeBar()
        case .allSpend:
            AllSpendBar()
        case .bills:
            BillsBar()
        case .discretionary:
            DiscretionaryBar()
        }
        //.animation(.easeInOut(duration: 0.2), value: selectedMonthFlex)
    }
}

#Preview {
    BudgetBarView(selectedSpendFilter: .constant(.discretionary))
        .environmentObject(UserViewModel())
        .environmentObject(DateViewModel())
        .environmentObject(BudgetViewModel())
}
