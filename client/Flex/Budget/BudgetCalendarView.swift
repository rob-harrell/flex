//
//  BudgetCalendarView.swift
//  Flex
//
//  Created by Rob Harrell on 1/28/24.
//

import SwiftUI

struct BudgetCalendarView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @EnvironmentObject var dateViewModel: DateViewModel
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
                    ForEach(dateViewModel.allTransactionDates.indices, id: \.self) { index in
                        LazyVGrid(columns: columns, spacing: 0) {
                            // Use an Int range to create the necessary number of spacers
                            if !spacerCounts.isEmpty && index < spacerCounts.count {
                                ForEach(0..<spacerCounts[index], id: \.self) { _ in
                                    Spacer().frame(height: 86)
                                }
                            }
                            // Display the dates for the month
                            ForEach(dateViewModel.allTransactionDates[index], id: \.self) { date in
                                calendarDateView(for: date, remainingDailyFlex: budgetViewModel.remainingDailyFlex, remainingBudgetHeight: budgetViewModel.remainingBudgetHeight, isDayOverBudget: budgetViewModel.isDayOverBudget[date] ?? false)
                                    .id("\(dateViewModel.stringForDate(dateViewModel.selectedMonth, format: "MMMM yyyy"))-\(date)")
                            }
                        }
                        .containerRelativeFrame(.vertical, alignment: .top)
                    }
                }
                .padding(.top, 2)
                .onAppear {
                    spacerCounts = dateViewModel.allTransactionDates.map { date in
                        let firstDayOfWeekday = calendar.component(.weekday, from: date.first!) - 1
                        return firstDayOfWeekday
                    }
                    if let index = dateViewModel.allTransactionDates.firstIndex(where: { dateViewModel.calendar.isDate($0.first!, equalTo: dateViewModel.selectedMonth, toGranularity: .month) }) {
                        scrollPosition = index
                    }
                }
            }
            .frame(height: 434)
            .scrollTargetLayout()
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $scrollPosition)
            .onChange(of: dateViewModel.selectedMonth) { oldValue, newValue in
                let monthIndex = dateViewModel.allTransactionDates.firstIndex(where: {
                    let dateString = dateViewModel.stringForDate($0.first!, format: "MMMM yyyy")
                    return dateString == dateViewModel.stringForDate(newValue, format: "MMMM yyyy")
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
                    dateViewModel.selectedMonth = dateViewModel.allTransactionDates[index].first!
                }
            }
        }
    }
        
    @ViewBuilder
    private func calendarDateView(for date: Date, remainingDailyFlex: Double, remainingBudgetHeight: Double, isDayOverBudget: Bool) -> some View {
        let today = dateViewModel.currentDay
        let cellDate = calendar.startOfDay(for: date)
        let isToday = calendar.isDate(cellDate, inSameDayAs: today)
        let isFirstDayOfPreviousMonth = calendar.component(.day, from: cellDate) == 1 && 
            ((calendar.component(.year, from: cellDate) < calendar.component(.year, from: today)) || 
            (calendar.component(.year, from: cellDate) == calendar.component(.year, from: today) && 
            calendar.component(.month, from: cellDate) < calendar.component(.month, from: today)))
        let isFuture = cellDate > today
        let isInSelectedMonth = calendar.isDate(cellDate, equalTo: dateViewModel.selectedMonth, toGranularity: .month)
        let curveDataPoints = budgetViewModel.budgetCurvePoints.filter { calendar.isDate($0.key, equalTo: cellDate, toGranularity: .day) }.first?.value ?? [0, 0, 0]
        let todayBills = budgetViewModel.selectedMonthTransactions[cellDate]?.filter { $0.budgetCategory == "Fixed" } ?? []

        Button(action: {
            if !isFuture {
                dateViewModel.selectedDay = cellDate
                hasTapped = true
                showingOverlay = true
            }
        }) {
            VStack {
                Text(dateViewModel.stringForDate(date, format: "d")) // Date
                    .font(.caption)
                    .foregroundColor(cellDate == dateViewModel.selectedDay && showingOverlay ? Color.white : (calendar.isDate(cellDate, inSameDayAs: today) ? Color.black : Color.slate400))
                    .fixedSize(horizontal: false, vertical: true) // Prevent stretching
                    .padding(.top, 8)
                    .padding(.bottom, 4)
                    .fontWeight(.medium)
                    .transition(.identity)

                if !isFuture && isInSelectedMonth {
                    let flexSpend = budgetViewModel.selectedMonthFlexSpendPerDay.filter { calendar.isDate($0.key, equalTo: cellDate, toGranularity: .day) }.first?.value ?? 0
                    let fixedSpend = budgetViewModel.selectedMonthFixedSpendPerDay.filter { calendar.isDate($0.key, equalTo: cellDate, toGranularity: .day) }.first?.value ?? 0
                    let income = budgetViewModel.selectedMonthIncomePerDay.filter { calendar.isDate($0.key, equalTo: cellDate, toGranularity: .day) }.first?.value ?? 0
                    
                    Group {
                        switch selectedSpendFilter {
                        case .discretionary where flexSpend > 0 && userViewModel.hasToggledDailySpend:
                            Text(formatBudgetNumber(flexSpend))
                                .font(.caption)
                                .foregroundColor(cellDate == dateViewModel.selectedDay && showingOverlay ? Color.white : isDayOverBudget ? Color.red600 : Color.black)
                                .fixedSize(horizontal: false, vertical: true)
                                .fontWeight(.semibold)
                                .transition(.identity)
                        case .bills where fixedSpend > 0:
                            Text(formatBudgetNumber(fixedSpend))
                                .font(.caption)
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
                        case .allSpend where fixedSpend + flexSpend > 0 && userViewModel.hasToggledDailySpend:
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
            .background(cellDate == dateViewModel.selectedDay && showingOverlay ? Color.black : Color.clear)
            .animation(.default, value: dateViewModel.selectedDay)
        }
        .disabled(isFuture)
        .sheet(isPresented: $showingOverlay) {
            if hasTapped {
                TransactionsListOverlay(selectedSpendFilter: $selectedSpendFilter, date: dateViewModel.selectedDay)
                    .environmentObject(budgetViewModel)
                    .presentationDetents([.fraction(0.5), .fraction(1.0)])
                    .presentationCornerRadius(24)
            }
        }
        .overlay(
            ZStack {
                RoundedRectangle(cornerRadius: 0)
                    .stroke(isToday ? Color.black : Color.slate100, lineWidth: isToday ? 1 : 0.75)
                if !isFuture && (selectedSpendFilter == .discretionary || selectedSpendFilter == .allSpend)  {
                    BudgetCurveView(dataPoints: curveDataPoints, isOverBudget: isDayOverBudget)
                        .opacity(0.4)
                    if !isToday && isInSelectedMonth && !userViewModel.hasToggledDailySpend {
                        GeometryReader { geometry in
                            Rectangle()
                                .fill(isDayOverBudget ? Color.red500 : Color.slate500)
                                .frame(height: 0.75)
                                .offset(y: geometry.size.height * CGFloat(1 - budgetViewModel.avgFlexSpendHeight))
                        }
                    }
                } else if isFuture && (selectedSpendFilter == .discretionary || selectedSpendFilter == .allSpend) && remainingDailyFlex >= 0.0 {
                    GeometryReader { geometry in
                        VStack {
                            Spacer()
                            Rectangle()
                                .fill(Color("emerald50"))
                                .frame(height: max(geometry.size.height * CGFloat(remainingBudgetHeight), geometry.size.height * 0.08))
                                .overlay(Divider().background(Color("emerald500")), alignment: .top)
                        }
                        if calendar.isDate(cellDate, inSameDayAs: Calendar.current.date(byAdding: .day, value: 1, to: today)!) {
                            Text(formatBudgetNumber(remainingDailyFlex))
                                .font(.system(size: 14))
                                .foregroundColor(Color.emerald600)
                                .fixedSize(horizontal: false, vertical: true)
                                .fontWeight(.semibold)
                                .transition(.identity)
                                .padding(.horizontal, 2)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .frame(maxWidth: .infinity, alignment: .center)
                                .offset(y: geometry.size.height - 9 - max(geometry.size.height * CGFloat(remainingBudgetHeight), geometry.size.height * 0.08))
                        }
                    }
                }
                if !isFuture && (selectedSpendFilter == .bills || selectedSpendFilter == .allSpend) && !todayBills.isEmpty {
                    VStack {
                        ForEach(todayBills, id: \.id) { bill in
                            ZStack (alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.slate100) 
                                    .frame(width: 54, height: 14) 
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(Color.slate400, lineWidth: 0.5)
                                    )
                                    .padding(.bottom, 1)
                                Text(bill.productCategory)
                                    .font(.system(size: 10))
                                    .fontWeight(.medium)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                    .padding(.leading, 4)
                                    .padding(.bottom, 1)
                            }
                        }
                    }
                    .padding(.top, 24)
                }
                if (isToday || isFirstDayOfPreviousMonth) && (selectedSpendFilter == .discretionary || selectedSpendFilter == .allSpend) && !userViewModel.hasToggledDailySpend {
                    GeometryReader { geometry in
                        Text(formatBudgetNumber(budgetViewModel.selectedMonthAvgFlexSpend))
                            .font(.system(size: 14))
                            .fontWeight(.semibold)
                            .padding(.horizontal, 2)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .offset(y: geometry.size.height * CGFloat(1 - budgetViewModel.avgFlexSpendHeight) - 9)
                            
                    }
                }
            }
        )
        .padding(0.25)
        .offset(x: -0.25, y: -0.25)
    }
}

#Preview {
    BudgetCalendarView(selectedSpendFilter: .constant(.discretionary))
        .environmentObject(UserViewModel())
        .environmentObject(DateViewModel())
        .environmentObject(BudgetViewModel())
}
