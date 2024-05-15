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
        let savings = budgetViewModel.selectedMonthSavings
        
        VStack(alignment: .leading) {
            HStack{
                Text("$\(abs(Int(savings)))")
                    .foregroundColor(savings < 0 ? Color(.red500) : Color(.emerald500))
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

