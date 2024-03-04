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
            BudgetFilterView(selectedFilter: $selectedFilter)
                .padding(.horizontal)
                .padding(.bottom, 4)
            BudgetHeaderView(selectedFilter: $selectedFilter)
                .padding(.horizontal)
            BudgetBarView(selectedFilter: $selectedFilter)
                .padding(.top, 24)
                .padding(.bottom, 44)
            BudgetCalendarView()
        }
        .padding(.top, 4)
    }
}

#Preview {
    BudgetView().environmentObject(DateViewModel())
}
