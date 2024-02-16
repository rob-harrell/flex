//
//  MonthSelectorView.swift
//  Flex
//
//  Created by Rob Harrell on 2/10/24.
//

import SwiftUI

struct MonthSelectorView: View {
    @Binding var showingMonthSelection: Bool
    @ObservedObject var sharedViewModel: SharedViewModel

    var body: some View {
        VStack {
            Text("Select a month")
                .font(.title2)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 24)
            ScrollViewReader { scrollView in
                ScrollView {
                    VStack(alignment: .leading) {
                        ForEach(sharedViewModel.dates, id: \.self) { dates in
                            let month = sharedViewModel.stringForDate(dates.first!, format: "MMMM")
                            Button(action: {
                                if let dateString = sharedViewModel.dates.first(where: { sharedViewModel.stringForDate($0.first!, format: "MMMM") == month }) {
                                    sharedViewModel.selectedMonth = dateString.first!
                                    if let index = sharedViewModel.dates.firstIndex(of: dateString) {
                                        sharedViewModel.selectedMonthIndex = index
                                    }
                                }
                                showingMonthSelection = false
                            }) {
                                ZStack(alignment: .trailing) {
                                    Text(month)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .font(.body)
                                        .fontWeight(sharedViewModel.stringForDate(sharedViewModel.selectedMonth, format: "MMMM") == month ? .bold : .regular)
                                        .padding(12)
                                        .background(sharedViewModel.stringForDate(sharedViewModel.selectedMonth, format: "MMMM") == month ? Color(.systemGray6) : Color.clear)
                                        .id(month)

                                    if sharedViewModel.stringForDate(sharedViewModel.selectedMonth, format: "MMMM") == month {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.black)
                                            .fontWeight(.semibold)
                                            .padding(12)
                                    }
                                }
                            }
                        }
                    }
                    .onAppear {
                        let lastMonth = sharedViewModel.stringForDate(sharedViewModel.dates.last!.first!, format: "MMMM")
                        scrollView.scrollTo(lastMonth, anchor: .bottom)
                    }
                }
            }
            .presentationDetents([.fraction(0.30), .fraction(0.80)])
            .padding(.bottom, 16)
            .padding(.top, 0)
            Spacer()
        }
    }

    func monthSelectionButtons() -> [ActionSheet.Button] {
        sharedViewModel.monthNames.map { month in
            .default(Text(month)) {
                if let dateString = sharedViewModel.dates.first(where: { sharedViewModel.stringForDate($0.first!, format: "MMMM") == month }) {
                    sharedViewModel.selectedMonth = dateString.first!
                }
            }
        } + [.cancel()]
    }
}

#Preview {
    MonthSelectorView(showingMonthSelection: .constant(false), sharedViewModel: SharedViewModel())
}
