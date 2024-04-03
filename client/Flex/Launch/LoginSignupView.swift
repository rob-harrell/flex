//
//  LoginSignupView.swift
//  Flex
//
//  Created by Rob Harrell on 3/22/24.
//

import SwiftUI

struct LoginSignupView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @State private var phoneNumber: String = ""
    @Binding var showOTPView: Bool
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Color.emerald300
                    .frame(height: geometry.size.height * (6.25/10))
                    .edgesIgnoringSafeArea(.top)
                
                
                VStack (alignment: .leading) {
                    //CTA
                    Text("Sign in or create")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                        .padding(.top, -40)

                    Text("a new account")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                        .padding(.top, -20)
                    
                    // Phone number input
                    HStack {
                        Text("🇺🇸")// Replace with your flag icon
                            .padding(.leading, 12)
                            .padding(.trailing, 4)
                        
                        Rectangle()
                            .fill(Color.gray)
                            .frame(width: 1, height: 56)
                        
                        TextField("Phone number", text: $phoneNumber)
                            .keyboardType(.phonePad)
                            .padding(.vertical)
                            .cornerRadius(8)
                    }
                    .frame(height: 56)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray, lineWidth: 1)
                    )
                    .padding(.horizontal)
                    
                    Text("We'll send a text to confirm your number. Standard ")
                        .font(.footnote)
                        .foregroundColor(.slate500)
                        .padding(.horizontal)
                    Text("messaging rates may apply")
                        .font(.footnote)
                        .foregroundColor(.slate500)
                        .padding(.horizontal)
                    
                    // Continue button
                    Button(action: {
                        userViewModel.phone = "+1\(phoneNumber)"
                        userViewModel.triggerTwilioOTP(phone: userViewModel.phone)
                        self.showOTPView = true
                    }) {
                        Text("Continue")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.black) 
                            .cornerRadius(8)
                    }
                    .padding()
                    
                    Text("By entering here I agree to all the language in Flex's ")
                        .font(.footnote)
                        .foregroundColor(.slate500)
                        .padding(.horizontal)
                        .padding(.top, -12)
                    Text("terms of service")
                        .underline()
                        .font(.footnote)
                        .foregroundColor(.slate500)
                        .font(.footnote)
                        .padding(.horizontal)
                }
            }
        }
    }
}

#Preview {
    LoginSignupView(showOTPView: .constant(false))
        .environmentObject(UserViewModel())
}
