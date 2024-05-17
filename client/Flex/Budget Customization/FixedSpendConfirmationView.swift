//
//  FixedSpendConfirmationView.swift
//  Flex
//
//  Created by Rob Harrell on 4/27/24.
//

import SwiftUI

struct FixedSpendConfirmationView: View {
    @EnvironmentObject var budgetViewModel: BudgetViewModel
    @EnvironmentObject var sharedViewModel: DateViewModel
    @EnvironmentObject var userViewModel: UserViewModel
    @State private var removedFixedExpenses: [String: Bool] = [
        "Housing": false,
        "Insurance": false,
        "Student Loans": false,
        "Other Loans": false,
        "Gas & Electrical": false,
        "Internet & Cable": false,
        "Sewage & Waste": false,
        "Phone Bill": false,
        "Water Bill": false,
        "Oterh Utilities": false,
        "Storage Fees": false,
        "Nursing Costs": false
    ]
    @State private var manualFixedString: String = ""
    @FocusState private var isFocused: Bool

    let nextAction: () -> Void
    let backAction: () -> Void
    
    var body: some View {
        let totalBudget: Double = max(userViewModel.monthlyIncome, userViewModel.monthlyFixedSpend, 1.0)
        let overSpend: Double = max(0, userViewModel.monthlyFixedSpend - userViewModel.monthlyIncome)
        let percentageFixed: Double = max(userViewModel.monthlyFixedSpend / (totalBudget + overSpend), 0.22)
        let fixedSpendSources: [(name: String, amount: Double, imageName: String)] = [
            ("Housing", budgetViewModel.recentHousingCosts, "Housing"),
            ("Insurance", budgetViewModel.recentInsuranceCosts, "Housing"),
            ("Student Loans", budgetViewModel.recentStudentLoans, "Housing"),
            ("Other Loans", budgetViewModel.recentOtherLoans, "Housing"),
            ("Gas & Electrical", budgetViewModel.recentGasAndElectrical, "Housing"),
            ("Internet & Cable", budgetViewModel.recentInternetAndCable, "Housing"),
            ("Sewage & Waste", budgetViewModel.recentSewageAndWaste, "Housing"),
            ("Phone Bill", budgetViewModel.recentPhoneBill, "Housing"),
            ("Water Bill", budgetViewModel.recentWaterBill, "Housing"),
            ("Other Utilities", budgetViewModel.recentOtherUtilities, "Housing"),
            ("Storage Fees", budgetViewModel.recentStorageCosts, "Housing"),
            ("Nursing Costs", budgetViewModel.recentNursingCosts, "Housing")
        ]

        ScrollView {
            VStack (alignment: .leading) {
                Button(action: {
                    self.backAction()
                }) {
                    Image(systemName: "chevron.left")
                        .resizable()
                        .frame(width: 12, height: 21)
                        .fontWeight(.semibold)
                }
                .padding(.vertical, 4)
                .padding(.bottom, 4)
                
                Text("Next, set a fixed budget for monthly essentials")
                    .font(.system(size: 26))
                    .fontWeight(.semibold)
                    .padding(.bottom, 10)
                
                Text("Your fixed budget should include your recurring bills. Any remaining income after your fixed budget will be considered your 'flex' budget.")
                    .font(.system(size: 16))
                    .foregroundColor(Color.slate500)
                    .padding(.bottom, 16)
                    .lineSpacing(4.0)
                
                //Fixed budget bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Total income bar
                        if overSpend > 0 {
                            UnevenRoundedRectangle(topLeadingRadius: 16, bottomLeadingRadius: 16, bottomTrailingRadius: 0, topTrailingRadius: 0)
                                .stroke(Color.clear, lineWidth: 1)
                                .background(
                                    UnevenRoundedRectangle(topLeadingRadius: 16, bottomLeadingRadius: 16, bottomTrailingRadius: 0, topTrailingRadius: 0)
                                        .fill(Color.red300)
                                )
                                .frame(width: geometry.size.width, height: 54)
                            
                            UnevenRoundedRectangle(topLeadingRadius: 16, bottomLeadingRadius: 16, bottomTrailingRadius: 16, topTrailingRadius: 16)
                                .stroke(Color.clear, lineWidth: 1)
                                .background(
                                    UnevenRoundedRectangle(topLeadingRadius: 16, bottomLeadingRadius: 16, bottomTrailingRadius: 16, topTrailingRadius: 16)
                                        .fill(Color.black)
                                )
                                .frame(width: geometry.size.width * CGFloat(percentageFixed), height: 54)
                            
                        } else {
                            Rectangle()
                                .fill(Color.emerald200)
                                .frame(width: geometry.size.width, height: 54)
                                .cornerRadius(16)
                            
                            UnevenRoundedRectangle(topLeadingRadius: 16, bottomLeadingRadius: 16, bottomTrailingRadius: 0, topTrailingRadius: 0)
                                .stroke(Color.clear, lineWidth: 1)
                                .background(
                                    UnevenRoundedRectangle(topLeadingRadius: 16, bottomLeadingRadius: 16, bottomTrailingRadius: 0, topTrailingRadius: 0)
                                        .fill(Color.black)
                                )
                                .frame(width: geometry.size.width * CGFloat(percentageFixed), height: 54)
                        }
                            
                        
                        
                        
                        // Vertical black line to mark the end of the income bar
                        Rectangle()
                            .fill(Color.black)
                            .frame(width: 2, height: 64)
                            .offset(x: overSpend > 0 ? geometry.size.width - 2 : geometry.size.width * CGFloat(percentageFixed) - 2, y: 0)
                        
                        HStack {
                            Text("\(formatBudgetNumber(userViewModel.monthlyFixedSpend))")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .frame(alignment: .center)
                                .padding(.leading, 10)
                                .fontWeight(.semibold)
                                .minimumScaleFactor(0.9)
                            Image(.lock)
                                .font(.system(size: 15))
                                .foregroundColor(Color.slate200)
                                .padding(.leading, -6)
                        }
                    }
                }
                .frame(height: 54)
                .padding(.bottom, 20)
                .animation(.easeInOut(duration: 0.2), value: percentageFixed)
                
                //Warning
                if overSpend > 0 {
                    HStack {
                        Image(.overspendWarning)
                        VStack (alignment: .leading) {
                            Text("Does this look right?")
                                .fontWeight(.medium)
                                .padding(.bottom, 2)
                            Text("Your spending exceeds your monthly")
                                .font(.system(size: 14))
                                .foregroundColor(Color.slate500)
                                .lineSpacing(2.0)
                            HStack {
                                Text("average income by \(formatBudgetNumber(overSpend)).")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color.slate500)
                                    .lineSpacing(2.0)
                                Button(action: {
                                    backAction()
                                }) {
                                    Text("Edit income")
                                        .font(.system(size: 14))
                                        .lineSpacing(2.0)
                                        .underline()
                                        .padding(.leading, -4)
                                }
                            }
                        }
                        Spacer()
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16.0)
                            .stroke(Color.slate200, lineWidth: 1)
                    )
                    .padding(.bottom, 12)
                }
                
                Text("Sources")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                ForEach(fixedSpendSources, id: \.name) { source in
                    if source.amount > 0 {
                        HStack {
                            Image(source.imageName)
                                .resizable()
                                .frame(width: 64, height: 64)
                            VStack (alignment: .leading) {
                                Text(source.name.capitalized)
                                    .font(.system(size: 14))
                                    .fontWeight(.medium)
                                    .foregroundColor(Color.slate500)
                                Text("\(formatBudgetNumber(source.amount))")
                                    .fontWeight(.medium)
                            }
                            Spacer()
                            if removedFixedExpenses[source.name] ?? false {
                                Button(action: {
                                    userViewModel.monthlyFixedSpend += source.amount
                                    removedFixedExpenses[source.name] = false
                                }) {
                                    Text("+ Add")
                                        .font(.system(size: 14))
                                        .fontWeight(.medium)
                                        .padding(8)
                                        .background(Color.black)
                                        .foregroundColor(.white)
                                        .cornerRadius(16)
                                }
                            } else {
                                Button(action: {
                                    userViewModel.monthlyFixedSpend -= source.amount
                                    removedFixedExpenses[source.name] = true
                                }) {
                                    Text("Remove")
                                        .font(.system(size: 14))
                                        .fontWeight(.medium)
                                        .padding(8)
                                        .background(Color.slate100)
                                        .cornerRadius(16)
                                }
                            }
                        }.padding(.bottom, 12)
                    }
                }
                
                HStack {
                    Image(.addFixedButton)
                        .resizable()
                        .frame(width: 64, height: 64)
                    VStack (alignment: .leading, spacing: 0) {
                        Text("Add a manual expense")
                            .font(.system(size: 14))
                            .fontWeight(.medium)
                            .foregroundColor(Color.slate500)
                        HStack (spacing: 0) {
                            Text("$")
                                .foregroundColor(manualFixedString.isEmpty ? .slate500 : .black)
                            ZStack(alignment: .leading) {
                                if manualFixedString.isEmpty && !isFocused {
                                    Text("0")
                                        .foregroundColor(.slate500)
                                }
                                TextField("", text: $manualFixedString, onEditingChanged: { editing in
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
                            if let value = Double(manualFixedString), value > 0 {
                                userViewModel.monthlyFixedSpend = budgetViewModel.avgTotalRecentFixedSpend + value
                                print(userViewModel.monthlyIncome)
                                isFocused = false
                            } else {
                                // Handle invalid manual expense
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
                        .disabled(!(Double(manualFixedString) != nil && Double(manualFixedString)! > 0))
                    }
                }
                
                Divider()
                    .foregroundColor(.slate)
                    .padding(.vertical)
                
                Text("Other Sources")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .padding(.bottom, 12)
                                
                HStack {
                    Image(.taxes)
                        .resizable()
                        .frame(width: 64, height: 64)
                    VStack (alignment: .leading, spacing: 0) {
                        Text("Tax payments & fees are included")
                            .font(.system(size: 16))
                            .fontWeight(.semibold)
                            .padding(.bottom, 4)
                        Text("Add a manual expense to plan ahead for\ntax refunds and other government fees.")
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
    FixedSpendConfirmationView(nextAction: {}, backAction: {})
        .environmentObject(BudgetViewModel())
}
