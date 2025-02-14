//
//  RegisterVC.swift
//  MyLocalTodoApp-tutorial
//
//  Created by goat on 2/14/25.
//

import Foundation
import UIKit

class RegisterVC: UIViewController {
    
    var myNavtigationController: AuthNavigationController? {
        return self.navigationController as? AuthNavigationController
    }
    
    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var passwordConfirmTextField: UITextField!

    @IBOutlet weak var nicknameTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "로그인"
        
    }
    
    @IBAction func handleRegisterButton(_ sender: Any) {
    }
    
    @IBAction func handleMoveToLoginButton(_ sender: Any) {
        myNavtigationController?.setRoute(route: .login)
    }
    
}
