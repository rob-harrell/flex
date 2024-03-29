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
    @Binding var showMainTabView: Bool
    
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
                    // Perform action for checking accounts button
                }) {
                    Image(.addButton)
                }
            }
            .padding()
            
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
                    // Perform action for checking accounts button
                }) {
                    Image(.addButton)
                }
            }
            .padding()
            
            Spacer()
            
            Button(action: {
                plaidLinkViewModel.fetchLinkToken (userId: userViewModel.id) {
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
            .sheet(
                isPresented: $isPresentingLink,
                onDismiss: {
                    isPresentingLink = false
                    userViewModel.fetchBankConnectionsFromServer()
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
            .padding()
        
        }
    }
    
    private func createHandler() -> Result<Handler, Error> {
        guard let linkToken = plaidLinkViewModel.linkToken else {
            let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey : "Link token is not set"])
            return .failure(error)
        }
        let configuration = plaidLinkViewModel.createLinkConfiguration(linkToken: linkToken, userId: userViewModel.id)

        // This only results in an error if the token is malformed.
        return Plaid.create(configuration).mapError { $0 as Error }
    }
}

#Preview {
    AccountConnectionView(showMainTabView: .constant(false))
        .environmentObject(UserViewModel())
}
