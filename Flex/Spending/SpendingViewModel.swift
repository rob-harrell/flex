//
//  SpendingViewModel.swift
//  Flex
//
//  Created by Rob Harrell on 1/28/24.
//

import Foundation
import SwiftUI

class SpendingViewModel: ObservableObject {
    // Dummy data for total spending
    @Published var totalSpending: String = "-$7,505"
    
    // Dummy data for spending by date
    @Published var spendingData: [Date: Double] = [:]
    
    init() {
        generateDummyData()
    }
    
    // Function to generate dummy spending data
    private func generateDummyData() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd"
        
        // Generate spending data for the current month
        for dayOffset in 0..<30 {
            if let date = calendar.date(byAdding: .day, value: dayOffset, to: today) {
                let randomSpending = Double.random(in: 1...100)
                spendingData[date] = randomSpending
            }
        }
    }
    
    // Function to return a string representation of the date
    func stringForDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd"
        return formatter.string(from: date)
    }
    
    // Function to return spending amount for a given date as a string
    func spendingStringForDate(_ date: Date) -> String {
        if let spending = spendingData[date] {
            return "$\(Int(round(spending)))"
        } else {
            return "$0"
        }
    }
    
    // Function to get an array of dates for the current month
    var dates: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let range = calendar.range(of: .day, in: .month, for: today)!
        
        return range.compactMap { day -> Date? in
            return calendar.date(byAdding: .day, value: day - 1, to: today)
        }
    }
}
