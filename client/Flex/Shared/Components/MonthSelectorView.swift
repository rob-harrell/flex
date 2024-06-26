//
//  MonthSelectorView.swift
//  Flex
//
//  Created by Rob Harrell on 2/10/24.
//

import SwiftUI

struct MonthSelectorView: View {
    @EnvironmentObject var dateViewModel: DateViewModel
    @Binding var showingMonthSelection: Bool

    var body: some View {
        VStack {
            Text("Select a month")
                .font(.title2)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 24)
            ScrollViewReader { scrollView in
                ScrollView(.vertical, showsIndicators: false) {
                    ForEach(dateViewModel.allTransactionDates, id: \.self) { dates in
                        monthButton(dates: dates)
                    }
                }
                .onAppear {
                    let month = dateViewModel.stringForDate(dateViewModel.selectedMonth, format: "MMMM")
                    scrollView.scrollTo(month, anchor: .center)
                }
            }
            .presentationDetents([.fraction(0.30), .fraction(0.80)])
            .padding(.bottom, 16)
            .padding(.top, 0)
            .presentationCornerRadius(24)
            Spacer()
        }
    }
    
    @ViewBuilder
    private func monthButton(dates: [Date]) -> some View {
        let month = dateViewModel.stringForDate(dates.first!, format: "MMMM")
        let isSelected = dateViewModel.calendar.isDate(dates.first!, equalTo: dateViewModel.selectedMonth, toGranularity: .month)
        Button(action: {
            dateViewModel.selectedMonth = dates.first!
            showingMonthSelection = false
        }) {
            ZStack(alignment: .trailing) {
                Text(month)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.body)
                    .fontWeight(isSelected ? .bold : .regular)
                    .padding(12)
                    .background(isSelected ? Color(.systemGray6) : Color.clear)
                    .id(month)

                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.black)
                        .fontWeight(.semibold)
                        .padding(12)
                }
            }
        }
    }
}

#Preview {
    MonthSelectorView(showingMonthSelection: .constant(false))
        .environmentObject(DateViewModel())
}
