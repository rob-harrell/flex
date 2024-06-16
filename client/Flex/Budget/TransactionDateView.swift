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
    @Binding var selectedSpendFilter: SpendFilter
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, MMM d"
        return formatter
    }

    var body: some View {
        if !transactions.isEmpty {
            VStack(alignment: .leading) {
                HStack {
                    Text(dateFormatter.string(from: date))
                        .font(.title3)
                        .fontWeight(.semibold)
                    Spacer()
                    let totalAmount = transactions.reduce(0) { $0 + $1.amount }
                    Text(totalAmount < 0 ? "+$\(Int(round(abs(totalAmount))))" : "$\(Int(round(totalAmount)))")
                        .foregroundColor(totalAmount < 0 ? Color.emerald600 : Color.black)
                        .font(.title3)
                        .fontWeight(.semibold)
                }

                ForEach(transactions, id: \.id) { transaction in
                    HStack {
                        AsyncImage(url: URL(string: transaction.logoURL)) { image in
                            image
                                .resizable()
                                .frame(width: 36, height: 36)
                                .clipShape(Circle())
                        } placeholder: {
                            Image(systemName: "photo") // Placeholder for the merchant logo
                                .frame(width: 36, height: 36)
                                .clipShape(Circle())
                        }
                        Text(transaction.merchantName.isEmpty ? transaction.name : transaction.merchantName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .foregroundColor(transaction.budgetCategory == "Fixed" ? Color.slate400 : Color.black)
                        Spacer()
                        HStack {
                            Text(transaction.budgetCategory == "Income" ? "Income" : transaction.productCategory)
                                .font(.caption)
                                .foregroundColor(transaction.budgetCategory == "Fixed" ? Color.slate400 : Color.black)
                                .padding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)) // Add padding around the text
                                .background(transaction.budgetCategory == "Income" ? Color.emerald200 : Color.slate100) // Set the background color
                                .clipShape(RoundedRectangle(cornerRadius: 12)) // Clip the background to a rounded rectangle
                            if transaction.budgetCategory == "Fixed" {
                                Image(.lock)
                                    .padding(.trailing, -4)
                                    .foregroundColor(.slate400)
                            }
                            Text("\(transaction.budgetCategory == "Income" ? "+" : transaction.amount < 0 ? "+" : "")$\(abs(Int(transaction.amount)))")
                                .foregroundColor(transaction.budgetCategory == "Fixed" ? Color.slate400 : transaction.budgetCategory == "Income" ? Color.emerald600 : Color.black)
                                
                        }
                        .font(.subheadline)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
}

