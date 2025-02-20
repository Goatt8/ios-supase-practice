//
//  SupabaseManager+Auth.swift
//  MyLocalTodoApp-tutorial
//
//  Created by goat on 2/14/25.
//

import Foundation
import Supabase

extension SupabaseManager {
    
    struct CurrentUser : Decodable {
        let id : UUID
        let nickname: String
    }
    
    // 사용자 로그아웃
    func logoutUser() async throws {
        try await client.auth.signOut()
    }
    
    // 현재 접속사용자 조회
    func getCurrentUser() async throws -> CurrentUser? {
        guard let currentUser =  client.auth.currentUser  else {
            return nil
        }
        
        let user: CurrentUser = try await client
            .from("users")
            .select()
            .eq("id", value: currentUser.id)
            .limit(1)
            .single()
            .execute()
            .value
        
        return user
    }
    
    //로그인
    func longinUser(email:String, password: String) async throws {
        try await client.auth.signIn(
            email: email,
            password: password
        )
    }
    
    // 사용자 회원가입
    func registerUser(email: String, password: String, nickname: String) async throws {
        let authResponse = try await client.auth.signUp(
            email: email,
            password: password
        )
        
        struct AddUsers: Encodable {
            let id: UUID
            let nickname: String
        }
        
        let addUserData = AddUsers(id: authResponse.user.id, nickname: nickname)
        
        try await client
            .from("users")
            .insert(addUserData)
            .execute()
    }
}


