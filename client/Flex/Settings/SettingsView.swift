//
//  SettingsView.swift
//  Flex
//
//  Created by Rob Harrell on 1/28/24.
//

import SwiftUI
import LinkKit

struct SettingsView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @StateObject private var plaidLinkViewModel = PlaidLinkViewModel()
    @State private var isPresentingLink = false
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Account")) {
                    HStack {
                        Text("Email").fontWeight(.medium)
                        Spacer()
                        TextField("Email", text: $userViewModel.email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .frame(width: 250)
                    }
                    HStack {
                        Text("Username").fontWeight(.medium)
                        Spacer()
                        TextField("Username", text: $userViewModel.username)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 250)
                    }
                    HStack {
                        Text("Phone").fontWeight(.medium)
                        Spacer()
                        TextField("Userphone", text: $userViewModel.phone)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 250)
                    }
                }
                
                Section(header: Text("Bank Connections")) {
                    ForEach(userViewModel.bankConnections) { connection in
                        HStack {
                            Image(systemName: "circle.fill") // Replace with your logo
                                .resizable()
                                .frame(width: 40, height: 40)
                                .foregroundColor(.blue)
                            VStack(alignment: .leading) {
                                Text(connection.name)
                                    .font(.headline)
                                    .fontWeight(.medium)
                                Text(connection.bank_name)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text(connection.is_active ? "Active" : "Inactive")
                                    .font(.subheadline)
                                Text("Last updated: \(connection.updated)")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.vertical, 5)
                    }
                    Button(action: {
                        print("connection button tapped")
                        let userId = userViewModel.userId
                        plaidLinkViewModel.fetchLinkToken (userId: userId) {
                                isPresentingLink = true
                        }
                    }) {
                        Text("Add Connection")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                            .background(Color.clear)
                            .foregroundColor(.black)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray, lineWidth: 1)
                            )
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
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal)
                }
                
                Section(header: Text("Logout")){
                    Button(action: {
                        // Handle the button tap
                        print("Logout button tapped")
                    }) {
                        HStack {
                            Text("Sign out")
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                                .background(Color.clear)
                                .foregroundColor(.red)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal)
                    .padding(.vertical, -8)
                }
            }
            .listStyle(GroupedListStyle())
            .navigationBarTitle("Settings")
        }
        .onAppear {
            userViewModel.fetchUserInfo()
            userViewModel.fetchBankConnections()
        }
    }
  
    private func createHandler() -> Result<Handler, Error> {
        guard let linkToken = plaidLinkViewModel.linkToken else {
            let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey : "Link token is not set"])
            return .failure(error)
        }
        let configuration = plaidLinkViewModel.createLinkConfiguration(linkToken: linkToken, userId: userViewModel.userId)

        // This only results in an error if the token is malformed.
        return Plaid.create(configuration).mapError { $0 as Error }
    }
}


#Preview {
    SettingsView()
        .environmentObject(UserViewModel())
}
