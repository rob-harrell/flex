//
//  PlaidLinkViewModel.swift
//  Flex
//
//  Created by Rob Harrell on 2/25/24.
//

import Foundation
import LinkKit

class PlaidLinkViewModel: ObservableObject {
    var linkToken: String?
    var onLinkFinished: (() -> Void)?
    @Published var isLinkActive = false

    func fetchLinkToken(userId: Int64, sessionToken: String, completion: @escaping () -> Void) {
        ServerCommunicator.shared.callMyServer(path: "/plaid/generate_link_token", httpMethod: .post, params: ["userId": userId], sessionToken: sessionToken) { (result: Result<LinkTokenCreateResponse, ServerCommunicator.Error>) in
            switch result {
                case .success(let response):
                    self.linkToken = response.linkToken
                    if let linkToken = self.linkToken {
                            print("Fetched link token: \(linkToken)")
                        }
                    completion()
                case .failure(let error):
                    print(error)
            }
        }
    }

    func createLinkConfiguration(linkToken: String, userId: Int64, sessionToken: String, completion: @escaping () -> Void) -> LinkTokenConfiguration {
        var linkTokenConfig = LinkTokenConfiguration(token: linkToken) { success in
            print("Link was finished successfully! \(success)")
            self.exchangePublicTokenForAccessToken(success.publicToken, userId: userId, sessionToken: sessionToken) {
                //DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
                    completion()
                //}
            }
            self.onLinkFinished?()
            DispatchQueue.main.async {
                self.isLinkActive = false
            }
        }
        linkTokenConfig.onExit = { linkEvent in
            print("User exited Link early \(linkEvent)")
            DispatchQueue.main.async {
                self.isLinkActive = false
            }
        }
        //linkTokenConfig.onEvent = { linkEvent in
        //    print("Hit an event \(linkEvent.eventName)")
        //}
        
        // Print out a message to check if the LinkTokenConfiguration is created correctly
        print("LinkTokenConfiguration created with linkToken: \(linkToken)")
        
        return linkTokenConfig
    }

    private func exchangePublicTokenForAccessToken(_ publicToken: String, userId: Int64, sessionToken: String, completion: @escaping () -> Void) {
        ServerCommunicator.shared.callMyServer(path: "/plaid/swap_public_token", httpMethod: .post, params: ["public_token": publicToken, "userId": userId], sessionToken: sessionToken) { (result: Result<SwapPublicTokenResponse, ServerCommunicator.Error>) in
            switch result {
                case .success:
                    DispatchQueue.main.async {
                        self.isLinkActive = false
                        completion()
                    }
                case .failure(let error):
                    print("Got an error \(error)")
            }
        }
    }
}
