//
//  BudgetHeaderView.swift
//  Flex
//
//  Created by Rob Harrell on 1/28/24.
//

import SwiftUI

struct BudgetHeaderView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @EnvironmentObject var sharedViewModel: DateViewModel
    @EnvironmentObject var budgetViewModel: BudgetViewModel
    @Binding var selectedSpendFilter: SpendFilter

    var body: some View {
        let isPastMonth = (sharedViewModel.selectedMonth != sharedViewModel.currentMonth)
        
        VStack(alignment: .leading) {
            switch selectedSpendFilter {
            case .income:
                HStack {
                    Text(isPastMonth ? "You made" : "You've made")
                    Text("+$\(Int(budgetViewModel.selectedMonthIncome))")
                        .foregroundColor(Color(.emerald500))
                }
                Text("in income")
            case .allSpend:
                HStack{
                    Text(isPastMonth ? "You spent" : "You've spent")
                    Text("$\(abs(Int(budgetViewModel.selectedMonthFixedSpend + budgetViewModel.selectedMonthFlexSpend)))")
                        .foregroundStyle(LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: Color(.navy), location: 0.0),
                                .init(color: Color(.darknavy), location: 0.6),
                                .init(color: Color(.lightblue), location: 0.8),
                                .init(color: Color(.pink), location: 0.9),
                                .init(color: Color(.peach), location: 1.0)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                }
                Text("on all expenses")
            case .bills:
                HStack {
                    Text(isPastMonth ? "You spent" : "You've spent")
                    Text("$\(abs(Int(budgetViewModel.selectedMonthFixedSpend)))")
                                        }
                Text("on bills")
            case .discretionary:
                HStack {
                    Text(isPastMonth ? "You spent" : "You've spent")
                    Text("$\(abs(Int(budgetViewModel.selectedMonthFlexSpend)))")
                }
                Text("on discretionary") 
            }
        }
        .font(.title)
        .fontWeight(.semibold)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    BudgetHeaderView(selectedSpendFilter: .constant(.discretionary))
        .environmentObject(UserViewModel())
        .environmentObject(DateViewModel())
        .environmentObject(BudgetViewModel())
}

