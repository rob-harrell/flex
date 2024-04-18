//
//  TransactionDateView.swift
//  Flex
//
//  Created by Rob Harrell on 4/17/24.
//

import SwiftUI

struct TransactionDateView: View {
    var date: Date
    var transactions: [BudgetViewModel.TransactionViewModel]
    var selectedFilter: BudgetFilter
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }

    var body: some View {
        // Filter transactions based on selected filter
        let filteredTransactions = transactions.filter { transaction in
            switch selectedFilter {
            case .all:
                return true
            case .flex:
                return transaction.budgetCategory == "Flex"
            case .fixed:
                return transaction.budgetCategory == "Fixed"
            }
        }

        if !filteredTransactions.isEmpty {
            VStack(alignment: .leading) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(dateFormatter.string(from: date))
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("\(filteredTransactions.count) \(filteredTransactions.count == 1 ? "transaction" : "transactions")")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Text("\(formatBudgetNumber(filteredTransactions.reduce(0) { $0 + $1.amount }))")
                        .font(.title2)
                        .fontWeight(.semibold)
                }

                ForEach(filteredTransactions, id: \.id) { transaction in
                    HStack {
                        AsyncImage(url: URL(string: transaction.logoURL)) { image in
                            image
                                .resizable()
                                .frame(width: 30, height: 30)
                        } placeholder: {
                            Image(systemName: "photo") // Placeholder for the merchant logo
                                .frame(width: 30, height: 30)
                        }
                        Text(transaction.merchantName.isEmpty ? transaction.name : transaction.merchantName)
                            .fontWeight(.medium)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Spacer()
                        HStack {
                            Text(transaction.budgetCategory == "Income" ? "Income" : transaction.productCategory)
                                .font(.caption)
                                .padding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)) // Add padding around the text
                                .background(Color.slate100) // Set the background color
                                .clipShape(RoundedRectangle(cornerRadius: 12)) // Clip the background to a rounded rectangle
                            Text("\(transaction.amount < 0 ? "-" : "")$\(abs(Int(transaction.amount)))")
                            if transaction.budgetCategory == "Fixed" {
                                Image(systemName: "lock.fill")
                                    .padding(.leading, -4)
                            } else if transaction.budgetCategory == "Income" {
                                Image(.budget)
                                    .resizable()
                                    .frame(width: 16, height: 12)
                                    .padding(.leading, -2)
                            }
                        }
                        .font(.subheadline)
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding(.vertical)
        }
    }
}

