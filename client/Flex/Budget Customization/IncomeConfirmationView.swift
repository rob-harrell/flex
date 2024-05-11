//
//  IncomeConfirmationView.swift
//  Flex
//
//  Created by Rob Harrell on 4/27/24.
//

import SwiftUI

struct IncomeConfirmationView: View {
    @EnvironmentObject var budgetViewModel: BudgetViewModel
    @EnvironmentObject var sharedViewModel: DateViewModel
    @EnvironmentObject var userViewModel: UserViewModel
    @State private var manualIncomeString: String = ""
    @State private var removedIncomes: [String: Bool] = ["work": false, "accruals": false, "benefits": false, "pension": false]
    @FocusState private var isFocused: Bool
    let nextAction: () -> Void

    var body: some View {
        let incomeSources: [(name: String, income: Double)] = [
            ("work", budgetViewModel.avgRecentWorkIncome),
            ("accruals", budgetViewModel.avgRecentAccrualsIncome),
            ("benefits", budgetViewModel.avgRecentBenefitsIncome),
            ("pension", budgetViewModel.avgRecentPensionIncome)
        ]
        
        VStack (alignment: .leading) {
            Text("First, set your average monthly income")
                .font(.title)
                .fontWeight(.semibold)
                .padding(.bottom, 10)
            
            Text("Your monthly budget will rely on this amount to help you keep track of how much you have left to spend.")
                .font(.callout)
                .foregroundColor(Color.slate500)
                .padding(.bottom, 16)
            
            ZStack (alignment: .leading) {
                Rectangle()
                    .fill(Color.emerald300)
                    .frame(height: 54)
                    .cornerRadius(16)
                
                Text("+ \(formatBudgetNumber(userViewModel.monthlyIncome))")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .padding(.leading, 12)
            }
            .padding(.bottom, 8)
            
            Text("Sources")
                .font(.title)
                .fontWeight(.semibold)
            
            ForEach(incomeSources, id: \.name) { source in
                if source.income > 0 {
                    HStack {
                        Image(.money)
                        VStack (alignment: .leading) {
                            Text(source.name.capitalized)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(Color.slate500)
                            Text("\(formatBudgetNumber(source.income))")
                                .fontWeight(.medium)
                        }
                        Spacer()
                        if removedIncomes[source.name] ?? false {
                            Button(action: {
                                userViewModel.monthlyIncome += source.income
                                removedIncomes[source.name] = false
                            }) {
                                Text("Add")
                                    .font(.caption)
                                    .padding(8)
                                    .background(Color.black)
                                    .foregroundColor(.white)
                                    .cornerRadius(16)
                            }
                        } else {
                            Button(action: {
                                userViewModel.monthlyIncome -= source.income
                                removedIncomes[source.name] = true
                            }) {
                                Text("Remove")
                                    .font(.caption)
                                    .padding(8)
                                    .background(Color.slate100)
                                    .cornerRadius(16)
                            }
                        }
                    }
                }
            }
            
            HStack{
                Image(.money)
                VStack (alignment: .leading, spacing: 0) {
                    Text("Add manual income")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(Color.slate500)
                    HStack (spacing: 0) {
                        Text("$")
                            .foregroundColor(manualIncomeString.isEmpty ? .slate500 : .black)
                        ZStack(alignment: .leading) {
                            if manualIncomeString.isEmpty && !isFocused {
                                Text("0")
                                    .foregroundColor(.slate500)
                            }
                            TextField("", text: $manualIncomeString, onEditingChanged: { editing in
                                self.isFocused = editing
                            })
                            .keyboardType(.decimalPad)
                            .focused($isFocused)
                        }
                    }
                    .fontWeight(.medium)
                }
                if isFocused {
                    Button(action: {
                        if let value = Double(manualIncomeString) {
                            userViewModel.monthlyIncome = budgetViewModel.avgTotalRecentIncome + value
                            print(userViewModel.monthlyIncome)
                            isFocused = false
                        }
                    }) {
                        Text("Done")
                            .font(.caption)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(Color.black)
                            .foregroundColor(.white)
                            .cornerRadius(16)
                    }
                }
            }
            
            Spacer()
            
            Button(action: {
                nextAction()
            }) {
                Text("Next")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .cornerRadius(10)
            }
        }
        .onAppear {
            budgetViewModel.calculateRecentBudgetStats()
            userViewModel.monthlyIncome = budgetViewModel.avgTotalRecentIncome
            print(userViewModel.monthlyIncome)
        }
    }
}

#Preview {
    IncomeConfirmationView(nextAction: {})
        .environmentObject(BudgetViewModel())
}
