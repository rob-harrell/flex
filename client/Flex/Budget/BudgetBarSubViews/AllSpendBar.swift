//
//  AllSpendBar.swift
//  Flex
//
//  Created by Rob Harrell on 6/16/24.
//

import SwiftUI

struct AllSpendBar: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @EnvironmentObject var sharedViewModel: DateViewModel
    @EnvironmentObject var budgetViewModel: BudgetViewModel
    
    var body: some View {
        let isCurrentMonth = (sharedViewModel.selectedMonth == sharedViewModel.currentMonth)
        let selectedMonthFixed = budgetViewModel.selectedMonthFixedSpend
        let selectedMonthFlex = budgetViewModel.selectedMonthFlexSpend
        let selectedMonthIncome = budgetViewModel.selectedMonthIncome
        
        let overSpend = isCurrentMonth ? selectedMonthFlex - (userViewModel.monthlyIncome - userViewModel.monthlyFixedSpend) : selectedMonthFlex - (selectedMonthIncome - selectedMonthFixed)
        let income = isCurrentMonth ? userViewModel.monthlyIncome : selectedMonthIncome
        let allSpend = isCurrentMonth ? max(userViewModel.monthlyFixedSpend + selectedMonthFlex, selectedMonthFlex + selectedMonthFixed) : selectedMonthFlex + selectedMonthFixed
        
        GeometryReader { geometry in
            VStack (alignment: .leading) {
                if overSpend < 0 {
                    ZStack(alignment: .leading){
                        UnevenRoundedRectangle(topLeadingRadius: 16, bottomLeadingRadius: 16, bottomTrailingRadius: 0, topTrailingRadius: 0)
                            .fill(Color.slate100)
                            .frame(width: geometry.size.width * CGFloat(allSpend/income), height: 54)
                            .overlay(
                                UnevenRoundedRectangle(topLeadingRadius: 16, bottomLeadingRadius: 16, bottomTrailingRadius: 0, topTrailingRadius: 0)
                                    .stroke(Color.slate400, lineWidth: 0.5)
                            )
                        UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 0, bottomTrailingRadius: 16, topTrailingRadius: 16)
                            .fill(Color.emerald300)
                            .frame(width: geometry.size.width * CGFloat((income - allSpend)/income), height: 54)
                            .overlay(
                                UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 0, bottomTrailingRadius: 16, topTrailingRadius: 16)
                                    .stroke(Color.emerald600, lineWidth: 0.5)
                            )
                            .offset(x: geometry.size.width * CGFloat(allSpend/income))
                    }
                    HStack {
                        Spacer()
                        if !isCurrentMonth {
                            Image(.upTrend)
                        }
                        Text("\(formatBudgetNumber(income - allSpend))")
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
                        UnevenRoundedRectangle(topLeadingRadius: 16, bottomLeadingRadius: 16, bottomTrailingRadius: 0, topTrailingRadius: 0)
                            .fill(Color.red300)
                            .frame(width: geometry.size.width, height: 54)
                            .overlay(
                                UnevenRoundedRectangle(topLeadingRadius: 16, bottomLeadingRadius: 16, bottomTrailingRadius: 0, topTrailingRadius: 0)
                                    .stroke(Color.red600, lineWidth: 0.5)
                            )
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.slate100)
                            .frame(width: geometry.size.width * CGFloat((allSpend - income)/allSpend), height: 54)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.slate400, lineWidth: 0.5)
                            )
                    }
                    HStack {
                        Spacer()
                        Image(.negativeUpTrend)
                        Text("\(formatBudgetNumber(allSpend - income))")
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
                    }
                    HStack {
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
