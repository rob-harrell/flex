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
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack{
                Text("\(budgetViewModel.currentMonthSavings < 0 ? "-" : "")$\(abs(Int(budgetViewModel.currentMonthSavings)))")
                    .foregroundColor(budgetViewModel.currentMonthSavings < 0 ? Color(.red600) : Color(.emerald600))
                if sharedViewModel.currentMonth == sharedViewModel.selectedMonth {
                    Text("remaining")
                } else {
                    Text("saved")
                }
            }
            Text("after all spending")
        }
        .font(.largeTitle)
        .fontWeight(.semibold)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    BudgetHeaderView()
        .environmentObject(UserViewModel())
        .environmentObject(DateViewModel())
        .environmentObject(BudgetViewModel())
}

