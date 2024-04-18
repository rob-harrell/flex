//
//  BudgetFilterView.swift
//  Flex
//
//  Created by Rob Harrell on 1/28/24.
//

import SwiftUI

struct BudgetFilterView: View {
    @Binding var selectedFilter: BudgetFilter

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            ForEach(BudgetFilter.allCases, id: \.self) { filter in
                ZStack {
                    if selectedFilter == filter {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.black)
                            .frame(height: 36)
                    }
                    Button(action: {
                        withAnimation {
                            selectedFilter = filter
                        }
                    }) {
                        Text(filter.rawValue)
                            .font(.body)
                            .fontWeight(selectedFilter == filter ? .semibold : .regular)
                            .padding(.horizontal, 12) // Adjust horizontal padding
                            .foregroundColor(selectedFilter == filter ? .white : Color.black)
                    }
                }
                .frame(width: 220 / CGFloat(BudgetFilter.allCases.count)) // Set the width of each button
            }
        }
        .frame(width: 220) // Set the width of the entire view
        .background(Color.slate50)
        .cornerRadius(20)
    }
}

enum BudgetFilter: String, CaseIterable {
    case all = "All"
    case fixed = "Fixed"
    case flex = "Flex"
}

struct BudgetFilterView_Previews: PreviewProvider {
    @State static var selectedFilter = BudgetFilter.all
    static var previews: some View {
        BudgetFilterView(selectedFilter: $selectedFilter)
    }
}
