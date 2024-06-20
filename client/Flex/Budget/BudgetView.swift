//
//  BudgetView.swift
//  Flex
//
//  Created by Rob Harrell on 1/27/24.
//

import SwiftUI

struct BudgetView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @EnvironmentObject var dateViewModel: DateViewModel
    @EnvironmentObject var budgetViewModel: BudgetViewModel
    @Binding var selectedBudgetConfigTab: BudgetConfigTab
    @Binding var showingBudgetConfigSheet: Bool
    @State private var showingSpendFilter = false
    @State private var selectedSpendFilter: SpendFilter = .discretionary
    @State private var isDragging = false
    @State private var dragOffset: CGSize = .zero

    var body: some View {
        VStack {
            BudgetHeaderView(selectedSpendFilter: $selectedSpendFilter)
                .padding(.horizontal)
            BudgetBarView(selectedSpendFilter: $selectedSpendFilter)
                .padding(.bottom, 30)
                .padding(.top, -4)
                .padding(.horizontal)
            ZStack {
                BudgetCalendarView(selectedSpendFilter: $selectedSpendFilter)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            showingSpendFilter.toggle()
                        }) {
                            if isDragging {
                                HStack {
                                    ForEach(SpendFilter.allCases.indices, id: \.self) { index in
                                        Circle()
                                            .frame(width: 6, height: 6)
                                            .foregroundColor(index == calculateHighlightedDotIndex() ? .black : .gray)
                                    }
                                }
                                .padding(12)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 30))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 30)
                                        .stroke(Color(.slate200), lineWidth: 0.5)
                                )
                                .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 10)
                            } else {
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
                                        .stroke(Color(.slate200), lineWidth: 0.5)
                                )
                                .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 10)
                            }
                        }
                        Spacer()
                    }
                    .padding(.bottom, 12)
                }
            }
            .gesture(
                DragGesture(minimumDistance: 10)
                    .onChanged { value in
                        isDragging = true
                        dragOffset = value.translation
                    }
                    .onEnded { value in
                        let newIndex = calculateHighlightedDotIndex()
                        isDragging = false
                        dragOffset = .zero
                        if newIndex >= 0 && newIndex < SpendFilter.allCases.count {
                            selectedSpendFilter = SpendFilter.allCases[newIndex]
                            print("Drag ended. New selectedSpendFilter: \(selectedSpendFilter)")
                        }
                    }
            )
        }
        .padding(.top, 20)
        .padding(.bottom, 2)
        .onChange(of: dateViewModel.selectedMonth) {
            budgetViewModel.calculateSelectedMonthBudgetMetrics(for: dateViewModel.selectedMonth, monthlyIncome: userViewModel.monthlyIncome, monthlyFixedSpend: userViewModel.monthlyFixedSpend)
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

    private func calculateHighlightedDotIndex() -> Int {
        let currentIndex = SpendFilter.allCases.firstIndex(of: selectedSpendFilter) ?? 0
        let dragOffsetWidth = dragOffset.width
        let threshold: CGFloat = 20 

        let potentialIndex = currentIndex - Int(dragOffsetWidth / threshold)

        if potentialIndex >= 0 && potentialIndex < SpendFilter.allCases.count {
            return potentialIndex
        } else if potentialIndex < 0 {
            return 0
        } else {
            return SpendFilter.allCases.count - 1
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
