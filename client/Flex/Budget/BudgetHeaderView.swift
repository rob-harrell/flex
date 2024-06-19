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
    @Binding var selectedSpendFilter: SpendFilter

    var body: some View {
        let isCurrentMonth = (sharedViewModel.selectedMonth == sharedViewModel.currentMonth)
        let allSpend = isCurrentMonth ? max(userViewModel.monthlyFixedSpend + budgetViewModel.selectedMonthFlexSpend, budgetViewModel.selectedMonthFlexSpend + budgetViewModel.selectedMonthFixedSpend) : budgetViewModel.selectedMonthFlexSpend + budgetViewModel.selectedMonthFixedSpend
        let income = isCurrentMonth ? userViewModel.monthlyIncome : budgetViewModel.selectedMonthIncome
        
        
        VStack(alignment: .leading) {
            switch selectedSpendFilter {
            case .income:
                HStack {
                    Text(isCurrentMonth ? "You've made" : "You made")
                    Text("+$\(Int(budgetViewModel.selectedMonthIncome))")
                        .foregroundColor(Color(.emerald500))
                }
                Text("in income")
            case .allSpend:
                HStack{
                    Text(isCurrentMonth ? "On track to spend" : "You spent")
                    Text("$\(abs(Int(budgetViewModel.selectedMonthFixedSpend + budgetViewModel.selectedMonthFlexSpend)))")
                        .foregroundColor(allSpend > income ? Color(.red500) : Color(.black))
                }
                Text("on all expenses")
            case .bills:
                HStack {
                    Text(isCurrentMonth ? "You've spent" : "You spent")
                    Text("$\(abs(Int(budgetViewModel.selectedMonthFixedSpend)))")
                }
                Text("on bills")
            case .discretionary:
                HStack {
                    Text(isCurrentMonth ? "You've spent" : "You spent")
                    Text("$\(abs(Int(budgetViewModel.selectedMonthFlexSpend)))")
                        .foregroundColor(allSpend > income ? Color(.red500) : Color(.black))
                }
                Text("on discretionary") 
            }
        }
        .font(.title)
        .fontWeight(.semibold)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    BudgetHeaderView(selectedSpendFilter: .constant(.discretionary))
        .environmentObject(UserViewModel())
        .environmentObject(DateViewModel())
        .environmentObject(BudgetViewModel())
}

