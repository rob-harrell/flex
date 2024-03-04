//
//  BudgetHeaderView.swift
//  Flex
//
//  Created by Rob Harrell on 1/28/24.
//

import SwiftUI

struct BudgetHeaderView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @EnvironmentObject var sharedViewModel: DateViewModel
    @EnvironmentObject var budgetViewModel: BudgetViewModel
    @Binding var selectedFilter: BudgetFilter
        
    var body: some View {
        VStack(alignment: .leading) {
            switch selectedFilter {
            case .total:
                if sharedViewModel.currentMonth == sharedViewModel.selectedMonth {
                    Text("On track to save")
                    Text("$\(Int(budgetViewModel.currentMonthSavings))")
                        .foregroundColor(Color(.emerald600))
                    Text("of estimated income ").foregroundColor(Color(.darkGray)).font(.body)
                        .fontWeight(.light) + Text("$\(Int(budgetViewModel.monthlyIncome))").fontWeight(.semibold).foregroundColor(.black)
                        .font(.body)
                } else {
                    Text("You saved")
                    Text("$\(Int(budgetViewModel.monthlySavings[sharedViewModel.selectedMonth] ?? 0.0))")
                        .foregroundColor(Color(.emerald600))
                    Text("of income ").foregroundColor(Color(.darkGray)).font(.body)
                        .fontWeight(.light) + Text("$\(Int(budgetViewModel.monthlyIncome))").fontWeight(.semibold).foregroundColor(.black)
                        .font(.body)
                }
            case .fixed:
                if sharedViewModel.currentMonth == sharedViewModel.selectedMonth {
                    Text("On track to spend")
                    Text("$\(budgetViewModel.expensesMonthToDate)")
                } else {
                    Text("You spent")
                    Text("$\(Int(budgetViewModel.expensesMonthToDate))")
                }
            case .flex:
                if sharedViewModel.currentMonth == sharedViewModel.selectedMonth {
                    Text("You've spent")
                    Text("$\(Int(budgetViewModel.expensesMonthToDate))")
                } else {
                    Text("You spent")
                    Text("$\(Int(budgetViewModel.expensesMonthToDate))")
                }
            }
        }
        .font(.largeTitle)
        .fontWeight(.semibold)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    BudgetHeaderView(selectedFilter: .constant(.total))
}
