//
//  BudgetFilterView.swift
//  Flex
//
//  Created by Rob Harrell on 1/28/24.
//

import SwiftUI

struct BudgetFilterView: View {
    @Binding var selectedFilter: BudgetFilter
    @Namespace private var animation

    var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .center, spacing: 0) {
                ForEach(BudgetFilter.allCases, id: \.self) { filter in
                    Button(action: {
                        withAnimation {
                            selectedFilter = filter
                        }
                    }) {
                        HStack {
                            if filter == .fixed {
                                Image(systemName: "lock.fill")
                                    .padding(.trailing, -4)
                            }
                            Text(filter.rawValue)
                                .font(.subheadline)
                        }
                        .frame(height: 44)
                        .padding(.horizontal, selectedFilter == .fixed ? (filter == .fixed ? 6 : -6) : (filter == .fixed ? 0 : 20))
                        .background(
                            Group {
                                if selectedFilter == filter {
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.white)
                                        .matchedGeometryEffect(id: "background", in: animation)
                                        .frame(height: 36)
                                }
                            }
                        )
                    }
                }
                .frame(width: 212 / CGFloat(BudgetFilter.allCases.count))
            }
        }
        .frame(width: 216, height: 44)
        .background(Color.slate200)
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
