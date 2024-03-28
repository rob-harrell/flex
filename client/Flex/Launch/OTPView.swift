//
//  OTPView.swift
//  Flex
//
//  Created by Rob Harrell on 3/22/24.
//

import SwiftUI

struct OTPView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @State private var otp: String = ""
    @State private var isExistingUser: Bool = false
    @Binding var showUserDetailsView: Bool
    @Binding var showMainTabView: Bool
    
    var body: some View {
        VStack (alignment: .leading) {
            Image(.phoneIcon)
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .padding(.horizontal)
                .padding(.bottom, 4)
                .padding(.top, 40)
            
            Text("Enter the 4-digit code sent")
                .font(.title)
                .bold()
                .padding(.horizontal)
            
            Text("to \(userViewModel.phone)")
                .font(.title)
                .bold()
                .padding(.horizontal)
            
            HStack {
                ForEach(0..<4, id: \.self) { index in
                    OTPDigitView(digit: otp.count > index ? String(otp[otp.index(otp.startIndex, offsetBy: index)]) : "")
                }
            }
            .padding(.horizontal)
            .onChange(of: otp) { oldValue, newValue in
                if newValue.count == 4 {
                    userViewModel.verifyTwilioOTP(code: newValue, forPhone: userViewModel.phone) { isExistingUser in
                        self.isExistingUser = isExistingUser
                        // Add your logic here for what to do after the OTP is verified
                    }
                }
            }
            
            HStack {
                Text("Didn't receive a code?")
                    .font(.body)
                    .foregroundColor(.gray)
                
                Button(action: {
                    userViewModel.triggerTwilioOTP(phone: userViewModel.phone)
                }) {
                    Text("Resend code")
                        .font(.body)
                        .foregroundColor(.black)
                        .underline()
                }
            }
            .padding(.horizontal)
            .padding(.top, 240)

            Spacer()
        }
    }
}

struct OTPDigitView: View {
    var digit: String
    
    var body: some View {
        Text(digit.isEmpty ? "-" : digit)
            .font(.title)
            .foregroundColor(digit.isEmpty ? .gray : .black)
            .frame(width: 64, height: 64)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray, lineWidth: 1)
            )
            .padding(4)
    }
}

#Preview {
    OTPView(showUserDetailsView: .constant(false), showMainTabView: .constant(false))
        .environmentObject(UserViewModel())
}
