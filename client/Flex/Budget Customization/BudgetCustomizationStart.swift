//
//  BuildBudgetStart.swift
//  Flex
//
//  Created by Rob Harrell on 6/26/24.
//

import SwiftUI
import LinkKit

struct BudgetCustomizationStart: View {
    @EnvironmentObject var budgetViewModel: BudgetViewModel
    @EnvironmentObject var dateViewModel: DateViewModel
    @EnvironmentObject var plaidLinkViewModel: PlaidLinkViewModel
    @EnvironmentObject var userViewModel: UserViewModel
    @State private var isPresentingLink = false
    @State private var linkController: LinkController?
    let nextAction: () -> Void
    
    var body: some View {
        VStack (alignment: .leading) {
            Text("Let's build your budget! Set\nyour monthly income to start")
                .font(.system(size: 24))
                .fontWeight(.semibold)
                .padding(.bottom, 28)
                .padding(.top, 8)
            
            Text("Add income sources")
                .font(.system(size: 18))
                .fontWeight(.semibold)
                .padding(.bottom, 12)
            Button(action: {
                plaidLinkViewModel.fetchLinkToken (userId: userViewModel.id, sessionToken: userViewModel.sessionToken) {
                    isPresentingLink = true
                }
            }) {
                HStack {
                    Image(.bankAccount)
                        .resizable()
                        .frame(width: 64, height: 64)
                    Text("Connect a bank account")
                        .font(.system(size: 16))
                        .fontWeight(.medium)
                    Spacer()
                    Image(systemName: "chevron.right")
                }
            }
            .padding(.bottom, 8)
            
            Button(action: {
                self.nextAction()
            }) {
                HStack {
                    Image(.pen)
                        .resizable()
                        .frame(width: 64, height: 64)
                    Text("Add income manually")
                        .font(.system(size: 16))
                        .fontWeight(.medium)
                    Spacer()
                    Image(systemName: "chevron.right")
                }
            }
            .padding(.bottom, 4)
            
            Spacer()
        }
        .sheet(
            isPresented: $isPresentingLink,
            onDismiss: {
                isPresentingLink = false
            },
            content: {
                let createResult = createHandler()
                switch createResult {
                case .failure(let createError):
                    Text("Link Creation Error: \(createError.localizedDescription)")
                        .font(.title2)
                case .success(let handler):
                    LinkController(handler: handler)
                }
            }
        )
    }
    
    private func createHandler() -> Result<Handler, Error> {
        guard let linkToken = plaidLinkViewModel.linkToken else {
            let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey : "Link token is not set"])
            return .failure(error)
        }
        let configuration = plaidLinkViewModel.createLinkConfiguration(linkToken: linkToken, userId: userViewModel.id, sessionToken: userViewModel.sessionToken) {
            self.userViewModel.fetchBankAccountsFromServer() { success in
                if success {
                    print("Successfully fetched bank accounts for user \(self.userViewModel.id)")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 120) {
                        self.budgetViewModel.fetchNewTransactionsFromServer(userId: self.userViewModel.id) { success in
                            if success {
                                print("Successfully fetched new transactions for user \(self.userViewModel.id)")
                                self.dateViewModel.updateAllTransactionDates()
                                self.budgetViewModel.calculateSelectedMonthBudgetMetrics(for: dateViewModel.selectedMonth, monthlyIncome: userViewModel.monthlyIncome, monthlyFixedSpend: userViewModel.monthlyFixedSpend)
                                self.budgetViewModel.calculateRecentBudgetStats()
                                nextAction()
                            }
                            else {
                                print("Failed to fetch new transactions for user in second call \(self.userViewModel.id)")
                            }
                        }
                    }
                } else {
                    print("Failed to fetch bank accounts for user \(self.userViewModel.id)")
                }
            }
        }

        // This only results in an error if the token is malformed.
        return Plaid.create(configuration).mapError { $0 as Error }
    }
    
    
}

#Preview {
    BudgetCustomizationStart(nextAction: {})
}
