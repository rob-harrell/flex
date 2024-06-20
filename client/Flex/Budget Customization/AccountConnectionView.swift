//
//  InitialAccountConnectionView.swift
//  Flex
//
//  Created by Rob Harrell on 3/24/24.
//

import SwiftUI
import LinkKit

struct AccountConnectionView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @EnvironmentObject var plaidLinkViewModel: PlaidLinkViewModel
    @EnvironmentObject var budgetViewModel: BudgetViewModel
    @EnvironmentObject var dateViewModel: DateViewModel
    @State private var isPresentingLink = false
    @State private var linkController: LinkController?
    
    let nextAction: () -> Void
    let backAction: () -> Void
    
    var body: some View {
        HStack {
            Button(action: {
                self.backAction()
            }) {
                Image(systemName: "chevron.left")
                    .resizable()
                    .frame(width: 12, height: 21)
                    .fontWeight(.semibold)
            }
            .padding(.vertical, 4)
            .padding(.bottom, 4)
            Spacer()
        }
        
        ScrollView {
            VStack (alignment: .leading) {
                Text("Next, connect your spending\ncards and accounts")
                    .font(.system(size: 24))
                    .fontWeight(.semibold)
                    .padding(.bottom, 8)
                    .lineSpacing(4.0)
                
                Text("The more accounts you add, the more accurate\nyour budget will be.")
                    .font(.system(size: 16))
                    .foregroundColor(Color.slate500)
                    .padding(.bottom, 16)
                    .lineSpacing(4.0)

                Text("Bank accounts")
                    .font(.system(size: 18))
                    .fontWeight(.semibold)
                    .padding(.bottom, 12)
                
                Button(action: {
                    plaidLinkViewModel.fetchLinkToken (userId: userViewModel.id, sessionToken: userViewModel.sessionToken) {
                        isPresentingLink = true
                    }
                }) {
                    HStack {
                        Image(.checkingAccountsIcon)
                            .resizable()
                            .frame(width: 40, height: 40)
                        Text("Connect a bank account")
                            .font(.system(size: 16))
                            .fontWeight(.medium)
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                }
                .padding(.bottom, 4)
                
                ForEach(userViewModel.bankAccounts.filter { $0.subType == "checking" || $0.subType == "savings"}) { account in
                    HStack {
                        AsyncImage(url: URL(string: "\(account.logoURL)")!) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                            case .success(let image):
                                image.resizable()
                            case .failure:
                                Image(.checkingAccountsIcon)
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .frame(width: 40, height: 40)
                        
                        VStack(alignment: .leading) {
                            Text(account.subType)
                                .font(.headline)
                                .fontWeight(.medium)
                            Text(account.bankName)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text(account.isActive ? "Active" : "Inactive")
                                .font(.subheadline)
                        }
                    }
                    .padding(.bottom, 4)
                }
                .padding(.bottom, 16)
                
                Text("Credit cards")
                    .font(.system(size: 18))
                    .fontWeight(.semibold)
                    .padding(.bottom, 12)
                
                Button(action: {
                    plaidLinkViewModel.fetchLinkToken (userId: userViewModel.id, sessionToken: userViewModel.sessionToken) {
                        isPresentingLink = true
                    }
                }) {
                    Image(.creditAccountsIcon)
                        .resizable()
                        .frame(width: 40, height: 40)
                    Text("Connect a credit card")
                        .font(.system(size: 16))
                        .fontWeight(.medium)
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .padding(.bottom, 4)
                
                
                ForEach(userViewModel.bankAccounts.filter { $0.subType == "credit card" }) { account in
                    HStack {
                        AsyncImage(url: URL(string: "\(account.logoURL)")!) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                            case .success(let image):
                                image.resizable()
                            case .failure:
                                Image(.creditAccountsIcon)
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .frame(width: 40, height: 40)
                        
                        VStack(alignment: .leading) {
                            Text(account.subType)
                                .font(.headline)
                                .fontWeight(.medium)
                            Text(account.bankName)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text(account.isActive ? "Active" : "Inactive")
                                .font(.subheadline)
                        }
                    }
                    .padding(.bottom, 4)
                }
            }
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
        
        Spacer()
        
        Button(action: {
            userViewModel.hasCompletedAccountCreation = true
            nextAction()
            userViewModel.updateUserOnServer()
        }) {
            Text("Next")
                .font(.headline)
                .foregroundColor(userViewModel.hasCreditCard ? .white : .slate500)
                .frame(maxWidth: .infinity)
                .padding()
                .background(userViewModel.hasCreditCard ? Color.black : .slate200)
                .cornerRadius(12)
        }
        .disabled(!userViewModel.hasCreditCard)
        .padding(.top)
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
                    self.budgetViewModel.fetchNewTransactionsFromServer(userId: self.userViewModel.id) { success in
                        if success {
                            dateViewModel.updateAllTransactionDates()
                            print("Successfully fetched new transactions for user \(self.userViewModel.id)")
                        } else {
                            print("Failed to fetch new transactions for user \(self.userViewModel.id)")
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
    AccountConnectionView(nextAction: {}, backAction: {})
        .environmentObject(UserViewModel())
}


