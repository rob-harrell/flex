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
        HStack(alignment: .center) {
            ForEach(BudgetFilter.allCases, id: \.self) { filter in
                Button(action: {
                    withAnimation {
                        selectedFilter = filter
                    }
                }) {
                    HStack {
                        Spacer()
                        if filter != .total {
                            Image(filter.iconName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 14, height: 14)
                            }
                        Text(filter.rawValue)
                            .font(.body)
                            .fontWeight(.medium)
                        Spacer()
                    }
                    .fixedSize(horizontal: true, vertical: false)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 6)
                    .background(selectedFilter == filter ? Color.black : Color.clear)
                    .foregroundColor(selectedFilter == filter ? .white : Color.black.opacity(0.7))
                    .cornerRadius(20)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

enum BudgetFilter: String, CaseIterable {
    case total = "Total"
    case fixed = "Fixed"
    case flex = "Flex"
    
    var iconName: String {
        switch self {
        case .total: return ""
        case .fixed: return "Lock" // Change this line
        case .flex: return "Tiki" // Change this line
        }
    }
}

struct BudgetFilterView_Previews: PreviewProvider {
    @State static var selectedFilter = BudgetFilter.total
    static var previews: some View {
        BudgetFilterView(selectedFilter: $selectedFilter)
    }
}
