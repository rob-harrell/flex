//
//  BudgetCalendarView.swift
//  Flex
//
//  Created by Rob Harrell on 1/28/24.
//

import SwiftUI

struct BudgetCalendarView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @EnvironmentObject var sharedViewModel: DateViewModel
    @EnvironmentObject var budgetViewModel: BudgetViewModel
    @State private var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var hasTapped: Bool = false
    @State private var scrollPosition: Int?
    @State private var showingOverlay = false
    
    let columns: [GridItem] = Array(repeating: .init(.flexible(), spacing: 0), count: 7)
    
    let numberOfRows = 5
    let cellHeight = 86.0
    let spacing = 0.0
    var scrollViewHeight: Double {
        Double(numberOfRows) * cellHeight + Double(numberOfRows - 1) * spacing
    }
    
    var body: some View {
        VStack {
            // Weekday headers
            HStack(spacing: 10) {
                ForEach(["S", "M", "T", "W", "T", "F", "S"].indices, id: \.self) { index in
                    Text(["S", "M", "T", "W", "T", "F", "S"][index])
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 4)

            // Vertical paging ScrollView for the month
            ScrollView {
                LazyVStack (spacing: -1) {
                    ForEach(sharedViewModel.dates.indices, id: \.self) { index in
                        VStack{
                            Spacer()
                                .frame(height: 2)
                            LazyVGrid(columns: columns, spacing: 0) {
                                ForEach(sharedViewModel.dates[index], id: \.self) { date in
                                    calendarDateView(for: date)
                                        .id("\(sharedViewModel.stringForDate(sharedViewModel.selectedMonth, format: "MMMM yyyy"))-\(date)")
                                }
                            }
                            .id(index)
                        }
                    }
                }
                .scrollTargetLayout()
            }
            .frame(height: 434)
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $scrollPosition, anchor: .top)
            .onAppear {
                scrollPosition = sharedViewModel.selectedMonthIndex
            }
            .onChange(of: sharedViewModel.selectedMonth) { oldValue, newValue in
                let monthIndex = sharedViewModel.dates.firstIndex(where: {
                    let dateString = sharedViewModel.stringForDate($0.first!, format: "MMMM yyyy")
                    return dateString == sharedViewModel.stringForDate(newValue, format: "MMMM yyyy")
                })
                if let index = monthIndex {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        scrollPosition = index
                    }
                }
            }
            .onChange(of: scrollPosition) { oldValue, newValue in
                if let index = newValue {
                    sharedViewModel.selectedMonth = sharedViewModel.dates[index].first!
                }
            }
        }
    }
        
        
   @ViewBuilder
    private func calendarDateView(for date: Date) -> some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let cellDate = calendar.startOfDay(for: date)
        let isPastOrToday = cellDate <= today && calendar.isDate(cellDate, equalTo: today, toGranularity: .month)
        let isFuture = cellDate > today

        Button(action: {
            selectedDate = date
            hasTapped = true
            showingOverlay = true
        }) {
            VStack {
                Text(sharedViewModel.stringForDate(date, format: "d")) // Date
                    .font(.caption)
                    .foregroundColor(cellDate == selectedDate ? Color.black : Color.slate500)
                    .fixedSize(horizontal: false, vertical: true) // Prevent stretching
                    .padding(.vertical, 8)
                    .fontWeight(.semibold)

                if !isFuture {
                    let flexSpend = Int(budgetViewModel.totalFlexSpendPerDay[date, default: 0])
                    let fixedSpend = Int(budgetViewModel.totalFixedSpendPerDay[date, default: 0])  
                    let income = Int(budgetViewModel.totalIncomePerDay[date, default: 0])

                    if flexSpend > 0 {
                        Text("$\(flexSpend)") // Flex spend
                            .font(.caption)
                            .foregroundColor(Color.black)
                            .fixedSize(horizontal: false, vertical: true) // Prevent stretching
                            .fontWeight(.semibold)
                    }

                    if fixedSpend > 0 {
                        Text("$\(fixedSpend)") // Fixed spend
                            .font(.caption)
                            .foregroundColor(Color.slate500)
                            .fixedSize(horizontal: false, vertical: true) // Prevent stretching
                            .fontWeight(.semibold)
                    }
                    
                    if abs(income) > 0 {
                        Text("+$\(abs(income))")
                            .font(.caption)
                            .foregroundColor(Color.emerald600)
                            .fixedSize(horizontal: false, vertical: true) // Prevent stretching
                            .fontWeight(.semibold)
                    }
                    
                }

                Spacer()
            }
            .frame(minWidth: 0, maxWidth: .infinity)
            .frame(height: 86)
            .background(isPastOrToday ? Color(.slate) : Color.clear)
        }
        .sheet(isPresented: $showingOverlay) {
            if hasTapped {
                TransactionsListOverlay(date: selectedDate)
                    .environmentObject(budgetViewModel)
                    .presentationDetents([.fraction(0.50), .fraction(1.0)])
            }
        }
        .overlay(
            ZStack {
                RoundedRectangle(cornerRadius: 0)
                    .stroke(Color.slate200, lineWidth: 0.75)
                if cellDate == selectedDate {
                    RoundedRectangle(cornerRadius: 0)
                        .stroke(Color.black, lineWidth: 1.0)
                }
            }
        )
        .padding(0.25) // Add padding equal to half the border width
        .offset(x: -0.25, y: -0.25)
    }
}

#Preview {
    BudgetCalendarView()
        .environmentObject(UserViewModel())
        .environmentObject(DateViewModel())
        .environmentObject(BudgetViewModel())
}
