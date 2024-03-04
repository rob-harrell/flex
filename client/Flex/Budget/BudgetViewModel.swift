//
//  BudgetViewModel.swift
//  Flex
//
//  Created by Rob Harrell on 1/28/24.
//

import Foundation
import SwiftUI

class BudgetViewModel: ObservableObject {      
    @Published var spendingData: [Date: Double] = [:]
    @Published var monthlyIncome: Double = 5000.0 // User-set monthly income
                
    var sharedViewModel: DateViewModel
    
    // Computed properties to calculate total expenses
    var totalExpensesPerDay: [Date: Double] {
        var expenses: [Date: Double] = [:]
        for (date, spending) in spendingData {
            expenses[date] = spending
        }
        return expenses
    }

    var totalExpensesPerMonth: [Date: Double] {
        var expenses: [Date: Double] = [:]
        for monthDates in sharedViewModel.dates {
            let totalSpending = monthDates.compactMap { spendingData[$0] }.reduce(0, +)
            expenses[monthDates.first!] = totalSpending
        }
        return expenses
    }

    var expensesMonthToDate: Double {
        let now = Date()
        let startOfMonth = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: now))!
        let range = startOfMonth...now
        let totalSpending = spendingData.filter { range.contains($0.key) }.values.reduce(0, +)
        return totalSpending
    }

    var monthlySavings: [Date: Double] {
        var savings: [Date: Double] = [:]
        for (date, totalExpenses) in totalExpensesPerMonth {
            savings[date] = monthlyIncome - totalExpenses
        }
        return savings
    }

    var currentMonthSavings: Double {
        return monthlyIncome - expensesMonthToDate
    }

    init(sharedViewModel: DateViewModel) {
        self.sharedViewModel = sharedViewModel
        generateSpendingData()
    }
    
    // Function to generate dummy spending data for the past 12 months
    private func generateSpendingData() {
        for monthDates in sharedViewModel.dates {
            for date in monthDates {
                // Generate and store dummy spending data for the date
                let randomSpending = Double.random(in: 1...100)
                spendingData[date] = randomSpending
            }
        }
    }
    
    // Function to return spending amount for a given date as a string
    func spendingStringForDate(_ date: Date) -> String {
        if let spending = spendingData[date] {
            return "$\(Int(round(spending)))"
        } else {
            return "$0"
        }
    }
}
