//
//  SpendingFilterView.swift
//  Flex
//
//  Created by Rob Harrell on 1/28/24.
//

import SwiftUI

struct SpendingFilterView: View {
    @Binding var selectedFilter: SpendingFilter

    var body: some View {
        HStack {
            ForEach(SpendingFilter.allCases, id: \.self) { filter in
                Button(filter.rawValue) {
                    selectedFilter = filter
                }
                .padding()
                .background(selectedFilter == filter ? Color.blue : Color.clear)
                .foregroundColor(selectedFilter == filter ? .white : .black)
                .cornerRadius(10)
            }
        }
        .padding(.horizontal)
    }
}

enum SpendingFilter: String, CaseIterable {
    case all = "All"
    case flex = "Flex"
    case fixed = "Fixed"
}

struct SpendingFilterView_Previews: PreviewProvider {
    @State static var selectedFilter = SpendingFilter.all
    static var previews: some View {
        SpendingFilterView(selectedFilter: $selectedFilter)
    }
}
