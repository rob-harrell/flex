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
            
            let discretionaryAmount = transactions.filter { $0.budgetCategory == "Flex" }.reduce(0){ $0 + $1.amount }
            let billsAmount = transactions.filter {$0.budgetCategory == "Fixed"}.reduce(0){ $0 + $1.amount }
            
            VStack(alignment: .leading) {
                HStack {
                    Text(dateFormatter.string(from: date))
                        .font(.system(size: 17))
                        .fontWeight(.semibold)
                    Spacer()
                    VStack (alignment: .trailing) {
                        Text(discretionaryAmount < 0 ? "+$\(Int(round(abs(discretionaryAmount))))" : "$\(Int(round(discretionaryAmount)))")
                            .foregroundColor(discretionaryAmount < 0 ? Color.emerald600 : Color.black)
                            .font(.system(size: 17))
                            .fontWeight(.semibold)
                            .padding(.bottom, 0.5)
                        if billsAmount > 0 {
                            Text("and $\(Int(billsAmount)) bills")
                                .font(.system(size: 12))
                                .foregroundColor(.slate500)
                        }
                    }
                }

                ForEach(transactions, id: \.id) { transaction in
                    HStack {
                        AsyncImage(url: URL(string: transaction.logoURL)) { image in
                            image
                                .resizable()
                                .frame(width: 36, height: 36)
                                .clipShape(Circle())
                        } placeholder: {
                            Image(systemName: "photo")
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
                                .foregroundColor(transaction.budgetCategory == "Fixed" ? Color.slate500 : Color.black)
                                .padding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)) // Add padding around the text
                                .background(transaction.budgetCategory == "Income" ? Color.emerald200 : Color.slate100) // Set the background color
                                .clipShape(RoundedRectangle(cornerRadius: 12)) // Clip the background to a rounded rectangle
                            Text("\(transaction.budgetCategory == "Income" ? "+" : transaction.amount < 0 ? "+" : "")$\(abs(Int(transaction.amount)))")
                                .foregroundColor(transaction.budgetCategory == "Fixed" ? Color.slate500 : transaction.budgetCategory == "Income" ? Color.emerald600 : Color.black)
                                
                        }
                        .font(.subheadline)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
}

