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

    var body: some View {
        VStack (alignment: .leading) {
            
            HStack {
                Spacer()
                Button(action: {
                    userViewModel.smsNotificationsEnabled = false
                    userViewModel.pushNotificationsEnabled = false
                    userViewModel.hasCompletedNotificationSelection = true
                    userViewModel.updateUserOnServer()
                }) {
                    Text("Skip")
                        .font(.body)
                        .foregroundColor(.slate500)
                       
                }
                .padding()
            }
            
            Text("Turn on\nnotifications?")
                .font(.title)
                .fontWeight(.bold)
                .padding(.horizontal)
                .padding(.top)
            
            Text("We promise, we'll only notify you about important things, like issues with your bank connections")
                .font(.body)
                .padding(.horizontal)
                .padding(.top, 4)
                .foregroundColor(.slate500)

            Spacer()
            
            HStack {
                Text("Allow us to send you offers and important\ninfo via SMS")
                    .font(.body)
                    .foregroundColor(.slate500)
                Spacer()
                CheckboxView(isChecked: $isCheckboxChecked)
            }
            .padding(.horizontal)

            Button(action: {
                userViewModel.smsNotificationsEnabled = isCheckboxChecked
                userViewModel.hasCompletedNotificationSelection = true

                let center = UNUserNotificationCenter.current()
                center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                    DispatchQueue.main.async {
                        if granted {
                            print("Notifications permission granted.")
                            userViewModel.pushNotificationsEnabled = true
                        } else {
                            print("Notifications permission denied because: \(error?.localizedDescription ?? "User denied permission.")")
                            userViewModel.pushNotificationsEnabled = false
                        }
                        userViewModel.updateUserOnServer()
                        userViewModel.hasCompletedNotificationSelection = true
                    }
                }
            }) {
                Text("Yes, notify me")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.black)
                    .cornerRadius(12)
            }
            .padding()
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
                .frame(width: 24, height: 24) // Adjust size as needed
                .background(isChecked ? Color.white : Color.black)
                .cornerRadius(4) // Adjust as needed
        }
    }
}

#Preview {
    NotificationView()
        .environmentObject(UserViewModel())
}
