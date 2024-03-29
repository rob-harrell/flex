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
    @EnvironmentObject var plaidLinkViewModel: PlaidLinkViewModel
    @State private var isPresentingLink = false
    @State private var linkController: LinkController?
    @State private var birthDate = Date()
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Account")) {
                    HStack {
                        Text("First Name").fontWeight(.medium)
                        Spacer()
                        TextField("First Name", text: $userViewModel.firstName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .frame(width: 250)
                    }
                    HStack {
                        Text("Last Name").fontWeight(.medium)
                        Spacer()
                        TextField("Last Name", text: $userViewModel.lastName)
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
                    HStack {
                        Text("Birth Date").fontWeight(.medium)
                        Spacer()
                        DatePicker("Birthdate", selection: $birthDate, displayedComponents: .date)
                            .datePickerStyle(GraphicalDatePickerStyle())
                            .frame(width: 250)
                    }
                }
                
                Section(header: Text("Bank Connections")) {
                    ForEach(userViewModel.bankConnections) { connection in
                        HStack {
                            AsyncImage(url: URL(string: "http://localhost:8000/assets/institution_logos/\(connection.logoPath)")!) { phase in
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
                                Text(connection.name)
                                    .font(.headline)
                                    .fontWeight(.medium)
                                Text(connection.bankName)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text(connection.isActive ? "Active" : "Inactive")
                                    .font(.subheadline)
                            }
                        }
                        .padding(.vertical, 5)
                    }
                    Button(action: {
                        print("connection button tapped")
                        plaidLinkViewModel.fetchLinkToken (userId: userViewModel.id) {
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
            print("got to th")
            //userViewModel.fetchUserInfoFromCoreData()
            userViewModel.fetchBankConnectionsFromServer()
            print("got here")
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
    SettingsView()
        .environmentObject(UserViewModel())
        .environmentObject(PlaidLinkViewModel())
}
