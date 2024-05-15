//
//  ConfirmBudgetView.swift
//  Flex
//
//  Created by Rob Harrell on 5/15/24.
//

import SwiftUI

struct ConfirmBudgetView: View {
    @EnvironmentObject var budgetViewModel: BudgetViewModel
    @EnvironmentObject var sharedViewModel: DateViewModel
    @EnvironmentObject var userViewModel: UserViewModel
    
    let doneAction: () -> Void
    let backAction: () -> Void
    
    var body: some View {
        let selectedMonthFlex = budgetViewModel.selectedMonthFlexSpend
        let totalBudget: Double = max(userViewModel.monthlyIncome, userViewModel.monthlyFixedSpend + selectedMonthFlex, 1.0)
        let overSpend: Double = max(0, selectedMonthFlex - (userViewModel.monthlyIncome - userViewModel.monthlyFixedSpend))
        let percentageFixed: Double = max(userViewModel.monthlyFixedSpend / (totalBudget + overSpend), 0.22)
        let percentageFlex: Double = max(selectedMonthFlex / (totalBudget + overSpend), 0.0)
        
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
                Text("This month, you're over")
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
                Text("This means you've spent \(formatBudgetNumber(selectedMonthFlex)) on flexible\nexpenses. Your app experience will mostly set\naside bills so you can focus on this spending.")
                    .font(.system(size: 16))
                    .foregroundColor(Color.slate500)
                    .lineSpacing(4.0)
                    .padding(.bottom, 10)
            } else {
                HStack {
                    Text("This month, you have ")
                        .font(.system(size: 26))
                        .fontWeight(.semibold)
                    Text("\(formatBudgetNumber(userViewModel.monthlyIncome-userViewModel.monthlyFixedSpend-budgetViewModel.selectedMonthFlexSpend))")
                        .font(.system(size: 26))
                        .foregroundColor(Color.emerald500)
                        .padding(.leading, -6)
                        .fontWeight(.semibold)
                    
                }
                Text("Flex budget remaining")
                    .font(.system(size: 26))
                    .fontWeight(.semibold)
                    .padding(.bottom, 10)
                Text("This means you've spent \(formatBudgetNumber(selectedMonthFlex)) in flexible\nexpenses")
                    .font(.system(size: 16))
                    .foregroundColor(Color.slate500)
                    .lineSpacing(4.0)
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
                        
                        HStack (spacing: 0) {
                            UnevenRoundedRectangle(topLeadingRadius: 16, bottomLeadingRadius: 16, bottomTrailingRadius: 0, topTrailingRadius: 0)
                                .stroke(Color.slate200, lineWidth: 2)
                                .background(
                                    UnevenRoundedRectangle(topLeadingRadius: 16, bottomLeadingRadius: 16, bottomTrailingRadius: 0, topTrailingRadius: 0)
                                        .fill(Color.white)
                                )
                                .frame(width: geometry.size.width * CGFloat(percentageFixed), height: 54)
                            ZStack(alignment: .leading) {
                                UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 0, bottomTrailingRadius: 16, topTrailingRadius: 16)
                                    .stroke(Color.clear, lineWidth: 1)
                                    .background(
                                        UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 0, bottomTrailingRadius: 16, topTrailingRadius: 16)
                                            .fill(Color.black)
                                    )
                                    .frame(width: geometry.size.width * CGFloat(percentageFlex), height: 54)
                                Text("\(formatBudgetNumber(selectedMonthFlex))")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                                    .padding(.leading, 10)
                                    .fontWeight(.semibold)
                            }
                        }
                    } else {
                        Rectangle()
                            .fill(Color.emerald200)
                            .frame(width: geometry.size.width, height: 54)
                            .cornerRadius(16)
                        
                        HStack (spacing: 0) {
                            UnevenRoundedRectangle(topLeadingRadius: 16, bottomLeadingRadius: 16, bottomTrailingRadius: 0, topTrailingRadius: 0)
                                .stroke(Color.slate200, lineWidth: 2)
                                .background(
                                    UnevenRoundedRectangle(topLeadingRadius: 16, bottomLeadingRadius: 16, bottomTrailingRadius: 0, topTrailingRadius: 0)
                                        .fill(Color.white)
                                )
                                .frame(width: geometry.size.width * CGFloat(percentageFixed), height: 54)
                            
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.black)
                                    .frame(width: geometry.size.width * CGFloat(percentageFlex), height: 54)
                                
                                Text("\(formatBudgetNumber(selectedMonthFlex))")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                                    .padding(.leading, 10)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                    
                    // Vertical black line to mark the end of the income bar
                    Rectangle()
                        .fill(Color.black)
                        .frame(width: 2, height: 64)
                        .offset(x: overSpend > 0 ? geometry.size.width - 1 : geometry.size.width * (CGFloat(percentageFlex) + CGFloat(percentageFixed)) - 1, y: 0)
                    
                    HStack {
                        Text("\(formatBudgetNumber(userViewModel.monthlyFixedSpend))")
                            .font(.system(size: 16))
                            .foregroundColor(Color.slate400)
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
            .animation(.easeInOut(duration: 0.5), value: selectedMonthFlex)
            
            Spacer()
            
            Button(action: {
                doneAction()
            }) {
                Text("Continue to calendar")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .cornerRadius(12)
            }
        }
    }
}

#Preview {
    ConfirmBudgetView(doneAction: {}, backAction: {})
        .environmentObject(BudgetViewModel())
}
