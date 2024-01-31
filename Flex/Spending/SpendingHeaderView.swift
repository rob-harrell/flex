//
//  SpendingHeaderView.swift
//  Flex
//
//  Created by Rob Harrell on 1/28/24.
//

import SwiftUI

struct SpendingHeaderView: View {
    @ObservedObject var viewModel: SpendingViewModel

    var body: some View {
            Text("All Spending")
                .foregroundColor(.gray)
            Text(viewModel.totalSpending)
    }
}

#Preview {
    SpendingHeaderView(viewModel: SpendingViewModel())
}
