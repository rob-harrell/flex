//
//  UserDetailsView.swift
//  Flex
//
//  Created by Rob Harrell on 3/22/24.
//

import SwiftUI

struct UserDetailsView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @Binding var showInitialAccountConnectionView: Bool
    
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var birthday: Date = Date()
    
    var body: some View {
        // Profile picture placeholder
        Image(systemName: "person.crop.circle.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 80, height: 80)
            .padding(.top, 50)

        Text("Welcome! Let's create your account")
            .font(.title)
            .fontWeight(.semibold)
            .padding()

        // Name Input Fields
        VStack {
            TextField("First name", text: $firstName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding([.horizontal, .bottom])

            TextField("Last name", text: $lastName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding([.horizontal, .bottom])
        }
        
        // Birthday Picker
        DatePicker("Birthday", selection: $birthday, displayedComponents: .date)
            .datePickerStyle(GraphicalDatePickerStyle())
            .padding()
        
        Button(action: {
            userViewModel.updateUser(userViewModel)
            showInitialAccountConnectionView = true
        }) {
            Text("Create Account")
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.black)
                .cornerRadius(8)
        }
        .padding(.horizontal)
    }
}

#Preview {
    UserDetailsView(showInitialAccountConnectionView: .constant(false))
}
