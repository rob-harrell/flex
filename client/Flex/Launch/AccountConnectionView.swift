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
    @State private var isPresentingLink = false
    @State private var linkController: LinkController?
    
    var body: some View {
        VStack (alignment: .leading) {

            Text("Connect Accounts")
                .bold()
                .font(.title)
                .padding()
            
            Text("The more accounts you add, the more accurate\nyour budget will be.")
                .font(.callout)
                .padding(.horizontal)
                .foregroundColor(.slate500)
            
            HStack{
                Image(.lock)
                Text("Bank level security")
                    .font(.callout)
                    .fontWeight(.medium)
                Spacer()
            }
            .padding(.horizontal)
            
            HStack{
                Image(.checkingAccountsIcon)
                VStack (alignment: .leading) {
                    Text("Required")
                        .font(.callout)
                        .foregroundColor(.blue)
                    Text("Checking & Savings")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                Spacer()
                Button(action: {
                    plaidLinkViewModel.fetchLinkToken (userId: userViewModel.id, sessionToken: userViewModel.sessionToken) {
                        isPresentingLink = true
                    }
                }) {
                    Image(.addButton)
                }
            }
            .padding()

            ForEach(userViewModel.bankAccounts.filter { $0.subType == "checking" || $0.subType == "savings"}) { account in
                HStack {
                    AsyncImage(url: URL(string: "http://localhost:8000/assets/institution_logos/\(account.logoPath)")!) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                        case .success(let image):
                            image.resizable()
                        case .failure:
                            Image(systemName: "exclamationmark.triangle")
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
                .padding()
            }
            
            HStack{
                Image(.creditAccountsIcon)
                VStack (alignment: .leading) {
                    Text("Required")
                        .font(.callout)
                        .foregroundColor(.blue)
                    Text("Credit Cards")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                Spacer()
                Button(action: {
                    plaidLinkViewModel.fetchLinkToken (userId: userViewModel.id, sessionToken: userViewModel.sessionToken) {
                        isPresentingLink = true
                    }
                }) {
                    Image(.addButton)
                }
            }
            .padding()
            
            ForEach(userViewModel.bankAccounts.filter { $0.subType == "credit" }) { account in
                HStack {
                    AsyncImage(url: URL(string: "http://localhost:8000/assets/institution_logos/\(account.logoPath)")!) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                        case .success(let image):
                            image.resizable()
                        case .failure:
                            Image(systemName: "exclamationmark.triangle")
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(width: 40, height: 40)
                    // Rest of your code...
                    
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
                .padding()
            }
            
            Spacer()
            
            Button(action: {
                userViewModel.hasCompletedAccountCreation = true
                userViewModel.updateUserOnServer()
                budgetViewModel.fetchTransactionsFromServer(userId: userViewModel.id)
            }) {
                Text("Done")
                    .foregroundColor(userViewModel.canCompleteAccountCreation ? .white : .slate500)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(userViewModel.canCompleteAccountCreation ? Color.black : .slate200)
                    .cornerRadius(12)
            }
            .disabled(!userViewModel.canCompleteAccountCreation)
            .padding()
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
                self.userViewModel.fetchBankAccountsFromServer()
        }

        // This only results in an error if the token is malformed.
        return Plaid.create(configuration).mapError { $0 as Error }
    }
}

#Preview {
    AccountConnectionView()
        .environmentObject(UserViewModel())
}
