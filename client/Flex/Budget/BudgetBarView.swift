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
    @Binding var selectedSpendFilter: SpendFilter
    //@State var selectedMonth: Date
    
    var body: some View {
        let isCurrentMonth = (sharedViewModel.selectedMonth == sharedViewModel.currentMonth)
        let selectedMonthFixed = 500.0 //budgetViewModel.selectedMonthFixedSpend
        let selectedMonthFlex = budgetViewModel.selectedMonthFlexSpend
        let selectedMonthIncome = budgetViewModel.selectedMonthIncome
        let fixedBarWidth = isCurrentMonth ? userViewModel.monthlyFixedSpend / userViewModel.monthlyIncome : userViewModel.monthlyFixedSpend / selectedMonthIncome
        let totalBudget: Double = isCurrentMonth ? max(userViewModel.monthlyIncome, userViewModel.monthlyFixedSpend + selectedMonthFlex, selectedMonthFixed + selectedMonthFlex, 1.0) : max(selectedMonthIncome, selectedMonthFixed + selectedMonthFlex, 1.0)
        let allSpendOffset: Double = isCurrentMonth ? (userViewModel.monthlyFixedSpend + selectedMonthFlex)/totalBudget : (selectedMonthFixed + selectedMonthFlex)/totalBudget
        let overSpend: Double = isCurrentMonth ? max(0, selectedMonthFlex - (userViewModel.monthlyIncome - userViewModel.monthlyFixedSpend)) : max(0, selectedMonthFlex - (selectedMonthIncome - selectedMonthFixed))
        let percentageIncome: Double = min(selectedMonthIncome / userViewModel.monthlyIncome, 1)
        let percentageFixed: Double = max(selectedMonthFixed / (totalBudget + overSpend), 0.0)
        let percentageFlex: Double = max(selectedMonthFlex / (totalBudget + overSpend), 0.0)
                
        GeometryReader { geometry in
            VStack(alignment: .leading) {
                switch selectedSpendFilter {
                case .income:
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
                case .allSpend:
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
                            .fill(Color.white)
                            .frame(width: geometry.size.width * CGFloat(allSpendOffset), height: 54)
                                .overlay(
                                    UnevenRoundedRectangle(topLeadingRadius: 16, bottomLeadingRadius: 16, bottomTrailingRadius: 0, topTrailingRadius: 0)
                                        .stroke(Color.darknavy, lineWidth: 1)
                                )
                        UnevenRoundedRectangle(topLeadingRadius: 12, bottomLeadingRadius: 12, bottomTrailingRadius: 0, topTrailingRadius: 0)
                            .foregroundStyle(LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: Color(.navy), location: 0.0),
                                    .init(color: Color(.darknavy), location: 0.6),
                                    .init(color: Color(.lightblue), location: 0.75),
                                    .init(color: Color(.pink), location: 0.9),
                                    .init(color: Color(.peach), location: 1.0)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            .frame(width: geometry.size.width * CGFloat(allSpendOffset) - 8, height: 48)
                            .padding(.leading, 4)
                            .overlay(
                                ZStack {
                                    Path { path in
                                        let xOffset = geometry.size.width * CGFloat(allSpendOffset)
                                        path.move(to: CGPoint(x: xOffset, y: 0))
                                        path.addLine(to: CGPoint(x: xOffset, y: 50))
                                    }
                                    .stroke(Color.white, lineWidth: 2)

                                    Path { path in
                                        let xOffset = geometry.size.width * CGFloat(allSpendOffset)
                                        path.move(to: CGPoint(x: xOffset, y: 0))
                                        path.addLine(to: CGPoint(x: xOffset, y: 50))
                                    }
                                    .stroke(Color.darknavy, style: StrokeStyle(lineWidth: 1, dash: [2]))
                                }
                            )
                    }
                    if isCurrentMonth {
                        HStack {
                            Text("\(formatBudgetNumber(userViewModel.monthlyFixedSpend + selectedMonthFlex)) expected")
                                .font(.system(size: 14))
                                .fontWeight(.medium)
                                .foregroundColor(Color.darknavy)
                            
                            Spacer()
                            Text("\(formatBudgetNumber(userViewModel.monthlyIncome - selectedMonthFlex)) discretionary left")
                                .font(.system(size: 14))
                                .fontWeight(.medium)
                                .foregroundColor(Color.slate400)
                        }
                    }
                case .bills:
                    if selectedMonthFixed > userViewModel.monthlyFixedSpend {
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
                                            path.addLine(to: CGPoint(x: xOffset, y: 50))
                                        }
                                        .stroke(Color.white, lineWidth: 2)
                                        Path { path in
                                            let xOffset = geometry.size.width * CGFloat(fixedBarWidth)
                                            path.move(to: CGPoint(x: xOffset, y: 0))
                                            path.addLine(to: CGPoint(x: xOffset, y: 50))
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
                                .frame(width: geometry.size.width * CGFloat(isCurrentMonth ? (userViewModel.monthlyFixedSpend - selectedMonthFixed) / userViewModel.monthlyIncome : (userViewModel.MonthlyFixedSpend - selectedMonthFixed)/selectedMonthIncome) - 1, height: 54)
                                .overlay(
                                    ZStack {
                                        Rectangle()
                                            .stroke(isCurrentMonth ? Color.slate400 : Color.emerald500, lineWidth: 0.5)
                                        Path { path in
                                            let xOffset = geometry.size.width * CGFloat(fixedBarWidth)
                                            path.move(to: CGPoint(x: xOffset, y: 0))
                                            path.addLine(to: CGPoint(x: xOffset, y: 50))
                                        }
                                        .stroke(Color.white, lineWidth: 2)
                                        Path { path in
                                            let xOffset = geometry.size.width * CGFloat(fixedBarWidth)
                                            path.move(to: CGPoint(x: xOffset, y: 0))
                                            path.addLine(to: CGPoint(x: xOffset, y: 50))
                                        }
                                        .stroke(Color.slate400, style: StrokeStyle(lineWidth: 1, dash: [2]))
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

                    }
                        
                case .discretionary:
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: geometry.size.width, height: 54)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.slate200, lineWidth: 1)
                            )
                        if overSpend > 0 {
                            UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 0)
                            .fill(Color.red300)
                            .frame(width: geometry.size.width * CGFloat(1 - userViewModel.monthlyFixedSpend/userViewModel.monthlyIncome), height: 54)
                            .overlay(
                                UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 0, bottomTrailingRadius: 16, topTrailingRadius: 16)
                                    .stroke(Color.slate400, lineWidth: 0.5)
                            )
                            .offset(x: geometry.size.width * CGFloat(userViewModel.monthlyFixedSpend/userViewModel.monthlyIncome))
                        } else {
                            UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 0, bottomTrailingRadius: 16, topTrailingRadius: 16)
                                .fill(Color.emerald200)
                                .frame(width: geometry.size.width * CGFloat(1 - userViewModel.monthlyFixedSpend/userViewModel.monthlyIncome), height: 54)
                                .overlay(
                                    UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 0, bottomTrailingRadius: 16, topTrailingRadius: 16)
                                        .stroke(Color.slate400, lineWidth: 0.5)
                                )
                                .offset(x: geometry.size.width * CGFloat(userViewModel.monthlyFixedSpend/userViewModel.monthlyIncome))
                        }
                        UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 0)
                            .fill(Color.slate100)
                            .frame(width: geometry.size.width * CGFloat(CGFloat(percentageFlex)), height: 54)
                            .offset(x: geometry.size.width * CGFloat(userViewModel.monthlyFixedSpend/userViewModel.monthlyIncome))
                            .overlay(
                                ZStack {
                                    UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 0)
                                        .stroke(Color.slate400, lineWidth: 0.5)
                                        .offset(x: geometry.size.width * CGFloat(userViewModel.monthlyFixedSpend/userViewModel.monthlyIncome))
                                    Path { path in
                                        let xOffset = geometry.size.width * CGFloat(userViewModel.monthlyFixedSpend/userViewModel.monthlyIncome)
                                        path.move(to: CGPoint(x: xOffset, y: 0))
                                        path.addLine(to: CGPoint(x: xOffset, y: 50))
                                    }
                                    .stroke(Color.white, lineWidth: 2)

                                    Path { path in
                                        let xOffset = geometry.size.width * CGFloat(userViewModel.monthlyFixedSpend/userViewModel.monthlyIncome)
                                        path.move(to: CGPoint(x: xOffset, y: 0))
                                        path.addLine(to: CGPoint(x: xOffset, y: 50))
                                    }
                                    .stroke(Color.slate400, style: StrokeStyle(lineWidth: 1, dash: [2]))
                                }
                            )
                    }
                    if isCurrentMonth {
                        HStack {
                            Spacer()
                            Text("\(formatBudgetNumber(userViewModel.monthlyIncome - userViewModel.monthlyFixedSpend - selectedMonthFlex)) budget left")
                                .font(.system(size: 16))
                                .fontWeight(.medium)
                        }
                    }
                }
            }
            .animation(.easeInOut(duration: 0.2), value: selectedMonthFlex)
        }
        .onReceive(budgetViewModel.objectWillChange) {
            print("monthlyIncome: \(userViewModel.monthlyIncome)")
            print("monthlyFixedSpend: \(userViewModel.monthlyFixedSpend)")
            print("This month's income: \(budgetViewModel.selectedMonthIncome)")
            print("This month's fixed: \(budgetViewModel.selectedMonthFixedSpend)")
            print("This month's flex: \(budgetViewModel.selectedMonthFlexSpend)")
            print("Total budget: \(totalBudget)")
            print("overspend: \(overSpend)")
        }
    }
}

#Preview {
    BudgetBarView(selectedSpendFilter: .constant(.discretionary))
        .environmentObject(UserViewModel())
        .environmentObject(DateViewModel())
        .environmentObject(BudgetViewModel())
}

/*

// Total income bar
                if overSpend > 0 {
                    UnevenRoundedRectangle(topLeadingRadius: 16, bottomLeadingRadius: 16, bottomTrailingRadius: 0, topTrailingRadius: 0)
                        .stroke(Color.clear, lineWidth: 1)
                        .background(
                            UnevenRoundedRectangle(topLeadingRadius: 16, bottomLeadingRadius: 16, bottomTrailingRadius: 0, topTrailingRadius: 0)
                                .fill(Color.red300)
                        )
                        .frame(width: geometry.size.width, height: 54)
                    
                } else {
                    Rectangle()
                        .fill(Color.emerald200)
                        .frame(width: geometry.size.width, height: 54)
                        .cornerRadius(16)
                }
                
                HStack(spacing: 0) {
                    // Fixed spend segment
                    ZStack(alignment: .leading) {
                        Button(action: {
                            selectedBudgetConfigTab = .fixedSpend
                            showingBudgetConfigSheet.toggle()
                        }) {
                            UnevenRoundedRectangle(topLeadingRadius: 16, bottomLeadingRadius: 16, bottomTrailingRadius: 0, topTrailingRadius: 0)
                                .stroke(Color.slate200, lineWidth: 1)
                                .background(
                                    UnevenRoundedRectangle(topLeadingRadius: 16, bottomLeadingRadius: 16, bottomTrailingRadius: 0, topTrailingRadius: 0)
                                        .fill(Color.white)
                                )
                                .frame(width: geometry.size.width * CGFloat(percentageFixed), height: 54)
                        }
                        .sheet(isPresented: $showingBudgetConfigSheet, onDismiss: {
                            self.showingBudgetConfigSheet = false
                        }) {
                            BudgetConfigTabView(selectedTab: $selectedBudgetConfigTab)
                        }
                        
                        HStack {
                            Text("\(formatBudgetNumber(selectedMonthFixed))")
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
                    
                    // Flex spend segment
                    if overSpend > 0 {
                        ZStack(alignment: .leading) {
                            Button(action: {
                                selectedBudgetConfigTab = .flexSpend
                                showingBudgetConfigSheet.toggle()
                            }) {
                                UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 0, bottomTrailingRadius: 16, topTrailingRadius: 16)
                                    .fill(Color.black)
                                    .frame(width: geometry.size.width * CGFloat(percentageFlex), height: 54)
                            }
                            .sheet(isPresented: $showingBudgetConfigSheet, onDismiss: {
                                self.showingBudgetConfigSheet = false
                            }) {
                                BudgetConfigTabView(selectedTab: $selectedBudgetConfigTab)
                            }
                            Text("\(formatBudgetNumber(selectedMonthFlex))")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .padding(.leading, 10)
                                .fontWeight(.semibold)
                        }
                    } else {
                        ZStack(alignment: .leading) {
                            Button(action: {
                                selectedBudgetConfigTab = .fixedSpend
                                showingBudgetConfigSheet.toggle()
                            }) {
                                Rectangle()
                                    .fill(Color.black)
                                    .frame(width: geometry.size.width * CGFloat(percentageFlex), height: 54)
                            }
                            .sheet(isPresented: $showingBudgetConfigSheet, onDismiss: {
                                self.showingBudgetConfigSheet = false
                            }) {
                                BudgetConfigTabView(selectedTab: $selectedBudgetConfigTab)
                            }
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
                    .offset(x: overSpend > 0 ? geometry.size.width - 1 : geometry.size.width * (CGFloat(percentageFlex) + CGFloat(percentageFixed)) - 1, y: 0)

*/
