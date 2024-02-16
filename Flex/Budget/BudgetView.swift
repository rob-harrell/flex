//
//  BudgetView.swift
//  Flex
//
//  Created by Rob Harrell on 1/27/24.
//

import SwiftUI

struct BudgetView: View {
    @ObservedObject var sharedViewModel: SharedViewModel
    @StateObject private var budgetViewModel: BudgetViewModel

    init(sharedViewModel: SharedViewModel) {
        self.sharedViewModel = sharedViewModel
        self._budgetViewModel = StateObject(wrappedValue: BudgetViewModel(sharedViewModel: sharedViewModel))
    }

    @State private var selectedFilter: BudgetFilter = .total
        
    var body: some View {
        VStack {
            BudgetFilterView(selectedFilter: $selectedFilter)
                .padding(.horizontal)
                .padding(.bottom, 4)
            BudgetHeaderView(budgetViewModel: budgetViewModel, sharedViewModel: sharedViewModel, selectedFilter: $selectedFilter)
                .padding(.horizontal)
            BudgetBarView(budgetViewModel: budgetViewModel, sharedViewModel: sharedViewModel, selectedFilter: $selectedFilter)
                .padding(.top, 24)
                .padding(.bottom, 44)
            BudgetCalendarView(budgetViewModel: budgetViewModel, sharedViewModel: sharedViewModel)
        }
        .padding(.top, 4)
    }
}

#Preview {
    BudgetView(sharedViewModel: SharedViewModel())
}
