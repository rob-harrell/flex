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
        
    var body: some View {
        VStack {
            BudgetHeaderView()
                .padding(.horizontal)
            BudgetBarView()
                .padding(.bottom, 30)
                .padding(.top, -4)
            BudgetCalendarView()
        }
        .padding(.top, 20)
    }
}

#Preview {
    BudgetView()
        .environmentObject(UserViewModel())
        .environmentObject(DateViewModel())
        .environmentObject(BudgetViewModel())
}
