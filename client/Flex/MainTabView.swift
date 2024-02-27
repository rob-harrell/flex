//
//  NavigationView.swift
//  Flex
//
//  Created by Rob Harrell on 1/27/24.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Tab = .budget
    @State private var showingMonthSelection = false
    @StateObject var sharedViewModel = SharedViewModel()
    let communicator: ServerCommunicator
    
    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                BudgetView(sharedViewModel: sharedViewModel)
                    .tabItem {
                        Label("Budget", image: "Budget")
                    }
                    .tag(Tab.budget)

                BalancesView()
                    .tabItem {
                        Label("Balances", image: "Balances")
                    }
                    .tag(Tab.balances)
                
                TrendsView()
                    .tabItem {
                        Label("Trends", image: "Trends")
                    }
                    .tag(Tab.trends)
                
                SettingsView(communicator: communicator)
                    .tabItem {
                        Label("Settings", image: "Settings")
                    }
                    .tag(Tab.settings)
            }
            .onAppear {
                UITabBarItem.appearance().setTitleTextAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12)], for: .normal)
                UITabBarItem.appearance().setTitleTextAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12)], for: .selected)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingMonthSelection.toggle()
                    }) {
                        HStack {
                            Text(sharedViewModel.stringForDate(sharedViewModel.selectedMonth, format: "MMMM yyyy"))
                                .font(.headline)
                                .fontWeight(.semibold)
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                    }
                    .sheet(isPresented: $showingMonthSelection) {
                        MonthSelectorView(showingMonthSelection: $showingMonthSelection, sharedViewModel: sharedViewModel)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            // Handle the button tap
                        }) {
                            Image("Bell")
                        }
                }
            }
        }
    }
        
    enum Tab {
        case budget
        case balances
        case trends
        case settings
    }
}

#Preview {
    MainTabView(communicator: ServerCommunicator())
}
