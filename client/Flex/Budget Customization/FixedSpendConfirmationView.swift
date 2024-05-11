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
    @State private var removedFixedExpenses: [String: Bool] = ["work": false, "accruals": false, "benefits": false, "pension": false]

    let nextAction: () -> Void
    
    var body: some View {
        let totalBudget: Double = max(userViewModel.monthlyIncome, budgetViewModel.avgTotalRecentFixedSpend, 1.0)
        let overSpend: Double = max(0, userViewModel.monthlyIncome - budgetViewModel.avgTotalRecentFixedSpend)
        let percentageFixed: Double = max(budgetViewModel.avgTotalRecentFixedSpend / (totalBudget + overSpend), 0.2)
        
        let fixedSpendSources: [(name: String, amount: Double)] = [
            ("Housing", budgetViewModel.recentHousingCosts),
            ("Insurance", budgetViewModel.recentInsuranceCosts),
            ("Student Loans", budgetViewModel.recentStudentLoans),
            ("Other Loans", budgetViewModel.recentOtherLoans),
            ("Gas & Electrical", budgetViewModel.recentGasAndElectrical),
            ("Internet & Cable", budgetViewModel.recentInternetAndCable),
            ("Sewage & Waste", budgetViewModel.recentSewageAndWaste),
            ("Phone Bill", budgetViewModel.recentPhoneBill),
            ("Water Bill", budgetViewModel.recentWaterBill),
            ("Other Utilities", budgetViewModel.recentOtherUtilities),
            ("Storage Fees", budgetViewModel.recentStorageCosts),
            ("Nursing Costs", budgetViewModel.recentNursingCosts)
        ]
        
        VStack (alignment: .leading) {
            Text("Next, set a fixed budget for monthly essentials")
                .font(.title)
                .fontWeight(.semibold)
                .padding(.bottom, 10)
            
            Text("Your fixed budget should include your recurring bills. Any remaining income after your fixed budget will be considered your 'flex' budget.")
                .font(.callout)
                .foregroundColor(Color.slate500)
                .padding(.bottom, 16)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Total income bar
                    if overSpend > 0 {
                        UnevenRoundedRectangle(topLeadingRadius: 16, bottomLeadingRadius: 16, bottomTrailingRadius: 0, topTrailingRadius: 0)
                            .stroke(Color.black, lineWidth: 1)
                            .background(
                                UnevenRoundedRectangle(topLeadingRadius: 16, bottomLeadingRadius: 16, bottomTrailingRadius: 0, topTrailingRadius: 0)
                                    .fill(Color.red400)
                            )
                            .frame(width: geometry.size.width, height: 54)
                        
                    } else {
                        Rectangle()
                            .fill(Color.emerald300)
                            .frame(width: geometry.size.width, height: 54)
                            .cornerRadius(16)
                    }
                    
                    HStack(spacing: 0) {
                        // Fixed spend segment
                        ZStack(alignment: .leading) {
                            UnevenRoundedRectangle(topLeadingRadius: 16, bottomLeadingRadius: 16, bottomTrailingRadius: 0, topTrailingRadius: 0)
                                .stroke(Color.slate200, lineWidth: 1)
                                .background(
                                    UnevenRoundedRectangle(topLeadingRadius: 16, bottomLeadingRadius: 16, bottomTrailingRadius: 0, topTrailingRadius: 0)
                                        .fill(Color.white)
                                )
                                .frame(width: geometry.size.width * CGFloat(percentageFixed), height: 54)
                            
                            HStack {
                                Text("\(formatBudgetNumber(budgetViewModel.avgTotalRecentFixedSpend))")
                                    .font(.system(size: 16))
                                    .foregroundColor(.slate500)
                                    .frame(alignment: .center)
                                    .padding(.leading, 10)
                                    .fontWeight(.semibold)
                                    .minimumScaleFactor(0.9)
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 15))
                                    .foregroundColor(Color.slate500)
                                    .padding(.leading, -7)
                            }
                        }
                    }
                }
            }
            .frame(height: 54)
            .padding(.bottom, 8)
            
            Text("Sources")
                .font(.title)
                .fontWeight(.semibold)
            
            ForEach(fixedSpendSources, id: \.name) { source in
                if source.amount > 0 {
                    HStack {
                        Image(.money)
                        VStack (alignment: .leading) {
                            Text(source.name.capitalized)
                                .font(.caption)
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
                                Text("Add")
                                    .font(.caption)
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
                                    .font(.caption)
                                    .padding(8)
                                    .background(Color.slate100)
                                    .cornerRadius(16)
                            }
                        }
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
            userViewModel.monthlyFixedSpend = budgetViewModel.avgTotalRecentFixedSpend
            print(userViewModel.monthlyFixedSpend)
        }
    }
}

#Preview {
    FixedSpendConfirmationView(nextAction: {})
        .environmentObject(BudgetViewModel())
}
