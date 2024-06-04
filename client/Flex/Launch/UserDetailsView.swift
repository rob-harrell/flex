//
//  UserDetailsView.swift
//  Flex
//
//  Created by Rob Harrell on 3/22/24.
//

import SwiftUI

struct UserDetailsView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var birthday: String = ""
    @State private var showingAlert = false
    @State private var isTextFieldFocused: Bool = false
    
    var body: some View {
        VStack(alignment: .leading) {
            // Profile picture placeholder
            if !isTextFieldFocused {
                Image(.userIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .padding(.horizontal)
                    .padding(.bottom, 4)
            }

            Text("Welcome! Let's create\nyour account")
                .font(.title)
                .fontWeight(.bold)
                .padding(.horizontal)
                .padding(.bottom)
                .transition(.identity)

            // Name Input Fields
            Text("Name")
                .font(.headline)
                .fontWeight(.medium)
                .padding(.horizontal)
            
            VStack {
                TextField("First name", text: $firstName, onEditingChanged: { isEditing in
                    isTextFieldFocused = isEditing
                })
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                    .foregroundColor(.black)

                TextField("Last name", text: $lastName, onEditingChanged: {isEditing in
                    isTextFieldFocused = isEditing
                })
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding([.horizontal, .bottom])
                    .foregroundColor(.black)
            }
            
            // Birthday Input Field
            Text("Birthday")
                .font(.headline)
                .fontWeight(.medium)
                .padding(.horizontal)
            
            TextField("MM/DD/YYYY", text: $birthday, onEditingChanged: {isEditing in
                isTextFieldFocused = isEditing
            })
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding([.horizontal, .bottom])
                .foregroundColor(.black)
            
            
        }
        .padding(.top, 40)
        
        Spacer()
        
        Button(action: {
            if isValidDate(dateString: birthday) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    userViewModel.firstName = firstName
                    userViewModel.lastName = lastName
                    userViewModel.birthDate = birthday
                    userViewModel.hasEnteredUserDetails = true
                    print("updated hasEnteredUserDetails: \(userViewModel.hasEnteredUserDetails)")
                    userViewModel.updateUserOnServer()
                }
            } else {
                showingAlert = true
            }
        }) {
            Text("Create Account")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.black)
                .cornerRadius(12)
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
    UserDetailsView()
        .environmentObject(UserViewModel())
}
