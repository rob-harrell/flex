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
    @Binding var selectedSpendFilter: SpendFilter
    @State private var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var hasTapped: Bool = false
    @State private var scrollPosition: Int?
    @State private var showingOverlay = false
    @State private var spacerCounts: [Int] = []

    let calendar = Calendar.current
    let columns: [GridItem] = Array(repeating: .init(.flexible(), spacing: 0), count: 7)

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
                VStack (spacing: -1) {
                    ForEach(sharedViewModel.dates.indices, id: \.self) { index in
                        LazyVGrid(columns: columns, spacing: 0) {
                            // Use an Int range to create the necessary number of spacers
                            if !spacerCounts.isEmpty && index < spacerCounts.count {
                                ForEach(0..<spacerCounts[index], id: \.self) { _ in
                                    Spacer().frame(height: 86)
                                }
                            }
                            // Display the dates for the month
                            ForEach(sharedViewModel.dates[index], id: \.self) { date in
                                calendarDateView(for: date)
                                    .id("\(sharedViewModel.stringForDate(sharedViewModel.selectedMonth, format: "MMMM yyyy"))-\(date)")
                            }
                        }
                        .containerRelativeFrame(.vertical, alignment: .top)
                    }
                }
                .padding(.top, 2)
                .onAppear {
                    spacerCounts = sharedViewModel.dates.map { date in
                        let firstDayOfWeekday = calendar.component(.weekday, from: date.first!) - 1
                        return firstDayOfWeekday
                    }
                    if let index = sharedViewModel.dates.firstIndex(where: { sharedViewModel.calendar.isDate($0.first!, equalTo: sharedViewModel.selectedMonth, toGranularity: .month) }) {
                        scrollPosition = index
                    }
                }
            }
            .frame(height: 434)
            .scrollTargetLayout()
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $scrollPosition)
            .onChange(of: sharedViewModel.selectedMonth) { oldValue, newValue in
                let monthIndex = sharedViewModel.dates.firstIndex(where: {
                    let dateString = sharedViewModel.stringForDate($0.first!, format: "MMMM yyyy")
                    return dateString == sharedViewModel.stringForDate(newValue, format: "MMMM yyyy")
                })
                if let index = monthIndex {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        print("Updated scroll position: \(index)") // Print the updated scroll position
                        scrollPosition = index
                    }
                }
            }
            .onChange(of: scrollPosition) { oldValue, newValue in
                if let index = newValue {
                    print("Scroll position changed: \(index)") // Print when the scroll position changes
                    sharedViewModel.selectedMonth = sharedViewModel.dates[index].first!
                }
            }
        }
    }
        
    @ViewBuilder
    private func calendarDateView(for date: Date) -> some View {
        let today = sharedViewModel.currentDay
        let cellDate = calendar.startOfDay(for: date)
        let isPastOrToday = cellDate <= today
        let isFuture = cellDate > today
        let isInSelectedMonth = calendar.isDate(cellDate, equalTo: sharedViewModel.selectedMonth, toGranularity: .month)
        let curveDataPoints = budgetViewModel.dataPointsPerDay.filter { calendar.isDate($0.key, equalTo: cellDate, toGranularity: .day) }.first?.value ?? [0, 0, 0]


        Button(action: {
            if !isFuture {
                sharedViewModel.selectedDay = cellDate
                hasTapped = true
                showingOverlay = true
            }
        }) {
            VStack {
                Text(sharedViewModel.stringForDate(date, format: "d")) // Date
                    .font(.caption)
                    .foregroundColor(cellDate == sharedViewModel.selectedDay && showingOverlay ? Color.white : (calendar.isDate(cellDate, inSameDayAs: today) ? Color.black : Color.slate400))
                    .fixedSize(horizontal: false, vertical: true) // Prevent stretching
                    .padding(.vertical, 8)
                    .fontWeight(.medium)
                    .transition(.identity)

                if !isFuture && isInSelectedMonth {
                    let flexSpend = budgetViewModel.selectedMonthFlexSpendPerDay.filter { calendar.isDate($0.key, equalTo: cellDate, toGranularity: .day) }.first?.value ?? 0
                    let fixedSpend = budgetViewModel.selectedMonthFixedSpendPerDay.filter { calendar.isDate($0.key, equalTo: cellDate, toGranularity: .day) }.first?.value ?? 0
                    let income = budgetViewModel.selectedMonthIncomePerDay.filter { calendar.isDate($0.key, equalTo: cellDate, toGranularity: .day) }.first?.value ?? 0
                    
                    Group {
                        switch selectedSpendFilter {
                        case .discretionary where flexSpend > 0:
                            Text(formatBudgetNumber(flexSpend))
                                .font(.caption)
                                .foregroundColor(cellDate == sharedViewModel.selectedDay && showingOverlay ? Color.white : Color.black)
                                .fixedSize(horizontal: false, vertical: true)
                                .fontWeight(.semibold)
                                .transition(.identity)
                        case .bills where fixedSpend > 0:
                            Text(formatBudgetNumber(fixedSpend))
                                .font(.caption)
                                .foregroundColor(Color.slate500)
                                .fixedSize(horizontal: false, vertical: true)
                                .fontWeight(.semibold)
                                .transition(.identity)
                        case .income where abs(income) > 0:
                            Text(formatBudgetNumber(abs(income)))
                                .font(.caption)
                                .foregroundColor(Color.emerald600)
                                .fixedSize(horizontal: false, vertical: true)
                                .fontWeight(.semibold)
                                .transition(.identity)
                        case .allSpend where fixedSpend + flexSpend > 0:
                            Text(formatBudgetNumber(abs(flexSpend + fixedSpend)))
                                .font(.caption)
                                .fixedSize(horizontal: false, vertical: true)
                                .fontWeight(.semibold)
                                .transition(.identity)
                        default:
                            EmptyView()
                        }
                    }
                }

                Spacer()
            }
            .frame(minWidth: 0, maxWidth: .infinity)
            .frame(height: 86)
            .background(cellDate == sharedViewModel.selectedDay && showingOverlay ? Color.black : Color.clear)
            .animation(.default, value: sharedViewModel.selectedDay)
        }
        .disabled(isFuture)
        .sheet(isPresented: $showingOverlay) {
            if hasTapped {
                TransactionsListOverlay(selectedSpendFilter: $selectedSpendFilter, date: sharedViewModel.selectedDay)
                    .environmentObject(budgetViewModel)
                    .presentationDetents([.fraction(0.35), .fraction(1.0)])
                    .presentationCornerRadius(24)
            }
        }
        .overlay(
            ZStack {
                RoundedRectangle(cornerRadius: 0)
                    .stroke(calendar.isDate(cellDate, inSameDayAs: today) ? Color.black : Color.slate100, lineWidth: calendar.isDate(cellDate, inSameDayAs: today) ? 1 : 0.75)
                if isPastOrToday && (selectedSpendFilter == .discretionary || selectedSpendFilter == .allSpend)  {
                    BudgetCurveView(dataPoints: curveDataPoints)
                        .opacity(0.4)
                }
            }
        )
        .padding(0.25)
        .offset(x: -0.25, y: -0.25)
        .onAppear {
            let formattedDate = DateFormatter.localizedString(from: cellDate, dateStyle: .short, timeStyle: .none)
            //print("Cell.onappear Date: \(formattedDate), Bezier points: \(curveDataPoints)")
        }
    }
}

#Preview {
    BudgetCalendarView(selectedSpendFilter: .constant(.discretionary))
        .environmentObject(UserViewModel())
        .environmentObject(DateViewModel())
        .environmentObject(BudgetViewModel())
}
