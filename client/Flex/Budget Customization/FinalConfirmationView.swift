//
//  FinalConfirmationView.swift
//  Flex
//
//  Created by Rob Harrell on 4/27/24.
//

import SwiftUI

struct FinalConfirmationView: View {
    @EnvironmentObject var budgetViewModel: BudgetViewModel
    @EnvironmentObject var sharedViewModel: DateViewModel
    @EnvironmentObject var userViewModel: UserViewModel
    
    let nextAction: () -> Void
    let doneAction: () -> Void
    let backAction: () -> Void
    let editIncome: () -> Void
    
    var body: some View {
        let totalBudget: Double = max(userViewModel.monthlyIncome, userViewModel.monthlyFixedSpend, 1.0)
        let overSpend: Double = max(0, userViewModel.monthlyFixedSpend - userViewModel.monthlyIncome)
        let percentageFixed: Double = max(userViewModel.monthlyFixedSpend / (totalBudget + overSpend), 0.22)
        
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
            
            if overSpend > 0 {
                Text("You'll start each month over")
                    .font(.system(size: 26))
                    .fontWeight(.semibold)
                HStack {
                    Text("budget by")
                        .font(.system(size: 26))
                        .fontWeight(.semibold)
                    Text("\(formatBudgetNumber(overSpend))")
                        .font(.system(size: 26))
                        .fontWeight(.semibold)
                        .foregroundColor(Color.red500)
                }
                .padding(.bottom, 10)
                HStack {
                    Text("This is where you start given your ")
                        .font(.system(size: 16))
                        .foregroundColor(Color.slate500)
                    Text("+\(formatBudgetNumber(userViewModel.monthlyIncome))")
                        .font(.system(size: 16))
                        .fontWeight(.medium)
                        .foregroundColor(Color.emerald500)
                        .padding(.leading, -7)
                }
                .padding(.bottom, -2)
                HStack {
                    Text("income after")
                        .font(.system(size: 16))
                        .foregroundColor(Color.slate500)
                    Text("\(formatBudgetNumber(userViewModel.monthlyFixedSpend))")
                        .font(.system(size: 16))
                        .fontWeight(.medium)
                        .padding(.leading, -4)
                    Image(.lock)
                        .resizable()
                        .frame(width: 10, height: 12)
                        .padding(.leading, -6)
                        .padding(.trailing, -2)
                    Text("in Fixed expenses. Your")
                        .font(.system(size: 16))
                        .foregroundColor(Color.slate500)
                        
                }
                .padding(.bottom, -2)
                Text("flexible spending will increase this overage.")
                    .font(.system(size: 16))
                    .foregroundColor(Color.slate500)
                    .padding(.bottom, 10)
            } else {
                Text("You'll start each month with")
                    .font(.system(size: 26))
                    .fontWeight(.semibold)
                HStack {
                    Text("a Flex budget of")
                        .font(.system(size: 26))
                        .fontWeight(.semibold)
                    Text("\(formatBudgetNumber(userViewModel.monthlyIncome-userViewModel.monthlyFixedSpend))")
                        .font(.system(size: 26))
                        .foregroundColor(Color.emerald500)
                        .fontWeight(.semibold)
                }
                .padding(.bottom, 10)
                HStack {
                    Text("This is what's remaining of your ")
                        .font(.system(size: 16))
                        .foregroundColor(Color.slate500)
                    Text("+\(formatBudgetNumber(userViewModel.monthlyIncome))")
                        .font(.system(size: 16))
                        .foregroundColor(.emerald500)
                        .fontWeight(.semibold)
                        .padding(.leading, -7)
                }
                .padding(.bottom, -2)
                HStack {
                    Text("income after")
                        .font(.system(size: 16))
                        .foregroundColor(Color.slate500)
                    Text("\(formatBudgetNumber(userViewModel.monthlyFixedSpend))")
                        .font(.system(size: 16))
                        .fontWeight(.medium)
                        .padding(.leading, -4)
                    Image(.lock)
                        .resizable()
                        .frame(width: 10, height: 12)
                        .padding(.leading, -6)
                        .padding(.trailing, -2)
                    Text(" in Fixed expenses.")
                        .font(.system(size: 16))
                        .foregroundColor(Color.slate500)
                }
                .padding(.bottom, 10)
            }
            
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
                            .stroke(Color.slate200, lineWidth: 2)
                            .background(
                                UnevenRoundedRectangle(topLeadingRadius: 16, bottomLeadingRadius: 16, bottomTrailingRadius: 0, topTrailingRadius: 0)
                                    .fill(Color.white)
                            )
                            .frame(width: geometry.size.width * CGFloat(percentageFixed), height: 54)
                    }
                    
                    // Vertical black line to mark the end of the income bar
                    Rectangle()
                        .fill(Color.black)
                        .frame(width: 2, height: 64)
                        .offset(x: overSpend > 0 ? geometry.size.width - 2 : geometry.size.width * CGFloat(percentageFixed) - 1, y: 0)
                    
                    HStack {
                        Text("\(formatBudgetNumber(userViewModel.monthlyFixedSpend))")
                            .font(.system(size: 16))
                            .foregroundColor(overSpend > 0 ? Color.white : Color.slate400)
                            .frame(alignment: .center)
                            .padding(.leading, 10)
                            .fontWeight(.semibold)
                            .minimumScaleFactor(0.9)
                        Image(.lock)
                            .font(.system(size: 15))
                            .foregroundColor(Color.slate400)
                            .padding(.leading, -6)
                    }
                }
            }
            .frame(height: 54)
            .padding(.bottom, 20)
            
            Spacer()
            
            if overSpend > 0 {
                Button(action: {
                    editIncome()
                }) {
                    Text("Edit income")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .cornerRadius(12)
                }
                Button(action: {
                    doneAction()
                    userViewModel.updateUserOnServer()
                }) {
                    Text("Continue to calendar")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.slate200)
                        .cornerRadius(12)
                }
            }
            else {
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
        }
    }
}

#Preview {
    FinalConfirmationView(nextAction: {}, doneAction: {}, backAction: {}, editIncome: {})
        .environmentObject(BudgetViewModel())
}
