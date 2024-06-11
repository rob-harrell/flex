//
//  BudgetView.swift
//  Flex
//
//  Created by Rob Harrell on 1/27/24.
//

import SwiftUI

struct BudgetView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @EnvironmentObject var sharedViewModel: DateViewModel
    @EnvironmentObject var budgetViewModel: BudgetViewModel
    @Binding var selectedBudgetConfigTab: BudgetConfigTab
    @Binding var showingBudgetConfigSheet: Bool
    @State private var showingSpendFilter = false
    @State private var selectedSpendFilter: SpendFilter = .discretionary

    var body: some View {
        VStack {
            BudgetHeaderView(selectedSpendFilter: $selectedSpendFilter)
                .padding(.horizontal)
            BudgetBarView(selectedBudgetConfigTab: $selectedBudgetConfigTab, showingBudgetConfigSheet: $showingBudgetConfigSheet, selectedMonth: sharedViewModel.selectedMonth)
                .padding(.bottom, 30)
                .padding(.top, -4)
            ZStack {
                BudgetCalendarView(selectedSpendFilter: $selectedSpendFilter)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            showingSpendFilter.toggle()
                        }) {
                            HStack {
                                Image(systemName: "slider.vertical.3")
                                    .resizable()
                                    .frame(width: 12, height: 12)
                                Text(selectedSpendFilter == .allSpend ? "All Spend" : selectedSpendFilter.rawValue.capitalized)
                                    .font(.system(size: 16))
                                    .fontWeight(.semibold)
                            }
                            .padding(12)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 30))
                            .overlay(
                                RoundedRectangle(cornerRadius: 30)
                                    .stroke(Color(.slate200), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 10)
                        }
                        Spacer()
                    }
                }
                .padding(.bottom, 12)
            }
        }
        .padding(.top, 20)
        .padding(.bottom, 2)
        .onChange(of: sharedViewModel.selectedMonth) {
            budgetViewModel.calculateSelectedMonthBudgetMetrics(for: sharedViewModel.selectedMonth, monthlyIncome: userViewModel.monthlyIncome, monthlyFixedSpend: userViewModel.monthlyFixedSpend)
        }
        .sheet(isPresented: $showingSpendFilter) {
            BudgetFilterView(selectedSpendFilter: $selectedSpendFilter, showingSpendFilter: $showingSpendFilter)
                .presentationDetents([.fraction(0.5), .fraction(1.0)])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(24)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 8)
                .presentationContentInteraction(.scrolls)
        }
    }
}

enum SpendFilter: String, CaseIterable {
    case income, allSpend, bills, discretionary
}

#Preview {
    BudgetView(selectedBudgetConfigTab: .constant(.income), showingBudgetConfigSheet: .constant(false))
        .environmentObject(UserViewModel())
        .environmentObject(DateViewModel())
        .environmentObject(BudgetViewModel())
}
