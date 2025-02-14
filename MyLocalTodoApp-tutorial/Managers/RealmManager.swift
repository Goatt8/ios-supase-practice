//
//  RealmManager.swift
//  MyLocalTodoApp-tutorial
//
//  Created by Jeff Jeong on 1/7/25.
//

import Foundation
import RealmSwift

class RealmManager {
    static let shared = RealmManager()
    
//    - 새 메모를 저장할 수 있다 - Create 생성
//    - 저장된 메모 목록 조회가 가능하다 - Read 조회
//    - 메모를 수정할 수 있다 - Update 수정
//    - 메모를 삭제할 수 있다 - Delete 삭제
    
    let realm : Realm
    
    init(){
        
        let config = Realm.Configuration(schemaVersion: 20)
        
        self.realm = try! Realm()
        print("Realm is located at:", realm.configuration.fileURL!)
    }
    
    // CREATE
    func createNewMemo(content: String, isDone: Bool){
        
        // Instantiate the class and set its values.
        let entity = MemoEntity(content: content, isDone: isDone)
        
        
        // Open a thread-safe transaction.
        try! realm.write {
            // Add the instance to the realm.
            realm.add(entity)
        }
    }
    
    // READ - 조회
    func fetchAllMemos() -> [MemoEntity]{
        
        // Access all dogs in the realm
        let allMemos = realm.objects(MemoEntity.self)
        return allMemos.map({ $0 })
    }
    
    
    // DELETE :ID
    func deleteAMemo(id: String) -> String? {
        
        guard let deleteItemObjectID = try? ObjectId(string: id) else {
            return nil
        }
        
        // ID 에 해당하는 녀석을 찾아야 한다
        
        guard let deletingEntity = realm.object(ofType: MemoEntity.self, forPrimaryKey: deleteItemObjectID) else {
            return nil
        }
        
        // 지운다
        // Delete the instance from the realm.
        try! realm.write {
            realm.delete(deletingEntity)
        }
        
        return id
    }
    
    // UPDATE :ID ?content=String ?isDone=Bool
    func updateAMemo(id: String,
                     content: String?,
                     isDone: Bool?) -> String? {
        
        guard let updateItemObjectID = try? ObjectId(string: id) else {
            return nil
        }
        
        // ID 에 해당하는 녀석을 찾아야 한다
        
        guard let updatingEntity = realm.object(ofType: MemoEntity.self, forPrimaryKey: updateItemObjectID) else {
            return nil
        }
        
        // 업데이트
        // Open a thread-safe transaction
        try! realm.write {
            // Update some properties on the instance.
            // These changes are saved to the realm
            
            if let content = content {
                updatingEntity.content = content
            }
            
            if let isDone = isDone {
                updatingEntity.isDone = isDone
            }
        }
        
        return id
    }
    
    
    // DELETE ALL
    func deleteAllMemos(){
        
        try! realm.write {
            // Delete all instances of Dog from the realm.
            let allEntities = realm.objects(MemoEntity.self)
            realm.delete(allEntities)
        }
    }
}
