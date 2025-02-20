//
//  MainTabbarController.swift
//  MyLocalTodoApp-tutorial
//
//  Created by goat on 2025/02/06.
//

import Foundation
import UIKit

class MainTabbarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("")
        
        let mainStoryBoard = UIStoryboard(name: "Main", bundle: .main)
        let memoNavigationController = mainStoryBoard.instantiateInitialViewController()!
        
        memoNavigationController.tabBarItem = UITabBarItem(title: "메모", image: UIImage(systemName: "note.text"), tag: 0)
        
        let postVC = UIViewController()
        postVC.view.backgroundColor = .systemYellow
        postVC.tabBarItem = UITabBarItem(title: "게시글", image: UIImage(systemName: "list.bullet.clipboard.fill" ), tag: 1)
        
        let chatVC = UIViewController()
        chatVC.view.backgroundColor = .systemGreen
        chatVC.tabBarItem = UITabBarItem(title: "채팅", image: UIImage(systemName: "ellipses.bubble" ), tag: 2)
        
        
        self.setViewControllers([memoNavigationController,
                                 postVC,
                                 chatVC], animated: false)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute:{ [weak self] in
            
            guard let self = self else {
                return
            }
            
            AuthNavigationController.present(parent: self)
        })
        
        handleAuthStatusChange()
        
        Task {
            do {
                if let currentUser = try await  SupabaseManager.shared.getCurrentUser() {
                    print("\(currentUser)")
                } else {
                    AuthNavigationController.present(parent: self)
                }
            } catch {

            }
        }
       
        
    }  //viewDidLoad
    
    // 현재 접속상태 체크여부 -> 중요
    private func handleAuthStatusChange() {
        
        Task {
            // Using AsyncStream
            for await (event, session) in SupabaseManager.shared.client.auth.authStateChanges {
              print(event, session)
                
                switch event {
                case .signedIn:
                    print("로그인처리됨")
                    NotificationCenter.default.post(name: .dissmissAuth, object: nil)
                case .signedOut:
                    print("로그아웃처리됨")
                    AuthNavigationController.present(parent: self)
                default:
                    print("")
                }
            }
        }
    }
    
}
