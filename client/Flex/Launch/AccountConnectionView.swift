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
    @State private var isPresentingLink = false
    @State private var linkController: LinkController?
    
    var body: some View {
        VStack (alignment: .leading) {
            
            HStack {
                Text("Connect Accounts")
                    .bold()
                    .font(.title)
                    .padding(.top, 100)
                    .padding(.leading)
                    .padding(.bottom, 6)
                
                Spacer()
            }
            
            Text("The more accounts you add, the more accurate")
                .font(.callout)
                .padding(.horizontal)
                .padding(.bottom, 1)
                .foregroundColor(.slate500)
            Text("your budget will be.")
                .font(.callout)
                .padding(.horizontal)
                .foregroundColor(.slate500)
                .padding(.bottom, 4)
            
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
                    Text("Checking Accounts")
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

            ForEach(userViewModel.bankAccounts.filter { $0.subType == "checking" }) { account in
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
                plaidLinkViewModel.fetchLinkToken (userId: userViewModel.id, sessionToken: userViewModel.sessionToken) {
                        isPresentingLink = true
                }
            }) {
                Text("+ Connect Account")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .cornerRadius(8)
            }
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
