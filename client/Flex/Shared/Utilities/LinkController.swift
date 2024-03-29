//
//  LinkKitSwiftUISupport.swift
//  LinkDemo-Swift
//
//  Copyright © 2020 Plaid Inc. All rights reserved.
//

import LinkKit
import SwiftUI

// Plaid currently doesn't fully support SwiftUI. Therefore, we need to create a bridge from SwiftUI to UIKit.
struct LinkController: UIViewControllerRepresentable {

    private let handler: Handler

    init(handler: Handler) {
        self.handler = handler
        print("LinkController initialized with handler: \(handler)") // Add this line
    }

    // MARK: UIViewControllerRepresentable

    final class Coordinator: NSObject {
        private let parent: LinkController
        private let handler: Handler

        fileprivate init(parent: LinkController, handler: Handler) {
            self.parent = parent
            self.handler = handler
            print("Coordinator initialized with parent: \(parent) and handler: \(handler)") // Add this line
        }

        fileprivate func present(_ handler: Handler, in viewController: UIViewController) {
            handler.open(presentUsing: .custom({ linkViewController in
                viewController.addChild(linkViewController)
                viewController.view.addSubview(linkViewController.view)
                linkViewController.view.translatesAutoresizingMaskIntoConstraints = false
                linkViewController.view.frame = viewController.view.bounds
                NSLayoutConstraint.activate([
                    linkViewController.view.centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor),
                    linkViewController.view.centerYAnchor.constraint(equalTo: viewController.view.centerYAnchor),
                    linkViewController.view.widthAnchor.constraint(equalTo: viewController.view.widthAnchor),
                    linkViewController.view.heightAnchor.constraint(equalTo: viewController.view.heightAnchor),
                ])
                linkViewController.didMove(toParent: viewController)
            }))
        }
    }

    func makeCoordinator() -> Coordinator {
        print("makeCoordinator called") // Add this line
        return Coordinator(parent: self, handler: handler)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        print("makeUIViewController called") // Add this line
        let viewController = UIViewController()
        context.coordinator.present(handler, in: viewController)
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        print("updateUIViewController called") // Add this line
        // Empty implementation
    }
}
