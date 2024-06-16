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
    @Binding var selectedSpendFilter: SpendFilter
    @State private var animateButton = false
    @State private var showingSpendFilter = false
    var date: Date
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }
    
    var body: some View {
        let dailyFilteredTransactions = budgetViewModel.selectedMonthTransactions.compactMapValues { transactions in
            transactions.filter { transaction in
                switch selectedSpendFilter {
                case .income:
                    return transaction.budgetCategory == "Income"
                case .allSpend:
                    return transaction.budgetCategory == "Flex" || transaction.budgetCategory == "Fixed"
                case .bills:
                    return transaction.budgetCategory == "Fixed"
                case .discretionary:
                    return transaction.budgetCategory == "Flex"
                }
            }
        }.filter { !$0.value.isEmpty }

        let sortedDates = dailyFilteredTransactions.keys.sorted()
        
        ZStack {
            VStack {
                ZStack {
                    Text("Daily transactions")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                    HStack {
                        Spacer()
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "xmark")
                                .font(.title3)
                                .fontWeight(.bold)
                                .padding(.horizontal)
                                .background(Color.white)
                                .foregroundColor(.slate400)
                                .clipShape(Circle())
                        }
                    }
                }
                .padding(.top, 24)
                .padding(.bottom, 8)
                
                ScrollViewReader { scrollView in                  
                    ScrollView {
                        // Display transactions in ascending order
                        ForEach(sortedDates, id: \.self) { date in
                            let transactions = dailyFilteredTransactions[date]!
                            TransactionDateView(date: date, transactions: transactions, selectedSpendFilter: $selectedSpendFilter)
                                .id(date)
                                .padding(.horizontal)
                                .padding(.vertical, 12)
                            
                            // Check if the current date is not the last date
                            if date != sortedDates.last {
                                Rectangle()
                                    .fill(Color.slate100)
                                    .frame(height: 8)
                            }
                        }
                    }
                    .onAppear {
                        scrollView.scrollTo(date, anchor: .top)
                    }
                    .animation(nil, value: selectedSpendFilter)
                    .onChange(of: selectedSpendFilter) {
                        // Scroll to the first date with a fixed expense when the selected filter is "fixed"
                        if selectedSpendFilter == .bills {
                            if let firstFixedExpenseDate = dailyFilteredTransactions.first(where: { $0.value.contains(where: { $0.budgetCategory.lowercased() == "fixed" }) })?.key {
                                scrollView.scrollTo(firstFixedExpenseDate, anchor: .top)
                            }
                        }
                        // Scroll to the selected date when the selected filter is "flex"
                        else if selectedSpendFilter == .discretionary {
                            scrollView.scrollTo(date, anchor: .top)
                        }
                    }
                }
                Spacer()
            }
            VStack {
                Spacer()
                Button(action: {
                    showingSpendFilter.toggle()
                }) {
                    HStack {
                        Image(systemName: "slider.vertical.3")
                            .resizable()
                            .frame(width: 12, height: 12)
                        Text(selectedSpendFilter == .allSpend ? "All Spend" : selectedSpendFilter.rawValue.capitalized)
                            .font(.system(size: 16))
                            .fontWeight(.semibold)
                    }
                    .padding(12)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 30))
                    .overlay(
                        RoundedRectangle(cornerRadius: 30)
                            .stroke(Color(.slate200), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 10)
                }
                .padding(.bottom, 12)
                .opacity(animateButton ? 1 : 0)
                .animation(.easeInOut(duration: 0.4), value: animateButton)
            }
        }
        .onAppear {
            animateButton = true
        }
        .sheet(isPresented: $showingSpendFilter) {
            BudgetFilterView(selectedSpendFilter: $selectedSpendFilter, showingSpendFilter: $showingSpendFilter)
                .presentationDetents([.fraction(0.5), .fraction(1.0)])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(24)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 8)
                .presentationContentInteraction(.scrolls)
        }
    }
}


#Preview {
    TransactionsListOverlay(selectedSpendFilter: .constant(.discretionary), date: Date())
        .environmentObject(BudgetViewModel())
}
