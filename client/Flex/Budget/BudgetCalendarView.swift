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
    @State private var selectedDate: Date?
    @State private var scrollPosition: Int?
    
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
                LazyVStack {
                    ForEach(sharedViewModel.dates.indices, id: \.self) { index in
                        LazyVGrid(columns: columns, spacing: 0) {
                            ForEach(sharedViewModel.dates[index], id: \.self) { date in
                                calendarDateView(for: date)
                            }
                        }
                        .id(index)
                    }
                }
                .scrollTargetLayout()
            }
            .frame(height: 383)
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
                    scrollPosition = index
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
        
        Button(action: {
            selectedDate = date
        }) {
            VStack {
                Text(sharedViewModel.stringForDate(date, format: "d")) // Date
                    .font(.caption)
                    .foregroundColor(cellDate == today || date == selectedDate ? Color.black : Color.gray)
                    .fixedSize(horizontal: false, vertical: true) // Prevent stretching
                    .padding(.vertical, 8)
                    .fontWeight(.semibold)
                
                Text(budgetViewModel.spendingStringForDate(date)) // Spending amount
                    .font(.caption)
                    .foregroundColor(cellDate == today || date == selectedDate ? Color.black : Color.gray)
                    .fixedSize(horizontal: false, vertical: true) // Prevent stretching
                    .fontWeight(.semibold)
                Spacer()
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 75)
            .background(isPastOrToday ? Color(.slate) : Color.clear)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(cellDate == today || date == selectedDate ? Color.black : Color(.gray.opacity(0.2)), lineWidth: 0.5)
        )
    }
}


#Preview {
    BudgetCalendarView()
        .environmentObject(UserViewModel())
        .environmentObject(DateViewModel())
        .environmentObject(BudgetViewModel())
}
