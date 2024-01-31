//
//  Spending.swift
//  Flex
//
//  Created by Rob Harrell on 1/27/24.
//

import SwiftUI

struct SpendingView: View {
    @State private var selectedFilter = SpendingFilter.all
    @ObservedObject var viewModel: SpendingViewModel
    
    var body: some View {
        VStack {
            SpendingFilterView(selectedFilter: $selectedFilter)
            SpendingCalendarView(viewModel: viewModel)
        }
        // Add modifiers such as .sheet here for the detail view when a day is selected
    }
}

#Preview {
    SpendingView(viewModel: SpendingViewModel())
}
