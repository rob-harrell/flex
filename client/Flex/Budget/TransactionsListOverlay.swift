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
            .padding(.vertical)

            ScrollViewReader { scrollView in
                ScrollView {
                    // Filter transactions for the current month and by budgetCategory
                    let currentMonthTransactions = budgetViewModel.transactions.filter { transaction in
                        let calendar = Calendar.current
                        let isCurrentMonth = calendar.isDate(transaction.date, equalTo: date, toGranularity: .month)
                        let isRelevantCategory = transaction.budgetCategory == "Flex" || transaction.budgetCategory == "Fixed" || transaction.budgetCategory == "Income"
                        return isCurrentMonth && isRelevantCategory
                    }

                    // Group transactions by date
                    let groupedTransactions = Dictionary(grouping: currentMonthTransactions) { transaction in
                        Calendar.current.startOfDay(for: transaction.date)
                    }.sorted { $0.key < $1.key }

                    // Display transactions in ascending order
                    ForEach(groupedTransactions, id: \.key) { (date, transactions) in
                        TransactionDateView(date: date, transactions: transactions, selectedFilter: selectedFilter)
                            .id(date)
                    }
                }
                .animation(nil, value: selectedFilter)
                .onAppear {
                    scrollView.scrollTo(date, anchor: .top)
                }
            }
            Spacer()
        }
        .padding()
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
