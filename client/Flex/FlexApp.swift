//
//  FlexApp.swift
//  Flex
//
//  Created by Rob Harrell on 1/27/24.
//

import SwiftUI

@main
struct FlexApp: App {
    let communicator = ServerCommunicator()
    
    var body: some Scene {
        WindowGroup {
            MainTabView(communicator: communicator)
        }
    }
}
