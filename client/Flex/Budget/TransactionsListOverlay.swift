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
    var date: Date
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }

    var body: some View {
        VStack {
            HStack {
                Text(dateFormatter.string(from: date))
                    .font(.title)
                    .fontWeight(.semibold)
                Spacer()
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.title)
                        .fontWeight(.semibold)
                }
            }
            .padding(.vertical)

            ScrollView {
                ForEach(["Flex", "Fixed"], id: \.self) { category in
                    let transactions = budgetViewModel.transactions.filter { $0.budgetCategory == category && Calendar.current.isDate($0.date, inSameDayAs: date) }
                    let totalAmount = transactions.reduce(0) { $0 + $1.amount }

                    if !transactions.isEmpty {
                        HStack{
                            Text(category)
                                .font(.title2)
                                .fontWeight(.semibold)
                            Spacer()
                            Text("\(formatBudgetNumber(totalAmount))")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        HStack{
                            Text("\(transactions.count) \(transactions.count == 1 ? "expense" : "expenses")")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Spacer()
                        }

                        ForEach(transactions, id: \.id) { transaction in
                            HStack {
                                AsyncImage(url: URL(string: transaction.logoURL)) { image in
                                    image
                                        .resizable()
                                        .frame(width: 40, height: 40)
                                } placeholder: {
                                    Image(systemName: "photo") // Placeholder for the merchant logo
                                        .frame(width: 40, height: 40)
                                }
                                VStack(alignment: .leading) {
                                    Text(transaction.merchantName.isEmpty ? transaction.name : transaction.merchantName)
                                        .font(.headline)
                                        .fontWeight(.medium)
                                    Text(transaction.productCategory)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                Text("$\(Int(transaction.amount))")
                                    .font(.subheadline)
                            }
                            .padding(.vertical, 4)
                        }
                        if category == "Flex" {
                            Spacer().frame(height: 20) // Add 20 points of space after the "Flex" category
                        }
                    }
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
