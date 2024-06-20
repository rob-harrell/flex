//
//  IncomeBar.swift
//  Flex
//
//  Created by Rob Harrell on 6/16/24.
//

import SwiftUI

struct IncomeBar: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @EnvironmentObject var dateViewModel: DateViewModel
    @EnvironmentObject var budgetViewModel: BudgetViewModel
    
    var body: some View {
        let isCurrentMonth = (dateViewModel.selectedMonth == dateViewModel.currentMonth)
        let selectedMonthIncome = budgetViewModel.selectedMonthIncome
        
        GeometryReader { geometry in
            VStack (alignment: .leading) {
                //Selected month income has exceeded expected
                if selectedMonthIncome > userViewModel.monthlyIncome {
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.emerald300)
                            .frame(width: geometry.size.width, height: 54)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.emerald500, lineWidth: 0.5)
                            )
                        Rectangle()
                            .fill(Color.emerald100)
                            .frame(width: geometry.size.width * CGFloat(userViewModel.monthlyIncome / selectedMonthIncome), height: 54)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.emerald600, style: StrokeStyle(lineWidth: 1, dash: [2]))
                            )
                    }
                    HStack {
                        Spacer()
                        Image(.upTrend)
                        Text("\(formatBudgetNumber(selectedMonthIncome - userViewModel.monthlyIncome))")
                            .foregroundColor(Color.emerald500)
                            .padding(.horizontal, -2)
                            .padding(.trailing, -2)
                        Text("above expected")
                    }
                    .font(.system(size: 16))
                    .fontWeight(.medium)
                    .padding(.top, 2)
                    //Selected month income is less than expected - state for current month (green) that's different from past months (red)
                } else if selectedMonthIncome < userViewModel.monthlyIncome {
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(isCurrentMonth ? Color.emerald100 : Color.red300)
                            .frame(width: geometry.size.width, height: 54)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(isCurrentMonth ? Color.emerald600 : Color.red600, style: StrokeStyle(lineWidth: 1, dash: [2]))
                            )
                        Rectangle()
                            .fill(isCurrentMonth ? Color.emerald300 : Color.emerald100)
                            .frame(width: geometry.size.width * CGFloat(selectedMonthIncome / userViewModel.monthlyIncome), height: 54)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(isCurrentMonth ? Color.emerald500 : Color.emerald600, lineWidth: 0.5)
                            )
                    }
                    HStack {
                        Spacer()
                        if !isCurrentMonth {
                            Image(.downTrend)
                        }
                        Text("\(formatBudgetNumber(userViewModel.monthlyIncome))")
                            .foregroundColor(isCurrentMonth ? Color.emerald500 : Color.red500)
                            .padding(.horizontal, -2)
                            .padding(.trailing, -2)
                        Text(isCurrentMonth ? "expected" : "below expected")
                    }
                    .font(.system(size: 16))
                    .fontWeight(.medium)
                    .padding(.top, 2)
                    //Selected month income is equal to expected
                } else {
                    Rectangle()
                        .fill(Color.emerald300)
                        .frame(width: geometry.size.width, height: 54)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.emerald500, lineWidth: 0.5)
                        )
                    HStack {
                        Spacer()
                        Text("On track")
                            .foregroundColor(Color.emerald500)
                            .padding(.horizontal, -2)
                            .padding(.trailing, -2)
                        Text("with expected")
                    }
                    .font(.system(size: 16))
                    .fontWeight(.medium)
                    .padding(.top, 2)
                }
            }
        }
    }
}
