//
//  BudgetFilterView.swift
//  Flex
//
//  Created by Rob Harrell on 1/28/24.
//

import SwiftUI

struct BudgetFilterView: View {
    @Binding var selectedSpendFilter: SpendFilter
    @Binding var showingSpendFilter: Bool
    @State private var newSpendFilter: SpendFilter

    var body: some View {
        VStack {
            ZStack {
                Text("Filter transactions")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                HStack {
                    Spacer()
                    Button(action: {
                        showingSpendFilter = false
                    }) {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                            .background(Color.white)
                            .foregroundColor(.slate400)
                            .clipShape(Circle())
                    }
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 4)
            
            ScrollView {
                Text("See how you're tracking against your monthly budget. Past Months will show actual amounts.")
                    .font(.system(size: 14))
                    .foregroundColor(.slate500)
                    .lineSpacing(4)
                    .padding(.bottom, 8)
                
                //Income filter
                Button(action: {
                    newSpendFilter = .income
                }) {
                    HStack {
                        Image(.accruals)
                            .resizable()
                            .frame(width: 64, height: 64)
                        Text("Income")
                            .font(.system(size: 16))
                            .fontWeight(.semibold)
                        Spacer()
                        ZStack {
                            Circle()
                                .stroke(Color.slate500, lineWidth: 1)
                                .frame(width: 16, height: 16)
                            if newSpendFilter == .income {
                                Circle()
                                    .fill(Color.black)
                                    .frame(width: 8, height: 8)
                            }
                        }
                        .padding(.trailing, 4)
                    }
                }
                .padding(.bottom, 10)

                //Spending filters
                HStack {
                    Image(.accruals)
                        .resizable()
                        .frame(width: 64, height: 64)
                    Text("Spending")
                        .font(.system(size: 16))
                        .fontWeight(.semibold)
                    Spacer()
                    Image(systemName: "chevron.up")
                        .resizable()
                        .frame(width: 14, height: 8)
                        .fontWeight(.semibold)
                        .foregroundColor(.slate400)
                        .padding(.trailing, 4)
                }
                .padding(.bottom, 8)

                //Total Spend filter
                Button(action: {
                    newSpendFilter = .allSpend
                }) {
                    HStack {
                        Text("All spend")
                            .font(.system(size: 14))
                            .fontWeight(.semibold)
                        Spacer()
                        ZStack {
                            Circle()
                                .stroke(Color.slate500, lineWidth: 1)
                                .frame(width: 16, height: 16)
                            if newSpendFilter == .allSpend {
                                Circle()
                                    .fill(Color.black)
                                    .frame(width: 8, height: 8)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 16)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(newSpendFilter == .allSpend ? Color.black : Color.slate200, lineWidth: newSpendFilter == .allSpend ? 2 : 1)
                )
                .padding(.horizontal, 1)

                //Bills filter
                Button(action: {
                    newSpendFilter = .bills
                }) {
                    HStack {
                        Text("Bills")
                            .font(.system(size: 14))
                            .fontWeight(.semibold)
                        Spacer()
                        ZStack {
                            Circle()
                                .stroke(Color.slate500, lineWidth: 1)
                                .frame(width: 16, height: 16)
                            if newSpendFilter == .bills {
                                Circle()
                                    .fill(Color.black)
                                    .frame(width: 8, height: 8)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 16)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(newSpendFilter == .bills ? Color.black : Color.slate200, lineWidth: newSpendFilter == .bills ? 2 : 1)
                )
                .padding(.horizontal, 1)

                //Discretionary filter
                Button(action: {
                    newSpendFilter = .discretionary
                }) {
                    HStack {
                        Text("Discretionary")
                            .font(.system(size: 14))
                            .fontWeight(.semibold)
                        Spacer()
                        ZStack {
                            Circle()
                                .stroke(Color.slate500, lineWidth: 1)
                                .frame(width: 16, height: 16)
                            if newSpendFilter == .discretionary {
                                Circle()
                                    .fill(Color.black)
                                    .frame(width: 8, height: 8)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 16)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(newSpendFilter == .discretionary ? Color.black : Color.slate200, lineWidth: newSpendFilter == .discretionary ? 2 : 1)
                )
                .padding(.horizontal, 1)
                .padding(.bottom, 4)
            }

            //Done Button
            Button(action: {
                showingSpendFilter = false
                selectedSpendFilter = newSpendFilter
            }) {
                Text("Done")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .cornerRadius(12)
            }
            .padding(.top, 8)
        }
    }

    init(selectedSpendFilter: Binding<SpendFilter>, showingSpendFilter: Binding<Bool>) {
        self._selectedSpendFilter = selectedSpendFilter
        self._showingSpendFilter = showingSpendFilter
        self._newSpendFilter = State(initialValue: selectedSpendFilter.wrappedValue)
    }
}

/*
struct BudgetFilterView: View {
    @Binding var selectedFilter: BudgetFilter
    @Namespace private var animation

    var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .center, spacing: 0) {
                ForEach(BudgetFilter.allCases, id: \.self) { filter in
                    Button(action: {
                        withAnimation {
                            selectedFilter = filter
                        }
                    }) {
                        HStack {
                            if filter == .fixed {
                                Image(systemName: "lock.fill")
                                    .padding(.trailing, -4)
                            }
                            Text(filter.rawValue)
                                .font(.subheadline)
                        }
                        .frame(height: 44)
                        .padding(.horizontal, selectedFilter == .fixed ? (filter == .fixed ? 6 : -6) : (filter == .fixed ? 0 : 20))
                        .background(
                            Group {
                                if selectedFilter == filter {
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.white)
                                        .matchedGeometryEffect(id: "background", in: animation)
                                        .frame(height: 36)
                                }
                            }
                        )
                    }
                }
                .frame(width: 212 / CGFloat(BudgetFilter.allCases.count))
            }
        }
        .frame(width: 216, height: 44)
        .background(Color.slate200)
        .cornerRadius(20)
    }
}

enum BudgetFilter: String, CaseIterable {
    case all = "All"
    case fixed = "Fixed"
    case flex = "Flex"
}
*/

#Preview {
    BudgetFilterView(selectedSpendFilter: .constant(.discretionary), showingSpendFilter: .constant(true))
        .environmentObject(UserViewModel())
        .environmentObject(DateViewModel())
        .environmentObject(BudgetViewModel())
}
