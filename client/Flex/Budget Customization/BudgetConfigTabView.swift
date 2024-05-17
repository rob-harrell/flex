//
//  BudgetConfigTabView.swift
//  Flex
//
//  Created by Rob Harrell on 5/15/24.
//

import SwiftUI

struct BudgetConfigTabView: View {
    @Binding var selectedTab: BudgetConfigTab

    var body: some View {
        NavigationView {
            VStack {
                Picker("Budget Config", selection: $selectedTab) {
                    Text("Income").tag(BudgetConfigTab.income)
                    Text("Fixed Spend").tag(BudgetConfigTab.fixedSpend)
                    Text("Flex Spend").tag(BudgetConfigTab.flexSpend)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                switch selectedTab {
                case .income:
                    IncomeConfigView()
                case .fixedSpend:
                    FixedSpendConfigView()
                case .flexSpend:
                    FlexSpendConfigView()
                }
            }
            .navigationTitle("Budget Config")
            .padding()
        }
    }
}

enum BudgetConfigTab {
    case income
    case fixedSpend
    case flexSpend
}
