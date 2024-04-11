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

    @State private var selectedFilter: BudgetFilter = .total
        
    var body: some View {
        VStack {
            BudgetHeaderView()
                .padding(.horizontal)
            BudgetBarView(selectedFilter: $selectedFilter)
                .padding(.vertical)
                .padding(.bottom, 16)
            BudgetCalendarView()
        }
    }
}

#Preview {
    BudgetView()
        .environmentObject(UserViewModel())
        .environmentObject(DateViewModel())
        .environmentObject(BudgetViewModel())
}
