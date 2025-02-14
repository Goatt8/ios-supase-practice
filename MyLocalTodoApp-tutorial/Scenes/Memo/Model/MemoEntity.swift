//
//  MemoEntity.swift
//  MyLocalTodoApp-tutorial
//
//  Created by Jeff Jeong on 1/7/25.
//
import RealmSwift

// A dog has an _id primary key, a string name, an optional
// string breed, and a date of birth.
class MemoEntity: Object {
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var isDone: Bool = false
    @Persisted var content: String = ""
    convenience init(content: String,
                     isDone: Bool) {
        self.init()
        self.isDone = isDone
        self.content = content
    }
}

