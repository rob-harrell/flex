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
    @Binding var selectedFilter: BudgetFilter
    
    private var percentageSpent: Double {
        if sharedViewModel.currentMonth == sharedViewModel.selectedMonth {
            return budgetViewModel.expensesMonthToDate / budgetViewModel.monthlyIncome
        } else {
            return (budgetViewModel.totalExpensesPerMonth[sharedViewModel.selectedMonth] ?? 0.0) / budgetViewModel.monthlyIncome
        }
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Background for income
            Rectangle()
                .fill(Color(.emerald300)) // Light background color
                .frame(maxWidth: .infinity, maxHeight: 56)
                .cornerRadius(16)

            // Foreground for expenses
            Rectangle()
                .fill(Color.black) // Foreground color representing the spend
                .frame(width: UIScreen.main.bounds.width * CGFloat(percentageSpent), height: 56)
                .cornerRadius(16)
                .animation(.linear, value: budgetViewModel.expensesMonthToDate)

            // Text overlay
            VStack(alignment: .leading) {
                Text("$\(Int(sharedViewModel.currentMonth == sharedViewModel.selectedMonth ? budgetViewModel.expensesMonthToDate : budgetViewModel.totalExpensesPerMonth[sharedViewModel.selectedMonth] ?? 0.0))")
                    .font(.body)
                    .fontWeight(.semibold)
                Text(sharedViewModel.currentMonth == sharedViewModel.selectedMonth ? "Est. total spend" : "Total Spend")
                    .font(.caption2)
            }
            .foregroundColor(.white)
            .padding(.leading, 8)
        }
        .frame(height: 24)
        .padding(.horizontal)
    }
}

#Preview {
    BudgetBarView(selectedFilter: .constant(.total))
}
