//
//  BillsBar.swift
//  Flex
//
//  Created by Rob Harrell on 6/16/24.
//

import SwiftUI

struct BillsBar: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @EnvironmentObject var sharedViewModel: DateViewModel
    @EnvironmentObject var budgetViewModel: BudgetViewModel
    
    var body: some View {
        let isCurrentMonth = (sharedViewModel.selectedMonth == sharedViewModel.currentMonth)
        let selectedMonthFixed = budgetViewModel.selectedMonthFixedSpend
        let selectedMonthIncome = budgetViewModel.selectedMonthIncome
        let fixedBarWidth = isCurrentMonth ? userViewModel.monthlyFixedSpend / userViewModel.monthlyIncome : userViewModel.monthlyFixedSpend / selectedMonthIncome
        let underSpend = isCurrentMonth ? (userViewModel.monthlyFixedSpend - selectedMonthFixed) / userViewModel.monthlyIncome : (userViewModel.monthlyFixedSpend - selectedMonthFixed) / selectedMonthIncome
        let billsExceedIncome = isCurrentMonth ? selectedMonthFixed > userViewModel.monthlyIncome : selectedMonthFixed > selectedMonthIncome
        
        GeometryReader { geometry in
            VStack (alignment: .leading) {
                if billsExceedIncome {
                    ZStack (alignment: .leading) {
                        UnevenRoundedRectangle(topLeadingRadius: 16, bottomLeadingRadius: 16, bottomTrailingRadius: 0, topTrailingRadius: 0)
                            .fill(Color.red300)
                            .frame(width: geometry.size.width, height: 54)
                            .overlay(
                                UnevenRoundedRectangle(topLeadingRadius: 16, bottomLeadingRadius: 16, bottomTrailingRadius: 0, topTrailingRadius: 0)
                                    .stroke(Color.red600, lineWidth: 0.5)
                            )
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.slate100)
                            .frame(width: geometry.size.width * CGFloat(isCurrentMonth ? userViewModel.monthlyIncome / selectedMonthFixed : selectedMonthIncome / selectedMonthFixed), height: 54)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.slate400, lineWidth: 0.5)
                            )
                    }
                    HStack {
                        Image(.negativeUpTrend)
                        Text("\(formatBudgetNumber(selectedMonthFixed - userViewModel.monthlyFixedSpend))")
                            .foregroundColor(Color.red500)
                            .padding(.horizontal, -2)
                            .padding(.trailing, -2)
                        Text("over budget")
                        Spacer()
                    }
                    .font(.system(size: 16))
                    .fontWeight(.medium)
                    .padding(.top, 2)
                } else if selectedMonthFixed > userViewModel.monthlyFixedSpend {
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: geometry.size.width, height: 54)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.slate200, lineWidth: 1)
                            )
                        UnevenRoundedRectangle(topLeadingRadius: 16, bottomLeadingRadius: 16, bottomTrailingRadius: 0, topTrailingRadius: 0)
                            .fill(Color.slate100)
                            .frame(width: geometry.size.width * CGFloat(fixedBarWidth), height: 54)
                            .overlay(
                                ZStack {
                                    UnevenRoundedRectangle(topLeadingRadius: 16, bottomLeadingRadius: 16, bottomTrailingRadius: 0, topTrailingRadius: 0)
                                        .stroke(Color.slate400, lineWidth: 0.5)
                                    Path { path in
                                        let xOffset = geometry.size.width * CGFloat(fixedBarWidth)
                                        path.move(to: CGPoint(x: xOffset, y: 0))
                                        path.addLine(to: CGPoint(x: xOffset, y: 54))
                                    }
                                    .stroke(Color.white, lineWidth: 2)
                                    Path { path in
                                        let xOffset = geometry.size.width * CGFloat(fixedBarWidth)
                                        path.move(to: CGPoint(x: xOffset, y: 0))
                                        path.addLine(to: CGPoint(x: xOffset, y: 54))
                                    }
                                    .stroke(Color.slate400, style: StrokeStyle(lineWidth: 1, dash: [2]))
                                }
                            )
                        Rectangle()
                            .fill(Color.red300)
                            .frame(width: geometry.size.width * CGFloat((selectedMonthFixed - userViewModel.monthlyFixedSpend)/userViewModel.monthlyFixedSpend), height: 54)
                            .overlay(
                                Rectangle()
                                    .stroke(Color.red600, lineWidth: 0.5)
                            )
                            .offset(x: geometry.size.width * CGFloat(fixedBarWidth) + 1)
                        
                    }
                    HStack {
                        Image(.negativeUpTrend)
                        Text("\(formatBudgetNumber(selectedMonthFixed - userViewModel.monthlyFixedSpend))")
                            .foregroundColor(Color.red500)
                            .padding(.horizontal, -2)
                            .padding(.trailing, -2)
                        Text("over budget")
                        Spacer()
                    }
                    .font(.system(size: 16))
                    .fontWeight(.medium)
                    .padding(.top, 2)
                } else if selectedMonthFixed < userViewModel.monthlyFixedSpend {
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: geometry.size.width, height: 54)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.slate200, lineWidth: 1)
                            )
                        UnevenRoundedRectangle(topLeadingRadius: 16, bottomLeadingRadius: 16, bottomTrailingRadius: 0, topTrailingRadius: 0)
                            .fill(Color.slate100)
                            .frame(width: geometry.size.width * CGFloat(isCurrentMonth ? selectedMonthFixed / userViewModel.monthlyIncome : selectedMonthFixed / selectedMonthIncome), height: 54)
                            .overlay(
                                UnevenRoundedRectangle(topLeadingRadius: 16, bottomLeadingRadius: 16, bottomTrailingRadius: 0, topTrailingRadius: 0)
                                    .stroke(Color.slate400, lineWidth: 0.5)
                            )
                        Rectangle()
                            .fill(isCurrentMonth ? Color.white : Color.emerald300)
                            .frame(width: geometry.size.width * CGFloat(underSpend), height: 54)
                            .overlay(
                                ZStack {
                                    Rectangle()
                                        .stroke(isCurrentMonth ? Color.slate400 : Color.emerald500, lineWidth: 0.5)
                                    Path { path in
                                        let xOffset = geometry.size.width * CGFloat(underSpend)
                                        path.move(to: CGPoint(x: xOffset, y: 0))
                                        path.addLine(to: CGPoint(x: xOffset, y: 54))
                                    }
                                    .stroke(Color.white, lineWidth: 2)
                                    Path { path in
                                        let xOffset = geometry.size.width * CGFloat(underSpend)
                                        path.move(to: CGPoint(x: xOffset, y: 0))
                                        path.addLine(to: CGPoint(x: xOffset, y: 54))
                                    }
                                    .stroke(isCurrentMonth ? Color.slate400 : Color.emerald500, style: StrokeStyle(lineWidth: 1, dash: [2]))
                                }
                            )
                            .offset(x: geometry.size.width * CGFloat(isCurrentMonth ? selectedMonthFixed / userViewModel.monthlyIncome : selectedMonthFixed / selectedMonthIncome))
                    }
                    HStack {
                        if !isCurrentMonth {
                            Image(.positiveDowntrend)
                        }
                        Text("\(formatBudgetNumber(userViewModel.monthlyFixedSpend - selectedMonthFixed))")
                            .foregroundColor(isCurrentMonth ? Color.black : Color.emerald500)
                            .padding(.horizontal, -2)
                            .padding(.trailing, -2)
                        Text(isCurrentMonth ? "bills remaining" : "under budget")
                        Spacer()
                    }
                    .font(.system(size: 16))
                    .fontWeight(.medium)
                    .padding(.top, 2)
                } else {
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: geometry.size.width, height: 54)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.slate200, lineWidth: 1)
                            )
                        UnevenRoundedRectangle(topLeadingRadius: 16, bottomLeadingRadius: 16, bottomTrailingRadius: 0, topTrailingRadius: 0)
                            .fill(Color.slate100)
                            .frame(width: geometry.size.width * CGFloat(fixedBarWidth), height: 54)
                            .overlay(
                                ZStack {
                                    UnevenRoundedRectangle(topLeadingRadius: 16, bottomLeadingRadius: 16, bottomTrailingRadius: 0, topTrailingRadius: 0)
                                        .stroke(Color.slate400, lineWidth: 0.5)
                                    Path { path in
                                        let xOffset = geometry.size.width * CGFloat(fixedBarWidth)
                                        path.move(to: CGPoint(x: xOffset, y: 0))
                                        path.addLine(to: CGPoint(x: xOffset, y: 54))
                                    }
                                    .stroke(Color.white, lineWidth: 2)
                                    Path { path in
                                        let xOffset = geometry.size.width * CGFloat(fixedBarWidth)
                                        path.move(to: CGPoint(x: xOffset, y: 0))
                                        path.addLine(to: CGPoint(x: xOffset, y: 54))
                                    }
                                    .stroke(Color.slate400, style: StrokeStyle(lineWidth: 1, dash: [2]))
                                }
                            )
                    }
                    HStack {
                        Text("On track")
                            .foregroundColor(Color.black)
                            .padding(.horizontal, -2)
                            .padding(.trailing, -2)
                        Text("with budget")
                            .foregroundColor(Color.slate400)
                        Spacer()
                    }
                    .font(.system(size: 16))
                    .fontWeight(.medium)
                    .padding(.top, 2)
                }
            }
        }
    }
}
