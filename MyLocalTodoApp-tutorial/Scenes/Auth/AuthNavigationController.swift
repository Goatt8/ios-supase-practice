//
//  AuthNavigationController.swift
//  MyLocalTodoApp-tutorial
//
//  Created by goat on 2/14/25.
//

import Foundation
import UIKit

extension Notification.Name {
    static let dissmissAuth = Notification.Name("dissmissAuth")
}

class AuthNavigationController: UINavigationController {
    
    enum Route {
        case login
        case register
        
        var viewController: UIViewController {
            switch self {
            case .login:
                return LoginVC()
            case .register:
                return RegisterVC()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotification(_:)), name: .dissmissAuth, object: nil)
    }
    
    @objc func handleNotification(_ sender: Notification) {
        guard sender.name == .dissmissAuth else {
            return
        }
        
        self.dismiss(animated: true)
    }
    
    func setRoute(route: Route) {
        switch route {
        case .login:
            
            let loginVC = LoginVC()
            self.setViewControllers([loginVC], animated: true)
            
        case .register:
            
            let registerVC = RegisterVC()
            self.setViewControllers([registerVC], animated: true)
        }
    }
    
    class func present(parent: UIViewController, initialRoute: Route = .login) {
        let authVC = AuthNavigationController(rootViewController: initialRoute.viewController)
        
        
        authVC.modalPresentationStyle = .fullScreen
        
        parent.present(authVC, animated: true)
    }
    
    
}
