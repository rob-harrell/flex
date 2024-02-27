//
//  SettingsView.swift
//  Flex
//
//  Created by Rob Harrell on 1/28/24.
//

import SwiftUI

struct SettingsView: View {
    // Sample bank connections
    @State private var bankConnections: [BankConnection] = [
        BankConnection(name: "My Account", institution: "Bank 1", status: "Connected", lastUpdated: Date()),
        BankConnection(name: "My Other Account", institution: "Bank 2", status: "Disconnected", lastUpdated: Date())
    ]
    @State private var email: String = ""
    @State private var username: String = ""
    @State private var userphone: String = ""
    @StateObject var viewModel: PlaidLinkViewModel
    let communicator: ServerCommunicator

    init(communicator: ServerCommunicator) {
        self.communicator = communicator
        self._viewModel = StateObject(wrappedValue: PlaidLinkViewModel(communicator: communicator))
    }

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Account")) {
                    HStack {
                        Text("Email").fontWeight(.medium)
                        Spacer()
                        TextField("Email", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .frame(width: 250)
                    }
                    HStack {
                        Text("Username").fontWeight(.medium)
                        Spacer()
                        TextField("Username", text: $username)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 250)
                    }
                    HStack {
                        Text("Phone").fontWeight(.medium)
                        Spacer()
                        TextField("Userphone", text: $userphone)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 250)
                    }
                }

                Section(header: Text("Bank Connections")) {
                    ForEach(bankConnections) { connection in
                        HStack {
                            Image(systemName: "circle.fill") // Replace with your logo
                                .resizable()
                                .frame(width: 40, height: 40)
                                .foregroundColor(.blue)
                            VStack(alignment: .leading) {
                                Text(connection.name)
                                    .font(.headline)
                                    .fontWeight(.medium)
                                Text(connection.institution)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text(connection.status)
                                    .font(.subheadline)
                                Text("Last updated: \(connection.lastUpdated, formatter: DateFormatter())")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.vertical, 5)
                    }
                    Button(action: {
                        print("connection button tapped")
                        viewModel.fetchLinkToken() {
                            viewModel.startLink()
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
            viewModel.fetchUserStatus()
        }
    }
}

struct BankConnection: Identifiable {
    var id = UUID()
    var name: String
    var institution: String
    var status: String
    var lastUpdated: Date
}

#Preview {
    SettingsView(communicator: ServerCommunicator())
}
