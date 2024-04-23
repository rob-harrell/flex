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

    var savings: Double {
        if sharedViewModel.selectedMonth == sharedViewModel.currentMonth {
            return budgetViewModel.currentMonthSavings
        } else {
            return budgetViewModel.monthlySavings[sharedViewModel.selectedMonth] ?? 0
        }
    } 

    var body: some View {
        VStack(alignment: .leading) {
            HStack{
                Text("$\(abs(Int(savings)))")
                    .foregroundColor(savings < 0 ? Color(.red600) : Color(.emerald600))
                Text(savings < 0 ? "over budget" : (sharedViewModel.currentMonth == sharedViewModel.selectedMonth ? "remaining" : "saved"))
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

