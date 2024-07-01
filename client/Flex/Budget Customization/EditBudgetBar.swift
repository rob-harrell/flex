//
//  EditBudgetBar.swift
//  Flex
//
//  Created by Rob Harrell on 6/24/24.
//

import SwiftUI

struct EditBudgetBar: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @Binding var selectedView: EditBudgetView.editBudgetSubView
    @Binding var localMonthlySavings: Double
    
    var body: some View {
        let initialSpend = userViewModel.monthlyFixedSpend + localMonthlySavings
        let income = userViewModel.monthlyIncome
        let overBudget = initialSpend - income
        
        GeometryReader { geometry in
            VStack (alignment: .leading) {
                if overBudget < 0 {
                    ZStack(alignment: .leading){
                        UnevenRoundedRectangle(topLeadingRadius: 16, bottomLeadingRadius: 16, bottomTrailingRadius: 0, topTrailingRadius: 0)
                            .fill(Color.white)
                            .frame(width: geometry.size.width * CGFloat(initialSpend/income), height: 48)
                            .overlay(
                                UnevenRoundedRectangle(topLeadingRadius: 16, bottomLeadingRadius: 16, bottomTrailingRadius: 0, topTrailingRadius: 0)
                                    .stroke(Color.slate400, lineWidth: 0.5)
                            )
                        UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 0, bottomTrailingRadius: 16, topTrailingRadius: 16)
                            .fill(Color.emerald300)
                            .frame(width: geometry.size.width * CGFloat((income - initialSpend)/income), height: 48)
                            .overlay(
                                UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 0, bottomTrailingRadius: 16, topTrailingRadius: 16)
                                    .stroke(Color.emerald600, lineWidth: 0.5)
                            )
                            .offset(x: geometry.size.width * CGFloat(initialSpend/income))
                        Path { path in
                            let xOffset = geometry.size.width * CGFloat(initialSpend/income)
                            path.move(to: CGPoint(x: xOffset, y: 0))
                            path.addLine(to: CGPoint(x: xOffset, y: 48))
                        }
                        .stroke(Color.white, lineWidth: 2)
                        Path { path in
                            let xOffset = geometry.size.width * CGFloat(initialSpend/income)
                            path.move(to: CGPoint(x: xOffset, y: 0))
                            path.addLine(to: CGPoint(x: xOffset, y: 48))
                        }
                        .stroke(Color.slate400, style: StrokeStyle(lineWidth: 1, dash: [2]))
                    }
                    HStack {
                        Text("\(formatBudgetNumber(userViewModel.monthlyFixedSpend)) bills")
                            .foregroundColor(.slate400)
                        Spacer()
                        Text("$\(Int(income - initialSpend))")
                            .foregroundColor(Color.emerald500)
                            .fontWeight(.medium)
                            .padding(.horizontal, -2)
                            .padding(.trailing, -2)
                        Text("budget left")
                            .fontWeight(.medium)
                    }
                    .font(.system(size: 16))
                    .padding(.top, 2)
                } else if overBudget > 0 {
                    ZStack(alignment: .leading){
                        UnevenRoundedRectangle(topLeadingRadius: 16, bottomLeadingRadius: 16, bottomTrailingRadius: 0, topTrailingRadius: 0)
                            .fill(Color.red300)
                            .frame(width: geometry.size.width, height: 48)
                            .overlay(
                                UnevenRoundedRectangle(topLeadingRadius: 16, bottomLeadingRadius: 16, bottomTrailingRadius: 0, topTrailingRadius: 0)
                                    .stroke(Color.red600, lineWidth: 0.5)
                            )
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.slate100)
                            .frame(width: geometry.size.width * CGFloat(income/initialSpend), height: 48)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.slate400, lineWidth: 0.5)
                            )
                    }
                    HStack {
                        Spacer()
                        Image(.negativeUpTrend)
                        Text("\(formatBudgetNumber(initialSpend - income))")
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
                            .frame(width: geometry.size.width, height: 48)
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
                        Text("budget left")
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
