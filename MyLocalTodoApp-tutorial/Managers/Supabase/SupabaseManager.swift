//
//  SupabaseManager.swift
//  MyLocalTodoApp-tutorial
//
//  Created by Jeff Jeong on 1/11/25.
//

import Foundation
import Supabase

// codable 제이슨
// de down
// json -> struct,class


// en make
// En codable

// json -> swift
struct MemoServerEntity: Decodable, Encodable {
    let id: UUID
    let content: String
    let isDone: Bool
    
    enum CodingKeys: CodingKey {
        case id
        case content
        case is_done
    }
    
    init(content: String,
         isDone: Bool = false){
        self.id = UUID()
        self.content = content
        self.isDone = isDone
    }
    
    // json -> swift
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.content = try container.decode(String.self, forKey: .content)
        self.isDone = try container.decode(Bool.self, forKey: .is_done)
    }
    
    // json 화
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(content, forKey: .content)
        try container.encode(isDone, forKey: .is_done)
    }
}

class SupabaseManager {
    static let shared = SupabaseManager()
    
    let client : SupabaseClient
    
    init(){
        // 여러분 프로젝트 주소
        self.client = SupabaseClient(supabaseURL:
                                        URL(string: "https://lkqizhakfmomfaarddmj.supabase.co")!,
                                     supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxrcWl6aGFrZm1vbWZhYXJkZG1qIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzg4MjQ5MjksImV4cCI6MjA1NDQwMDkyOX0.vwLAo26NDId81tSQBTrTk0joMhKEzZhQGtBmS2QzfF4")

    }
}

// json
// en codable
// make - 화

//MARK: - 1 : N
struct User: Decodable {
    let id: Int
    let nickname: String?
    
// +) 추가됨
    let publishedPosts: [Post]
//    let posts: [Post]
    
    let messages : [Message]
    
//    let profiles : [Profile]
    let profile : Profile?
    
    enum CodingKeys: String, CodingKey {
        case id
        case nickname = "name"
//        case publishedPosts = "posts"
        case publishedPosts = "published_posts"
        
        case messages = "my_messages"
        
        case profiles
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = try container.decode(Int.self, forKey: .id)
        self.nickname = try container.decode(String?.self, forKey: .nickname)
        self.publishedPosts = try container.decode([Post].self, forKey: .publishedPosts)
        self.messages = try container.decode([Message].self, forKey: .messages)
        
        let tempProfiles : [Profile] = try container.decode([Profile].self, forKey: .profiles)
        
        self.profile = tempProfiles.first
    }
    
    struct Post: Codable {
        let id: Int
        let postTitle: String
        
        enum CodingKeys : String, CodingKey {
            case id
            case postTitle = "title"
        }
    }
    
    struct Message: Codable {
        let id : Int
        let content: String
    }
    
    struct Profile: Codable {
        let id : Int
        let bio: String
    }
}

enum PostContentType: Int {
    case normal = 1
    case news
    case sisa
    case sports
    case entertainment
}

struct Post: Decodable {
    let id: Int
    let title: String
    let content: String
    
    // +) 추가됨
    let author: User
    
//    let tags: [Tag]
    
//    let tags: [String]
    let tags: [PostContentType]
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case content
        case author
        
        case tags = "attatched_tags"
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.content = try container.decode(String.self, forKey: .content)
        self.author = try container.decode(Post.User.self, forKey: .author)
        
        let tempTags = try container.decode([Tag].self, forKey: .tags)
        
//        self.tags = tempTags.map(\.name)
        
        self.tags = tempTags
            .map(\.id)
            .map({ PostContentType(rawValue: $0) ?? .normal })
        
    }
    
    struct User: Decodable {
        let id: Int
        let name: String
    }
    
    struct Tag: Decodable {
        let id: Int
        let name: String
    }
}


//MARK: - 1 : N
extension SupabaseManager {
    
    
    // 정대리가 작성한 글들을 가져올 수 있다
    func fetchUsers() async throws -> [User] {
        let entities: [User] = try await client
          .from("users")
          .select("""
                id, 
                name,
            
                published_posts: posts (id, title),
                
                my_messages: messages (id, content),
            
                profiles: user_infos (*)
            """)
          .execute()
          .value
        //        published_posts: posts(*)
        return entities
    }
    
    // 게시글을 보고 누가 작성했는지 안다
    func fetchPosts() async throws -> [Post] {
        let entities: [Post] = try await client
          .from("posts")
          .select(
            """
            
              *,
            
              author: author_id(id, name),
            
              attatched_tags: tags(id, name)
                
            """)
          .execute()
          .value
        
        return entities
    }
    
    
}

//MARK: - N : M - model

struct PostEntity: Codable {
    let id: Int
    let title: String
    let content: String
    
    // +) 추가됨
    let attachedTags : [Tag]
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case content
        
        case attachedTags = "attached_tags"
    }
    
    struct Tag: Codable {
        let id: Int
        let name: String
    }
}

struct TagEntity: Decodable {
    let id: Int
    let name: String
    
    // +) 추가됨
    let posts : [Post]
    
    enum CodingKeys: String, CodingKey {
        case id
        case name

        case posts
    }
    
    struct Post: Decodable {
        let id: Int
        let title: String
        let content: String
        
//        let postAuthor: User
        let postAuthor: String
        
        enum CodingKeys: CodingKey {
            case id
            case title
            case content
            case postAuthor
        }
        
        init(from decoder: any Decoder) throws {
            let container: KeyedDecodingContainer<TagEntity.Post.CodingKeys> = try decoder.container(keyedBy: TagEntity.Post.CodingKeys.self)
            self.id = try container.decode(Int.self, forKey: TagEntity.Post.CodingKeys.id)
            self.title = try container.decode(String.self, forKey: TagEntity.Post.CodingKeys.title)
            self.content = try container.decode(String.self, forKey: TagEntity.Post.CodingKeys.content)
            
            let tempAuthor = try container.decode(User.self, forKey: .postAuthor)
            
            self.postAuthor = tempAuthor.name
        }
    }
    
    struct User: Decodable {
        let id: Int
        let name: String
    }
}

//MARK: - N : M
extension SupabaseManager {
    
    
    // 게시글에 어떤 태그들이 있는 지 알 수 있다
    func fetchPostWithTags() async throws -> [PostEntity] {
        let entities: [PostEntity] = try await client
          .from("posts")
          .select(
            """
              *, 
              attached_tags: tags(*)
            """)
          .execute()
          .value
        
        return entities
    }
    
    // 태그에 달린 게시글들을 조회 할 수 있다
    func fetchTagsWithPosts() async throws -> [TagEntity] {
        let entities: [TagEntity] = try await client
          .from("tags")
          .select(
            """
              *, 
              posts( *, postAuthor: author_id(*))
            """)
          .execute()
          .value
//        author: author_id(id, name),
        return entities
    }
    
}


//MARK: - Closure
extension SupabaseManager {
    
    // 단일 처리
    func doHeavyWorkWithCompletion(title: String, time: Double = 2,
                                            completion: @escaping (String) -> Void){
        print(#fileID, #function, #line, "- title: \(title)")
        // 1.
        DispatchQueue.global().asyncAfter(deadline: .now() + time, execute: {
            print(#fileID, #function, #line, "- ")
            completion(title)
            completion(title)
            completion(title)
            print(#fileID, #function, #line, "- 2초 뒤 title: \(title)")
        })
    }
    
    // 순차 처리 01
    func doSomethingSeqWithCompletion(completion: @escaping (String) -> Void){
        
        doHeavyWorkWithCompletion(title: "⭐️", completion: { result in
            print(#fileID, #function, #line, "- result 1 ")
            self.doHeavyWorkWithCompletion(title: "⭐️⭐️", completion: { result in
                print(#fileID, #function, #line, "- result 2")
                
                self.doHeavyWorkWithCompletion(title: "⭐️⭐️⭐️", completion: { result in
                    print(#fileID, #function, #line, "- result 3")
                    completion("done!")
                })
            })
        })
    }
    
    // 순차 처리 2
    func doSomethingSeqWithCompletionSemaphore(completion: @escaping (String) -> Void){
        
        let semaphore = DispatchSemaphore(value: 0)
        
        doHeavyWorkWithCompletion(title: "⭐️", completion: { result in
            print(#fileID, #function, #line, "- result ⭐️")
            semaphore.signal()
        })
        
        semaphore.wait()
        
        doHeavyWorkWithCompletion(title: "⭐️⭐️", completion: { result in
            print(#fileID, #function, #line, "- result ⭐️⭐️ ")
            semaphore.signal()
        })
        
        semaphore.wait()
        doHeavyWorkWithCompletion(title: "⭐️⭐️⭐️", completion: { result in
            print(#fileID, #function, #line, "- result ⭐️⭐️⭐️")
            completion("done!")
        })
    }
    
    
    // 동시 처리
    func doAtTheSameTimeWithCompletion(completion: @escaping ([String]) -> Void){
        
        let items = ["🐙", "⭐️", "👍"]
        
        var results : [String] = []
        
        let group = DispatchGroup()
        
        items.forEach { item in
            group.enter()
            doHeavyWorkWithCompletion(title: item, time: 2, completion: { result in
                
                results.append(result)
                
                group.leave()
            })
        }
        
//
//        group.enter()
//        
//        doHeavyWorkWithCompletion(title: items[0], time: 2, completion: { result in
//            print(#fileID, #function, #line, "- 1 ")
//            results.append(result)
//            
//            group.leave()
//        })
//        
//        group.enter()
//        doHeavyWorkWithCompletion(title: items[1], time: 1, completion: { result in
//            print(#fileID, #function, #line, "- 2")
//            results.append(result)
//            group.leave()
//        })
//        
//        group.enter()
//        doHeavyWorkWithCompletion(title: items[2], time: 2, completion: { result in
//            print(#fileID, #function, #line, "-  3")
//            results.append(result)
//            group.leave()
//            
//        })
        
        group.notify(queue: .main, execute: {
            print(#fileID, #function, #line, "- 모든 API 완료")
            completion(results)
        })
    }
    
}

//MARK: - Async Await 처리
extension SupabaseManager {
    
    func doSomethingHeavyWithAsync(title: String, time: Double = 2) async -> String{
        print(#fileID, #function, #line, "- \(title)")
        
//        do {
//            try await Task.sleep(nanoseconds: 1_000_000_000 * UInt64(time))
//        } catch {
//            print(#fileID, #function, #line, "- error: \(error)")
//        }
        
        try? await Task.sleep(nanoseconds: 1_000_000_000 * UInt64(time))
        
        
        print(#fileID, #function, #line, "- \(title) \(time)초 뒤")
        return title
    }
    
    func doSomethingHeavyWithAsyncNoReturn(title: String, time: Double = 2) async {
        print(#fileID, #function, #line, "- \(title)")
        
//        do {
//            try await Task.sleep(nanoseconds: 1_000_000_000 * UInt64(time))
//        } catch {
//            print(#fileID, #function, #line, "- error: \(error)")
//        }
        
        try? await Task.sleep(nanoseconds: 1_000_000_000 * UInt64(time))
        
        
        print(#fileID, #function, #line, "- \(title) \(time)초 뒤")
        
    }
    
    
    // 순차 처리
    func doSeqWithAsync() async throws -> [String]{
        
        let result1 = try await doSomethingHeavyWithAsync(title: "⭐️")
        let result2 = try await doSomethingHeavyWithAsync(title: "⭐️⭐️")
        let result3 = try await doSomethingHeavyWithAsync(title: "⭐️⭐️⭐️")
     
        return [result1, result2, result3]
    }
    
    // 동시처리 01
    func doAtTheSameTimeWithAsync() async -> [String] {
        
        async let result1 =  doSomethingHeavyWithAsync(title: "⭐️", time: 2)
        async let result2 =  doSomethingHeavyWithAsync(title: "⭐️⭐️", time: 3)
        async let result3 =  doSomethingHeavyWithAsync(title: "⭐️⭐️⭐️", time: 1)
        
        return await [result1, result2, result3]
    }
    
    func doAtTheSameTimeWithAsyncNoReturn() async {
        
        async let result1 =  doSomethingHeavyWithAsyncNoReturn(title: "⭐️", time: 2)
        async let result2 =  doSomethingHeavyWithAsyncNoReturn(title: "⭐️⭐️", time: 2)
        async let result3 =  doSomethingHeavyWithAsyncNoReturn(title: "⭐️⭐️⭐️", time: 2)
        await [result1, result2, result3]
    }
    
    // 동시처리 02
    func doAtTheSameTimeWithAsync02(items: [String]) async -> [String]{
        
        return await withTaskGroup(of: String.self, body: { group in
            
            for anItem in items {
                group.addTask(operation: {
                    let childTaskResult : String = await self.doSomethingHeavyWithAsync(title: anItem, time: 2)
                    return childTaskResult
                })
            }
            
            var results : [String] = []
            
            for await singleValue in group {
                results.append(singleValue)
            }
            return results
        })
        
    }
}

//MARK: - Closure, async

extension SupabaseManager {
    
    func closureToAsynSteam() -> AsyncStream<String> {
        
        return AsyncStream(String.self, { continuation in
            self.doHeavyWorkWithCompletion(title: "⭐️", time: 2, completion: { result in
                continuation.yield(result)
            })
        })
    }
    
    func closureToAsync() async -> String {
        return await withCheckedContinuation({ continuation in
            self.doHeavyWorkWithCompletion(title: "⭐️", completion: { result in
                continuation.resume(returning: result)
            })
        })
    }
    
    func closureToAsync2() async -> String {
        return await withCheckedContinuation({ continuation in
            
            self.doHeavyWorkWithCompletion(title: "⭐️", completion: { result in
                continuation.resume(returning: result)
                
                self.doHeavyWorkWithCompletion(title: "⭐️⭐️", completion: { result in
                    continuation.resume(returning: result)
                    
                    self.doHeavyWorkWithCompletion(title: "⭐️⭐️⭐️", completion: { result in
                        continuation.resume(returning: result)
                    })
                })
            })
        })
    }
    
}

