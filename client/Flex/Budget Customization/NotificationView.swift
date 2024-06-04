//
//  NotificationView.swift
//  Flex
//
//  Created by Rob Harrell on 4/4/24.
//

import SwiftUI
import UserNotifications

struct NotificationView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @State private var isCheckboxChecked = true
    @State private var isRequestingAuthorization = false
    
    let doneAction: () -> Void
    let backAction: () -> Void

    var body: some View {
        VStack (alignment: .leading) {
            Image(.notifications)
                .padding(.bottom, 8)
            
            Text("Turn on\nnotifications?")
                .font(.title)
                .fontWeight(.semibold)
            
            Text("We promise, we'll only notify you about things that need attention.")
                .font(.system(size: 16))
                .foregroundColor(.slate500)
                .padding(.top, 4)
                .padding(.bottom, 8)
                .lineSpacing(4.0)
            
            HStack {
                Text("Allow us to send you offers and\nimportant info via SMS")
                    .font(.system(size: 16))
                    .foregroundColor(.slate500)
                    .lineSpacing(4.0)
                Spacer()
                CheckboxView(isChecked: $isCheckboxChecked)
            }
            .padding(.bottom, 20)

            
            Image(.notificationExamples)
                .resizable()
                .scaledToFit()
            
            Spacer()
            
            Button(action: {
                isRequestingAuthorization = true
                userViewModel.smsNotificationsEnabled = isCheckboxChecked
                let center = UNUserNotificationCenter.current()
                center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                    DispatchQueue.main.async {
                        isRequestingAuthorization = false
                        if granted {
                            print("Notifications permission granted.")
                            userViewModel.pushNotificationsEnabled = true
                        } else {
                            print("Notifications permission denied because: \(error?.localizedDescription ?? "User denied permission.")")
                            userViewModel.pushNotificationsEnabled = false
                        }
                        userViewModel.updateUserOnServer()
                        doneAction()
                    }
                }
            }) {
                Text("Yes, notify me")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.black)
                    .cornerRadius(12)
            }
            .padding(.top)
            .disabled(isRequestingAuthorization)
            
            Button(action: {
                doneAction()
                userViewModel.updateUserOnServer()
            }) {
                Text("Not right now")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.slate200)
                    .cornerRadius(12)
            }
        }
    }
}

struct CheckboxView: View {
    @Binding var isChecked: Bool

    var body: some View {
        Button(action: {
            isChecked.toggle()
        }) {
            Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                .resizable()
                .frame(width: 24, height: 24)
                .foregroundColor(isChecked ? .black : .black)
                .background(isChecked ? Color.white : Color.white)
                .cornerRadius(4)
        }
    }
}

#Preview {
    NotificationView(doneAction: {}, backAction: {})
        .environmentObject(UserViewModel())
}
