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
    
    let nextAction: () -> Void

    var body: some View {
        VStack(alignment: .leading) {
            Text("First, set your average monthly income")
                .font(.title)
                .fontWeight(.semibold)
                .padding(.bottom, 10)

            Text("See if this monthly average looks right, or edit later. Past months will show actual income.")
                .font(.title3)
                .foregroundColor(Color.slate500)
                .padding(.bottom, 20)
            
            ZStack {
                Rectangle()
                    .fill(Color.emerald300)
                    .frame(height: 54)
                    .cornerRadius(16)
                
                Text("+ \(formatBudgetNumber(budgetViewModel.avgTotalRecentIncome))")
                    .font(.system(size: 16))
                    .padding(.leading, 10)
                    .fontWeight(.semibold)
            }
            
            Text("Sources")
                .font(.title)
                .fontWeight(.semibold)
            
            HStack{
                Image(.money)
                VStack {
                    Text("Paycheck")
                        .font(.callout)
                        .foregroundColor(Color.slate500)
                    Text("\(budgetViewModel.avgRecentWorkIncome)")
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
        .padding()
        .onAppear {
            self.budgetViewModel.calculateRecentIncomeStats()
        }
    }
}

#Preview {
    IncomeConfirmationView(nextAction: {})
        .environmentObject(BudgetViewModel())
}
