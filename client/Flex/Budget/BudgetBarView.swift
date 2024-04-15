//
//  BudgetBarView.swift
//  Flex
//
//  Created by Rob Harrell on 2/13/24.
//

import SwiftUI

struct BudgetBarView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @EnvironmentObject var sharedViewModel: DateViewModel
    @EnvironmentObject var budgetViewModel: BudgetViewModel

    var selectedMonthFixed: Double {
        if sharedViewModel.currentMonth == sharedViewModel.selectedMonth {
            return userViewModel.monthlyFixedSpend
        } else {
            return budgetViewModel.totalFixedSpendPerMonth[sharedViewModel.selectedMonth] ?? 0.0
        }
    }
    
    var selectedMonthFlex: Double {
        if sharedViewModel.currentMonth == sharedViewModel.selectedMonth {
            return budgetViewModel.flexSpendMonthToDate
        } else {
            return budgetViewModel.totalFlexSpendPerMonth[sharedViewModel.selectedMonth] ?? 0.0
        }
    }
    
    var totalBudget: Double {
        return max(userViewModel.monthlyIncome, selectedMonthFixed + selectedMonthFlex)
    }
    
    var percentageFixed: Double {
        let percentage = selectedMonthFixed / totalBudget
        return max(percentage, 0.2)
    }
    
    var percentageFlex: Double {
        return selectedMonthFlex / totalBudget
    }
    
    var percentageOverSpend: Double {
        let overSpend = max(0, selectedMonthFlex - (userViewModel.monthlyIncome - selectedMonthFixed))
        return overSpend / totalBudget
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Total income bar
                if percentageOverSpend > 0 {
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
                            Text("\(formatBudgetNumber(selectedMonthFixed))")
                                .font(.system(size: 16))
                                .foregroundColor(.slate500)
                                .frame(alignment: .center)
                                .padding(.leading, 10)
                                .fontWeight(.semibold)
                            Image(systemName: "lock.fill")
                                .foregroundColor(Color.slate500)
                                .padding(.leading, -4)
                        }
                    }
                    
                    // Flex spend segment
                    if percentageOverSpend > 0 {
                        ZStack(alignment: .leading) {
                            UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 0, bottomTrailingRadius: 16, topTrailingRadius: 16)
                                .fill(Color.black)
                                .frame(width: geometry.size.width * CGFloat(abs(percentageFlex - percentageOverSpend)), height: 54)
                            
                            Text("\(formatBudgetNumber(selectedMonthFlex))")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .padding(.leading, 10)
                                .fontWeight(.semibold)
                        }
                    } else {
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
                    
                    Spacer()
                }
                
                // Vertical black line to mark the end of the income bar
                Rectangle()
                    .fill(Color.black)
                    .frame(width: 2, height: 64)
                    .offset(x: percentageOverSpend > 0 ? geometry.size.width - 1 : geometry.size.width * (CGFloat(percentageFlex) + CGFloat(percentageFixed)) - 1, y: 0)
            }
            .animation(.easeInOut(duration: 0.2), value: selectedMonthFlex)
        }
        .frame(height: 54)
        .padding(.horizontal)
    }
}


#Preview {
    BudgetBarView()
        .environmentObject(UserViewModel())
        .environmentObject(DateViewModel())
        .environmentObject(BudgetViewModel())
}
