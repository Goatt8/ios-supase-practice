//
//  LoginVC.swift
//  MyLocalTodoApp-tutorial
//
//  Created by goat on 2/14/25.
//

import Foundation
import UIKit

class LoginVC: UIViewController {
    
    var myNavtigationController: AuthNavigationController? {
        return self.navigationController as? AuthNavigationController
    }
    
    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet weak var passwordTextField: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "로그인"
    }
    
    
    @IBAction func handleLoginButton(_ sender: Any) {
    }
    
    @IBAction func handleMoveToRegisterButton(_ sender: Any) {
        self.myNavtigationController?.setRoute(route: .register)
    }
    
}
