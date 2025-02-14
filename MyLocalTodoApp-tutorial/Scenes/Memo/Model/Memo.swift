//
//  Memo.swift
//  MyLocalTodoApp-tutorial
//
//  Created by Jeff Jeong on 2023/04/21.
//

import Foundation
import UIKit
import RealmSwift

class Memo : NSObject {
    
    var uuid: String = UUID().uuidString
    var isDone: Bool
    var content: String
    
    init(isDone: Bool = false,
         content: String = "하하하하하하") {
        self.isDone = isDone
        self.content = content
    }
    
    // Entity -> Memo
    init(entity: MemoEntity){
        self.uuid = entity._id.stringValue
        self.isDone = entity.isDone
        self.content = entity.content
    }
    
    // Entity -> Memo
    init(serverEntity entity: MemoServerEntity){
        self.uuid = entity.id.uuidString
        self.isDone = entity.isDone
        self.content = entity.content
    }
    
    static func == (lhs: Memo, rhs: Memo) -> Bool {
        return lhs.uuid == rhs.uuid
    }
}
