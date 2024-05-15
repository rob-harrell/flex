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
        let incomeSources: [(name: String, income: Double, imageName: String)] = [
            ("work", budgetViewModel.avgRecentWorkIncome, "workImage"),
            ("accruals", budgetViewModel.avgRecentAccrualsIncome, "accrualsImage"),
            ("benefits", budgetViewModel.avgRecentBenefitsIncome, "benefitsImage"),
            ("pension", budgetViewModel.avgRecentPensionIncome, "pensionImage")
        ]
        ScrollView {
            VStack (alignment: .leading) {
                Text("First, set your average monthly income")
                    .font(.system(size: 26))
                    .fontWeight(.semibold)
                    .padding(.bottom, 4)
                
                Text("Your monthly budget will rely on this amount to help you keep track of how much you have left to spend.")
                    .font(.system(size: 16))
                    .foregroundColor(Color.slate500)
                    .padding(.bottom, 16)
                    .lineSpacing(4.0)
                
                
                ZStack (alignment: .leading) {
                    Rectangle()
                        .fill(Color.emerald200)
                        .frame(height: 54)
                        .cornerRadius(16)
                    
                    Text("+ \(formatBudgetNumber(userViewModel.monthlyIncome))")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .padding(.leading, 12)
                }
                .padding(.bottom, 16)
                
                Text("Monthly sources")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                ForEach(incomeSources, id: \.name) { source in
                    if source.income > 0 {
                        HStack {
                            Image(source.imageName)
                                .resizable()
                                .frame(width: 64, height: 64)
                            VStack (alignment: .leading) {
                                Text(source.name.capitalized)
                                    .font(.system(size: 14))
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
                                        .font(.system(size: 14))
                                        .fontWeight(.medium)
                                        .padding(8)
                                        .background(Color.slate100)
                                        .cornerRadius(16)
                                }
                            }
                        }
                        .padding(.bottom, 12)
                    }
                }
                
                HStack {
                    Image(.addIncomeButton)
                        .resizable()
                        .frame(width: 64, height: 64)
                    VStack (alignment: .leading, spacing: 0) {
                        Text("Add manual income")
                            .font(.system(size: 14))
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
                                .font(.system(size: 14))
                                .fontWeight(.medium)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 12)
                                .background(Color.black)
                                .foregroundColor(.white)
                                .cornerRadius(16)
                        }
                    }
                }
                
                Divider()
                    .foregroundColor(.slate)
                    .padding(.vertical)
                
                Text("Other sources")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .padding(.bottom, 12)
                
                HStack {
                    Image(.paymentApps)
                        .resizable()
                        .frame(width: 64, height: 64)
                    VStack (alignment: .leading, spacing: 0) {
                        Text("Payment apps will be included")
                            .font(.system(size: 16))
                            .fontWeight(.semibold)
                            .padding(.bottom, 4)
                        Text("Cash-outs will appear in your actual income to offset reimbursements")
                            .font(.system(size: 14))
                            .foregroundColor(Color.slate500)
                            .lineSpacing(4.0)
                    }
                }
                .padding(.bottom, 12)
                
                HStack {
                    Image(.bankPhoto)
                        .resizable()
                        .frame(width: 64, height: 64)
                    VStack (alignment: .leading, spacing: 0) {
                        Text("Bank transfers are excluded")
                            .font(.system(size: 16))
                            .fontWeight(.semibold)
                            .padding(.bottom, 4)
                        Text("Transfers tend to skew income. Add manual income to plan for this.")
                            .font(.system(size: 14))
                            .foregroundColor(Color.slate500)
                            .lineSpacing(4.0)
                        
                    }
                }
            }
        }
        Button(action: {
            nextAction()
        }) {
            Text("Next")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.black)
                .cornerRadius(12)
        }
        .padding(.top)
    }
}

#Preview {
    IncomeConfirmationView(nextAction: {})
        .environmentObject(BudgetViewModel())
}
