//
//  MonthSelectorView.swift
//  Flex
//
//  Created by Rob Harrell on 2/10/24.
//

import SwiftUI

struct MonthSelectorView: View {
    @EnvironmentObject var sharedViewModel: DateViewModel
    @Binding var showingMonthSelection: Bool

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
                        ForEach(Array(sharedViewModel.dates.enumerated()), id: \.element) { index, dates in
                            let month = sharedViewModel.stringForDate(dates.first!, format: "MMMM")
                            Button(action: {
                                sharedViewModel.selectedMonth = dates.first!
                                sharedViewModel.selectedMonthIndex = index
                                showingMonthSelection = false
                            }) {
                                ZStack(alignment: .trailing) {
                                    Text(month)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .font(.body)
                                        .fontWeight(sharedViewModel.selectedMonthIndex == index ? .bold : .regular)
                                        .padding(12)
                                        .background(sharedViewModel.selectedMonthIndex == index ? Color(.systemGray6) : Color.clear)
                                        .id(month)

                                    if sharedViewModel.selectedMonthIndex == index {
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
                        scrollView.scrollTo(sharedViewModel.stringForDate(sharedViewModel.dates.last!.first!, format: "MMMM"), anchor: .bottom)
                    }
                }
            }
            .presentationDetents([.fraction(0.30), .fraction(0.80)])
            .padding(.bottom, 16)
            .padding(.top, 0)
            Spacer()
        }
    }
}

#Preview {
    MonthSelectorView(showingMonthSelection: .constant(false))
        .environmentObject(DateViewModel())
}
