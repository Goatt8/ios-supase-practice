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
        
        let emailInput = emailTextField.text ?? ""
        let passwordInput = passwordTextField.text ?? ""
        let passwordConfirmInput = passwordConfirmTextField.text ?? ""
        let nicknameInput = nicknameTextField.text ?? ""
        
        Task {
            do {
                try await SupabaseManager.shared.registerUser(email: emailInput, password: passwordInput, nickname: nicknameInput)
            } catch {
                print("error")
            }
        }
        
        
    }
    
    @IBAction func handleMoveToLoginButton(_ sender: Any) {
        myNavtigationController?.setRoute(route: .login)
    }
    
}
