//
//  InitialAccountConnectionView.swift
//  Flex
//
//  Created by Rob Harrell on 3/24/24.
//

import SwiftUI

struct AccountConnectionView: View {
    @EnvironmentObject var userViewModel: UserViewModel
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
                //do action
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
    }
}

#Preview {
    AccountConnectionView(showMainTabView: .constant(false))
        .environmentObject(UserViewModel())
}
