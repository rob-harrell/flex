//
//  NavigationView.swift
//  Flex
//
//  Created by Rob Harrell on 1/27/24.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Tab = .home
    @State private var showingSettings = false
    
    let spendingViewModel = SpendingViewModel()

    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }
                    .tag(Tab.home)

                SpendingView(viewModel: spendingViewModel)
                    .tabItem {
                        Label("Spending", systemImage: "banknote")
                    }
                    .tag(Tab.spending)

                BudgetView()
                    .tabItem {
                        Label("Budget", systemImage: "list.bullet")
                    }
                    .tag(Tab.budget)

                BalancesView()
                    .tabItem {
                        Label("Balances", systemImage: "chart.bar")
                    }
                    .tag(Tab.balances)
            }
            .padding(.bottom, 10) // Adds padding to the bottom of the TabView
            .navigationBarItems(trailing: Button(action: {
                showingSettings = true
            }) {
                Image(systemName: "gear")
                    .imageScale(.large)
                    .padding(.top, 60)
            })
            .fullScreenCover(isPresented: $showingSettings) {
                SettingsView()
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    titleViewForSelectedTab(selectedTab)
                }
            }
        }
    }
    
    // Function to return the appropriate title view based on the selected tab
    @ViewBuilder
    private func titleViewForSelectedTab(_ tab: Tab) -> some View {
        HStack {
            VStack(alignment: .leading) {
                switch tab {
                case .home:
                    Text("Home Page")
                case .spending:
                    SpendingHeaderView(viewModel: spendingViewModel)
                case .budget:
                    Text("Budget Page")
                case .balances:
                    Text("Balances Page")
                }
            }
            .padding(.leading, 10)
            .padding(.top, 150)
            .font(.title)
            .fontWeight(.semibold)

            Spacer() // This pushes the content to the left
        }
    }
        

    enum Tab {
        case home
        case spending
        case budget
        case balances
    }
}

#Preview {
    MainTabView()
}
