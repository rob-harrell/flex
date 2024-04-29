//
//  TransactionsListOverlay.swift
//  Flex
//
//  Created by Rob Harrell on 4/15/24.
//

import SwiftUI

struct TransactionsListOverlay: View {
    @EnvironmentObject var budgetViewModel: BudgetViewModel
    @Environment(\.presentationMode) var presentationMode
    @State var selectedFilter: BudgetFilter = .all
    var date: Date
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }
    
    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    //show search overlay
                }) {
                    Image(.search)
                        .resizable()
                        .frame(width: 32, height: 32)
                }
                Spacer()
                BudgetFilterView(selectedFilter: $selectedFilter)
                Spacer()
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.slate500)
                }
            }
            .padding(.horizontal)
            .padding(.top, 24)
            .padding(.bottom, 8)
            
            ScrollViewReader { scrollView in
                // Filter transactions for the current month and by budgetCategory
                let currentMonthTransactions = budgetViewModel.selectedMonthTransactions.filter { transaction in
                    let calendar = Calendar.current
                    let isCurrentMonth = calendar.isDate(transaction.date, equalTo: date, toGranularity: .month)
                    let isRelevantCategory = transaction.budgetCategory == "Flex" || transaction.budgetCategory == "Fixed" || transaction.budgetCategory == "Income"
                    return isCurrentMonth && isRelevantCategory
                }
                
                // Further filter transactions based on the selected filter
                let filteredTransactions = currentMonthTransactions.filter { transaction in
                    selectedFilter == .all || transaction.budgetCategory.lowercased() == selectedFilter.rawValue.lowercased()
                }
                
                // Group transactions by date
                let groupedTransactions = Dictionary(grouping: filteredTransactions) { transaction in
                    Calendar.current.startOfDay(for: transaction.date)
                }.sorted { $0.key < $1.key }

                ScrollView {
                    // Display transactions in ascending order
                    ForEach(groupedTransactions.indices, id: \.self) { index in
                        let (date, transactions) = groupedTransactions[index]
                        TransactionDateView(date: date, transactions: transactions, selectedFilter: selectedFilter)
                            .id(date)
                            .padding(.horizontal)
                            .padding(.vertical, 12)
                        
                        // Check if the current date is not the last date
                        if index != groupedTransactions.count - 1 {
                            Rectangle()
                                .fill(Color.slate100)
                                .frame(height: 8)
                        }
                    }
                }
                .onAppear {
                    scrollView.scrollTo(date, anchor: .top)
                }
                .animation(nil, value: selectedFilter)
                .onChange(of: selectedFilter) {
                    // Scroll to the first date with a fixed expense when the selected filter is "fixed"
                    if selectedFilter == .fixed {
                        if let firstFixedExpenseDate = groupedTransactions.first(where: { $0.value.contains(where: { $0.budgetCategory.lowercased() == "fixed" }) })?.key {
                            scrollView.scrollTo(firstFixedExpenseDate, anchor: .top)
                        }
                    }
                    // Scroll to the selected date when the selected filter is "flex"
                    else if selectedFilter == .flex {
                        scrollView.scrollTo(date, anchor: .top)
                    }
                }
            }
            Spacer()
        }
    }
}


struct TransactionsListOverlay_Previews: PreviewProvider {
    static var previews: some View {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        let date = dateFormatter.date(from: "04/15/2024")!

        return TransactionsListOverlay(date: date)
            .environmentObject(BudgetViewModel())
    }
}
