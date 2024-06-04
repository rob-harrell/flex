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
    //@State private var otp: [String] = Array(repeating: "", count: 4)
    //@State private var autoFillOTP: String = ""
    //@FocusState private var focus0: Bool
    //@FocusState private var focus1: Bool
    //@FocusState private var focus2: Bool
    //@FocusState private var focus3: Bool
    
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
            
            TextField("Enter OTP", text: $otp)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.black, lineWidth: 1)
                )
                .onChange(of: otp) {
                    if otp.count == 4 {
                        userViewModel.verifyTwilioOTP(code: otp, phone: userViewModel.phone) { result in
                            switch result {
                            case .success:
                                print("successfully verified OTP")
                            case .failure(let error):
                                // OTP is incorrect or an error occurred, show an error message
                                print("Failed to verify OTP: \(error)")
                                // Reset the OTP field
                                otp = ""
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                .padding(.bottom, 80)
            
            HStack {
                Text("Didn't receive a code?")
                    .font(.body)
                    .foregroundColor(.slate500)
                
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
            
            Spacer()
            
        }
    }
}

#Preview {
    OTPView()
        .environmentObject(UserViewModel())
}


    /*
    var body: some View {
        VStack (alignment: .leading) {
            TextField("", text: $autoFillOTP)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .hidden()
                .onChange(of: autoFillOTP) {
                    if autoFillOTP.count == 4 {
                        otp = Array(autoFillOTP).map { String($0) }
                        DispatchQueue.main.async {
                            focus3 = true
                        }
                    }
                }
            
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
                ForEach(0..<4) { index in
                    TextField("-", text: otpBinding(for: index))
                        .keyboardType(.numberPad)
                        .frame(width: 64, height: 64)
                        .multilineTextAlignment(.center)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                        .padding(4)
                        .focused(focusBinding(for: index))
                        .onChange(of: otp[index]) { 
                            let newValue = otp[index]
                            if newValue.count == 1 && index < 3 {
                                DispatchQueue.main.async {
                                    switch index {
                                    case 0: focus1 = true
                                    case 1: focus2 = true
                                    case 2: focus3 = true
                                    default: break
                                    }
                                }
                            } else if newValue.isEmpty && index > 0 {
                                DispatchQueue.main.async {
                                    switch index {
                                    case 1: focus0 = true
                                    case 2: focus1 = true
                                    case 3: focus2 = true
                                    default: break
                                    }
                                }
                            }
                            // Check if all fields are filled
                            if otp.allSatisfy({ !$0.isEmpty }) {
                                let enteredOTP = otp.joined()
                                userViewModel.verifyTwilioOTP(code: enteredOTP, phone: userViewModel.phone) { result in
                                    switch result {
                                    case .success:
                                        print("successfully verified OTP")
                                    case .failure(let error):
                                        // OTP is incorrect or an error occurred, show an error message
                                        print("Failed to verify OTP: \(error)")
                                        // Reset the OTP fields
                                        otp = Array(repeating: "", count: 4)
                                    }
                                }
                            }
                        }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 80)
            .onAppear {
                DispatchQueue.main.async {
                    focus0 = true
                }
            }
            
            HStack {
                Text("Didn't receive a code?")
                    .font(.body)
                    .foregroundColor(.slate500)
                
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
            
            Spacer()
            
        }
    }

    private func otpBinding(for index: Int) -> Binding<String> {
        Binding(
            get: { self.otp[index] },
            set: { newValue in
                    self.otp[index] = newValue
            }
        )
    }

    private func focusBinding(for index: Int) -> FocusState<Bool>.Binding {
        switch index {
        case 0: return $focus0
        case 1: return $focus1
        case 2: return $focus2
        case 3: return $focus3
        default: return $focus0
        }
    }
}
*/
     
