//
//  SettingsView.swift
//  Flex
//
//  Created by Rob Harrell on 1/28/24.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("General")) {
                    NavigationLink(destination: AccountSettingsView()) {
                        Text("Account Settings")
                    }
                    NavigationLink(destination: NotificationSettingsView()) {
                        Text("Notification Settings")
                    }
                }
                
                Section(header: Text("Connections")) {
                    NavigationLink(destination: BankConnectionsView()) {
                        Text("Bank Connections")
                    }
                }
            }
            .listStyle(GroupedListStyle())
            .navigationBarTitle("Settings", displayMode: .inline)
            .navigationBarItems(trailing: Button(action: {
                presentationMode.wrappedValue.dismiss() // Dismiss the view
            }) {
                Image(systemName: "xmark")
                    .imageScale(.large)
            })
        }
    }
}


#Preview {
    SettingsView()
}
