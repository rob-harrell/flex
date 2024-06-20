//
//  DiscretionaryBar.swift
//  Flex
//
//  Created by Rob Harrell on 6/16/24.
//

import SwiftUI

struct DiscretionaryBar: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @EnvironmentObject var dateViewModel: DateViewModel
    @EnvironmentObject var budgetViewModel: BudgetViewModel
    
    var body: some View {
        let isCurrentMonth = (dateViewModel.selectedMonth == dateViewModel.currentMonth)
        let selectedMonthFixed = budgetViewModel.selectedMonthFixedSpend
        let selectedMonthFlex = budgetViewModel.selectedMonthFlexSpend
        let selectedMonthIncome = budgetViewModel.selectedMonthIncome
        
        let totalBudget = isCurrentMonth ? max(userViewModel.monthlyIncome, userViewModel.monthlyFixedSpend + selectedMonthFlex, selectedMonthFixed + selectedMonthFlex, 1.0) : max(selectedMonthIncome, selectedMonthFixed + selectedMonthFlex, 1.0)
        let overSpend = isCurrentMonth ? selectedMonthFlex - (userViewModel.monthlyIncome - userViewModel.monthlyFixedSpend) : selectedMonthFlex - (selectedMonthIncome - selectedMonthFixed)
        let flexBudget = isCurrentMonth ? max(userViewModel.monthlyIncome - userViewModel.monthlyFixedSpend, 0) : max(selectedMonthIncome - selectedMonthFixed, 0)
        let flexOffsetUnderspent = isCurrentMonth ? max(userViewModel.monthlyFixedSpend/userViewModel.monthlyIncome, selectedMonthFixed/userViewModel.monthlyIncome) : selectedMonthFixed/selectedMonthIncome
        let flexOffsetOverspent = isCurrentMonth ? max(userViewModel.monthlyFixedSpend/totalBudget, selectedMonthFixed/totalBudget) : selectedMonthFixed/totalBudget
        let billsForString = isCurrentMonth ? max(userViewModel.monthlyFixedSpend, selectedMonthFixed) : selectedMonthFixed
        
        GeometryReader { geometry in
            VStack (alignment: .leading) {
                if overSpend < 0 {
                    ZStack(alignment: .leading){
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                            .frame(width: geometry.size.width, height: 54)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.slate200, lineWidth: 1)
                            )
                        UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 0, bottomTrailingRadius: 16, topTrailingRadius: 16)
                            .fill(Color.emerald300)
                            .frame(width: geometry.size.width * CGFloat(flexBudget/totalBudget), height: 54)
                            .overlay(
                                UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 0, bottomTrailingRadius: 16, topTrailingRadius: 16)
                                    .stroke(Color.emerald600, lineWidth: 0.5)
                            )
                            .offset(x: geometry.size.width * CGFloat(flexOffsetUnderspent))
                        Rectangle()
                            .fill(Color.slate100)
                            .frame(width: geometry.size.width * CGFloat(selectedMonthFlex/totalBudget), height: 54)
                            .overlay(
                                ZStack {
                                    Rectangle()
                                        .stroke(Color.slate400, lineWidth: 0.5)
                                    Path { path in
                                        path.move(to: CGPoint(x: 0, y: 0))
                                        path.addLine(to: CGPoint(x: 0, y: 54))
                                    }
                                    .stroke(Color.white, lineWidth: 2)
                                    Path { path in
                                        path.move(to: CGPoint(x: 0, y: 0))
                                        path.addLine(to: CGPoint(x: 0, y: 54))
                                    }
                                    .stroke(Color.slate400, style: StrokeStyle(lineWidth: 1, dash: [2]))
                                }
                            )
                            .offset(x: geometry.size.width * CGFloat(flexOffsetUnderspent))
                    }
                    HStack {
                        Text("\(formatBudgetNumber(billsForString)) bills")
                            .foregroundColor(.slate400)
                        Spacer()
                        Image(.upTrend)
                        Text("\(formatBudgetNumber(flexBudget - selectedMonthFlex))")
                            .foregroundColor(Color.emerald500)
                            .fontWeight(.medium)
                            .padding(.horizontal, -2)
                            .padding(.trailing, -2)
                        Text(isCurrentMonth ? "budget left" : "saved")
                            .fontWeight(.medium)
                    }
                    .font(.system(size: 16))
                    .padding(.top, 2)
                } else if overSpend > 0 {
                    ZStack(alignment: .leading){
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                            .frame(width: geometry.size.width, height: 54)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.slate200, lineWidth: 1)
                            )
                        Rectangle()
                            .fill(Color.red300)
                            .frame(width: geometry.size.width * CGFloat(selectedMonthFlex/totalBudget), height: 54)
                            .overlay(
                                Rectangle()
                                    .stroke(Color.red600, lineWidth: 0.5)
                            )
                            .offset(x: geometry.size.width * CGFloat(flexOffsetOverspent))
                        UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 0, bottomTrailingRadius: 16, topTrailingRadius: 16)
                            .fill(Color.slate100)
                            .frame(width: geometry.size.width * CGFloat(flexBudget/totalBudget), height: 54)
                            .overlay(
                                ZStack {
                                    UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 0, bottomTrailingRadius: 16, topTrailingRadius: 16)
                                        .stroke(Color.slate400, lineWidth: 0.5)
                                    Path { path in
                                        path.move(to: CGPoint(x: 0, y: 0))
                                        path.addLine(to: CGPoint(x: 0, y: 54))
                                    }
                                    .stroke(Color.white, lineWidth: 2)
                                    Path { path in
                                        path.move(to: CGPoint(x: 0, y: 0))
                                        path.addLine(to: CGPoint(x: 0, y: 54))
                                    }
                                    .stroke(Color.slate400, style: StrokeStyle(lineWidth: 1, dash: [2]))
                                }
                            )
                            .offset(x: geometry.size.width * CGFloat(flexOffsetOverspent))
                    }
                    HStack {
                        Text("\(formatBudgetNumber(billsForString)) bills")
                            .foregroundColor(.slate400)
                        Spacer()
                        Image(.negativeUpTrend)
                        Text("\(formatBudgetNumber(selectedMonthFlex - flexBudget))")
                            .foregroundColor(Color.red500)
                            .fontWeight(.medium)
                            .padding(.horizontal, -2)
                            .padding(.trailing, -2)
                        Text("over budget")
                            .fontWeight(.medium)
                    }
                    .font(.system(size: 16))
                    .padding(.top, 2)
                } else {
                    ZStack(alignment: .leading){
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                            .frame(width: geometry.size.width, height: 54)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.slate200, lineWidth: 1)
                            )
                        UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 0, bottomTrailingRadius: 16, topTrailingRadius: 16)
                            .fill(Color.slate100)
                            .frame(width: geometry.size.width * CGFloat(selectedMonthFlex/totalBudget), height: 54)
                            .overlay(
                                ZStack {
                                    UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 0, bottomTrailingRadius: 16, topTrailingRadius: 16)
                                        .stroke(Color.slate400, lineWidth: 0.5)
                                    Path { path in
                                        path.move(to: CGPoint(x: 0, y: 0))
                                        path.addLine(to: CGPoint(x: 0, y: 54))
                                    }
                                    .stroke(Color.white, lineWidth: 2)
                                    Path { path in
                                        path.move(to: CGPoint(x: 0, y: 0))
                                        path.addLine(to: CGPoint(x: 0, y: 54))
                                    }
                                    .stroke(Color.slate400, style: StrokeStyle(lineWidth: 1, dash: [2]))
                                }
                            )
                            .offset(x: geometry.size.width * CGFloat(flexOffsetUnderspent))
                    }
                    HStack {
                        Text("\(formatBudgetNumber(billsForString)) bills")
                            .foregroundColor(.slate400)
                        Spacer()
                        Text("$0")
                            .foregroundColor(Color.black)
                            .fontWeight(.medium)
                            .padding(.horizontal, -2)
                            .padding(.trailing, -2)
                        Text(isCurrentMonth ? "budget left" : "saved")
                            .foregroundColor(Color.slate400)
                            .fontWeight(.medium)
                    }
                    .font(.system(size: 16))
                    .padding(.top, 2)
                }
            }
        }
    }
}

