//
//  UserDetailsView.swift
//  Flex
//
//  Created by Rob Harrell on 3/22/24.
//

import SwiftUI

struct UserDetailsView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @Binding var showAccountConnectionView: Bool
    
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var birthday: String = ""
    @State private var showingAlert = false
    
    var body: some View {
        VStack(alignment: .leading) {
            // Profile picture placeholder
            Image(.userIcon)
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .padding(.horizontal)
                .padding(.bottom, 4)
                .padding(.top, 40)

            Text("Welcome! Let's create your account")
                .font(.title)
                .fontWeight(.bold)
                .padding(.horizontal)
                .padding(.bottom)

            // Name Input Fields
            Text("Name")
                .font(.headline)
                .fontWeight(.medium)
                .padding(.horizontal)
            
            VStack {
                TextField("First name", text: $firstName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                    .foregroundColor(.black)

                TextField("Last name", text: $lastName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding([.horizontal, .bottom])
                    .foregroundColor(.black)
            }
            
            // Birthday Input Field
            Text("Birthday")
                .font(.headline)
                .fontWeight(.medium)
                .padding(.horizontal)
            
            TextField("MM/DD/YYYY", text: $birthday)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding([.horizontal, .bottom])
                .foregroundColor(.black)
            
            
        }
        
        Spacer()
        
        Button(action: {
            if isValidDate(dateString: birthday) {
                userViewModel.firstName = firstName
                userViewModel.lastName = lastName
                userViewModel.birthDate = birthday
                userViewModel.updateUser()
                showAccountConnectionView = true
            } else {
                showingAlert = true
            }
        }) {
            Text("Create Account")
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.black)
                .cornerRadius(8)
        }
        .alert(isPresented: $showingAlert) {
            Alert(title: Text("Invalid Date"), message: Text("Please enter a valid date in the format MM/DD/YYYY"), dismissButton: .default(Text("OK")))
        }
        .padding()
    }
    
    func isValidDate(dateString: String) -> Bool {
        let dateFormatterGet = DateFormatter()
        dateFormatterGet.dateFormat = "MM/dd/yyyy"

        if dateFormatterGet.date(from: dateString) != nil {
            return true
        } else {
            return false
        }
    }
}

#Preview {
    UserDetailsView(showAccountConnectionView: .constant(false))
        .environmentObject(UserViewModel())
}
