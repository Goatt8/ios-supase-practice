//
//  SupanaseManager+Memo.swift
//  MyLocalTodoApp-tutorial
//
//  Created by goat on 2/7/25.
//

import Foundation

extension SupabaseManager {
    
    func fetchMemos(searchTerm: String) async throws -> [MemoServerEntity]{
        
        let fetchedEntities: [MemoServerEntity] = try await client
            .from("memos")
            .select()
            .textSearch("content", query: searchTerm)
            .execute()
            .value
        print(#fileID, #function, #line, "- fetchedEntities: \(fetchedEntities.count)")
        return fetchedEntities
    }
    
    func fetchMemos(page: Int, perPage: Int) async throws -> (data: [MemoServerEntity], lastPage: Int){
        
        var fromIndex = 0
        
        if page > 1 {
            fromIndex = (page - 1) * perPage
        }
        
        let toIndex = fromIndex + (perPage - 1)
        
        async let _totalCount = client
          .from("memos")
          .select("*", head: true, count: .exact)
          .execute()
          .count ?? 0
        
        async let _fetchedEntities: [MemoServerEntity] = client
          .from("memos")
          .select()
          .range(from: fromIndex, to: toIndex)
          .execute()
          .value
        
        let (fetchedEntities, totalCount) : ([MemoServerEntity], Int) = try await (_fetchedEntities, _totalCount)
        
        let value = Float(Float(totalCount) / Float(perPage))
        
        let lastPage = Int(ceil(value))
        
        return (data: fetchedEntities, lastPage: lastPage)
    }
    
    //    // CREATE
    func createNewMemo(content: String, isDone: Bool) async throws {
        
        struct AddMemo : Encodable {
            let content: String
            let is_done: Bool
            let user_id: UUID
        }
        
//        let newMemoEntity = MemoServerEntity(content: content, isDone: isDone)
        guard let currentUserId = client.auth.currentUser?.id else {
            return
        }
        
        let newMemo = AddMemo(content: content, is_done: isDone, user_id: currentUserId)
        
        try await client
            .from("memos")
            .insert(newMemo)
            .execute()
        
    }
    
    // READ - 조회
    func fetchAllMemos() async throws -> [MemoServerEntity]{
        let fetchedEntities: [MemoServerEntity] = try await client
            .from("memos")
            .select()
            .execute()
            .value
        print(#fileID, #function, #line, "- fetchedEntities: \(fetchedEntities.count)")
        return fetchedEntities
    }
    
    
    // DELETE :ID
    func deleteAMemo(id: String) async throws {
        
        try await client
            .from("memos")
            .delete()
            .eq("id", value: id)
            .execute()
    }
    
    // UPDATE :ID ?content=String ?isDone=Bool
    func updateAMemo(id: String,
                     content: String?,
                     isDone: Bool?) async throws{
        
        var updatingValue : [String : String] = [:]
        
        if let content = content {
            updatingValue["content"] = content
        }
        
        if let isDone = isDone {
            updatingValue["is_done"] = "\(isDone)"
        }
        
        
        try await client
            .from("memos")
            .update(updatingValue)
            .eq("id", value: id)
            .execute()
        
    }
    
    func deleteAllMemos() async throws{
        
        // 1.
        // 일단 모든 메모 데이터 조회
        let allMemoIds : [UUID] = try await fetchAllMemos().map { $0.id }
        
        // 2.
        // 해당 아이디를 가진 애들 지우기
        try await client.from("memos").delete()
            .in("id", values: allMemoIds)
            .execute()
        
    }
    
}
