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
    
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

#Preview {
    UserDetailsView(showInitialAccountConnectionView: .constant(false))
}
