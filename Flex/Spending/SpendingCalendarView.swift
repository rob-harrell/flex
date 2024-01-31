//
//  SpendingCalendarView.swift
//  Flex
//
//  Created by Rob Harrell on 1/28/24.
//

import SwiftUI

struct SpendingCalendarView: View {
    @ObservedObject var viewModel: SpendingViewModel
    @State private var selectedDate: Date?

    let columns: [GridItem] = Array(repeating: .init(.flexible(), spacing: 0), count: 7)

    var body: some View {
        VStack {
            // Month header
            HStack {
                Text("December") // Replace with dynamic month
                    .font(.title2)
                    .fontWeight(.bold)
                    .frame(alignment: .leading) // Align text to the leading edge
                Spacer() // Pushes the text to the left
            }
            .padding(.leading) // Add padding to the left of "December"
            .padding(.bottom)  // Add padding between "December" and day headers
            .padding(.top) // Add padding above month header


            // Weekday headers
            HStack(spacing: 10) {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .font(.body)
                }
            }
            .padding(.horizontal) // Add horizontal padding to match the grid alignment


            // Date and spending grid
            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(viewModel.dates, id: \.self) { date in
                    Button(action: {
                        selectedDate = date
                    }) {
                        VStack {
                            Text(viewModel.stringForDate(date)) // Date
                                .font(.body)
                                .foregroundColor(.gray)
                                .fixedSize(horizontal: false, vertical: true) // Prevent stretching

                            Text(viewModel.spendingStringForDate(date)) // Spending amount
                                .font(.caption)
                                .foregroundColor(.gray)
                                .fixedSize(horizontal: false, vertical: true) // Prevent stretching
                        }
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 60)
                        .background(date == selectedDate ? Color.gray : Color.clear)
                        .border(Color.gray.opacity(0.3), width: 1) // Use border instead of overlay for shared walls
                    }
                }
            }
            .padding() // Padding around the grid
        }
    }
}

#Preview {
    SpendingCalendarView(viewModel: SpendingViewModel())
}
