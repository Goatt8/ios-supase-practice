//
//  ViewController.swift
//  MyLocalTodoApp-tutorial
//
//  Created by Jeff Jeong on 2023/04/21.
//

import UIKit
import SwipeCellKit
import Supabase
import Realtime

class MemoListVC: UIViewController {

    
    @IBOutlet weak var deleteAllBarBtn: UIBarButtonItem!
    
    @IBOutlet weak var writeANewMemo: UIBarButtonItem!
    
    @IBOutlet weak var memoTableView: UITableView!
    
    @IBOutlet var searchBar: UISearchBar!
    
    @IBOutlet weak var currentPageLabel: UILabel!
    
    @IBOutlet weak var currentLoggedInUserNicknameLabel: UILabel!
    
    @IBOutlet weak var lastPageLabel: UILabel!
    
    var memoList : [Memo] = []
    
    var memoSubscription : RealtimeSubscription? = nil
    
    @IBOutlet weak var logoutButton: UIButton!
    
    var currentPage: Int = 1 {
        didSet {
            print("\(self.currentPage)")
            self.currentPageLabel.text = "현재페이지 \(self.currentPage)"
        }
    }
    
    var lastPage: Int = 1 {
        didSet {
            print("\(self.lastPage)")
            self.lastPageLabel.text = "마지막페이지 \(self.lastPage)"
        }
    }
    
    //다음페이지여부
    var hasNextPage: Bool {
        if currentPage >= lastPage {
            return false
        }
        return true
    }
    
    lazy var refreshControl: UIRefreshControl = {
        
        let refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "당겨서 새로고침")
        refreshControl.addTarget(self, action: #selector(handleRefresh(_:)), for: .valueChanged)
        return refreshControl
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print(#fileID, #function, #line, "- 1")
        
        currentPageLabel.text = "현재페이지 \(self.currentPage)"
        configureTableView()
        addActions()
        configureSearchBar()
        reloadData()
        
        logoutButton.addTarget(self, action: #selector(handleLogoutButton), for: .touchUpInside)
        
        Task {
            await listenMemoChangeWithCompletion()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotification(_:)), name: .dissmissAuth, object: nil)
        
        Task {
            guard let currentUser = try? await SupabaseManager.shared.getCurrentUser() else {
                return
            }
            self.currentLoggedInUserNicknameLabel.text = "접속 유저 : " + currentUser.nickname
        }
        
    } //viewDidLoad
    
    @objc private func handleNotification(_ sender: Notification) {
        
        guard sender.name == .dissmissAuth else {
            
            return
        }
        
        Task {
            guard let currentUser = try? await SupabaseManager.shared.getCurrentUser() else {
                return
            }
            self.currentLoggedInUserNicknameLabel.text = "접속 유저 : " + currentUser.nickname
        }
        
    }
    
    private func reloadData() {
        Task {
            do {
                let (nextPageMemoEntities, lastPage) = try await SupabaseManager.shared.fetchMemos(page: 1, perPage: 3)
                
                self.lastPage = lastPage
                self.currentPage = 1
                
                let nextPageMemos = nextPageMemoEntities.map { Memo(serverEntity: $0)}
                
                self.memoList = nextPageMemos
                
                self.memoTableView.reloadData()
            } catch {
                print("error")
            }
        }
    }
    
    private func configureSearchBar() {
        searchBar.delegate = self
    }
    
    func listenMemoChangeWithCompletion() async {
        let channel = SupabaseManager.shared.client.channel("memos")

        let subscription = channel.onPostgresChange(
          AnyAction.self,
          schema: "public",
          table: "memos"
        ) { change in
          switch change {
          case .delete(let action): print("Deleted: \(action.oldRecord)")
          case .insert(let action):
              print("Inserted: \(action.record)")
              
              guard let newMemoEntity = try? action.decodeRecord(as: MemoServerEntity.self, decoder: JSONDecoder()) else {
                  return
              }
              DispatchQueue.main.async(execute: {
                  let newMemo = Memo(serverEntity: newMemoEntity)
                  
                  self.memoList.insert(newMemo, at: 0)
                  
                  self.updateMemoListUI(self.memoList)
              })
          case .update(let action): print("Updated: \(action.oldRecord) with \(action.record)")
          }
        }

        await channel.subscribe()
        
        self.memoSubscription = subscription
        

        // remove subscription some time later
//        subscription.cancel()
    }
    
    func listenMemoChangeWithAsync() async {
        let channel = SupabaseManager.shared.client.channel("memos")

        let changeStream = channel.postgresChange(
          AnyAction.self,
          schema: "public",
          table: "memos"
        )

        await channel.subscribe()

        for await change in changeStream {
          switch change {
            case .delete(let action):
              print("Deleted: \(action.oldRecord)")
            case .insert(let action):
              print("Inserted: \(action.record)")
            case .update(let action):
              print("Updated: \(action.oldRecord) with \(action.record)")
          }
        }
    }

    fileprivate func addActions(){
        print(#fileID, #function, #line, "- ")
        self.writeANewMemo.target = self
        self.writeANewMemo.action = #selector(showAddAMemoAlert(_:))
        

        self.deleteAllBarBtn.target = self
        self.deleteAllBarBtn.action = #selector(deleteAll(_:))
    }
    
    @objc private func handleRefresh(_ sender: UIRefreshControl) {
        print(#fileID, #function, #line, "- ")
        Task {
            do {
                let (nextPageMemoEntities, lastPage) = try await SupabaseManager.shared.fetchMemos(page: 1, perPage: 3)
                
                let nextPageMemos = nextPageMemoEntities.map { Memo(serverEntity: $0)}
                
                self.lastPage = lastPage
                self.currentPage = 1
                self.memoList = nextPageMemos
                
                self.memoTableView.reloadData()
            } catch {
                print("error")
            }
        }
        sender.endRefreshing()
    }
//MARK: - IBActions
    @objc private func handleLogoutButton() {
        Task {
            do {
                try await SupabaseManager.shared.logoutUser()
            } catch {
                print("error")
            }
        }
    }
    
    @IBAction func handleDataRefreshButton(_ sender: Any) {
        Task {
            do {
                let (nextPageMemoEntities, lastPage) = try await SupabaseManager.shared.fetchMemos(page: 1, perPage: 3)
                
                let nextPageMemos = nextPageMemoEntities.map { Memo(serverEntity: $0)}
                
                self.lastPage = lastPage
                self.currentPage = 1
                
                self.memoList.append(contentsOf: nextPageMemos)
                
                self.memoTableView.reloadData()
            } catch {
                print("error")
            }
        }
    }
    
    @IBAction func handleNextPageButton(_ sender: Any) {
        
        guard hasNextPage == true else {
            print("더 이상 가져올 페이지가 없습니다")
            return
        }
        
        Task {
            do {
                let (nextPageMemoEntities, lastPage) = try await SupabaseManager.shared.fetchMemos(page: self.currentPage + 1, perPage: 3)
                
                self.lastPage = lastPage
                self.currentPage += 1
                
                let nextPageMemos = nextPageMemoEntities.map { Memo(serverEntity: $0)}
                
                self.memoList.append(contentsOf: nextPageMemos)
                
                self.memoTableView.reloadData()
            } catch {
                print("error")
            }
        }
    }
    
}






extension MemoListVC {
    
    @objc fileprivate func deleteAll(_ sender: UIBarButtonItem){
        print(#fileID, #function, #line, "- ")
//        RealmManager.shared.deleteAllMemos()
        Task{
            try? await SupabaseManager.shared.deleteAllMemos()
        }
        
        memoList.removeAll()
        self.updateMemoListUI([])
    }
    
    
    @objc fileprivate func showAddAMemoAlert(_ sender: UIBarButtonItem){
        print(#fileID, #function, #line, "- ")
        
        let alert = UIAlertController(title: "메모 추가하기", message: "새 메모를 추가해주세요", preferredStyle: .alert)
        
        alert.addTextField(configurationHandler: { tf in
            
            print(#fileID, #function, #line, "- tf.text: \(tf.text)")
        })
        
        alert.textFields?.first?.placeholder = "빡코딩하기!"
        
        let addMemoAction = UIAlertAction(title: NSLocalizedString("추가", comment: "추가 액션"), style: .default, handler: { [weak self] _ in
            
            guard let userInput = alert.textFields?.first?.text,
                  let self = self else {
                print(#fileID, #function, #line, "- 작성된 내용이 없습니다")
                return
            }
            print(#fileID, #function, #line, "- userInput: \(userInput)")
            
            self.addNewMemo(userInput: userInput)
        })
        
        let dismissAction = UIAlertAction(title: "닫기", style: .cancel)
        
        alert.addAction(addMemoAction)
        alert.addAction(dismissAction)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc fileprivate func showEditAMemoAlert(existingMemo: Memo){
        print(#fileID, #function, #line, "- ")
        
        let alert = UIAlertController(title: "메모 수정하기", message: "기존 메모를 수정해주세요", preferredStyle: .alert)
        
        alert.addTextField(configurationHandler: { tf in
            
            print(#fileID, #function, #line, "- tf.text: \(tf.text)")
        })
        
        alert.textFields?.first?.placeholder = "빡코딩하기!"
        alert.textFields?.first?.text = existingMemo.content
        
        let addMemoAction = UIAlertAction(title: NSLocalizedString("수정", comment: "수정 액션"), style: .default, handler: { [weak self] _ in
            
            guard let userInput = alert.textFields?.first?.text,
                  let self = self else {
                print(#fileID, #function, #line, "- 작성된 내용이 없습니다")
                return
            }
            print(#fileID, #function, #line, "- userInput: \(userInput)")
            
            self.updateAMemo(existingMemo, userInput)
        })
        
        let dismissAction = UIAlertAction(title: "닫기", style: .cancel)
        
        alert.addAction(addMemoAction)
        alert.addAction(dismissAction)
        
        self.present(alert, animated: true, completion: nil)
    }
}

//MARK: - 메모 데이터 처리 관련 
extension MemoListVC {
    
    fileprivate func updateAMemoIsDone(_ updatingMemo : Memo,
                                       _ isDone: Bool){
        print(#fileID, #function, #line, "- updatingMemo.uuid: \(updatingMemo.uuid), isDone: \(isDone)")

        guard let updateIndex = memoList.firstIndex(of: updatingMemo) else {
            print(#fileID, #function, #line, "- ")
            return
        }
        
//        RealmManager.shared.updateAMemo(id: updatingMemo.uuid,
//                                        content: nil, isDone: isDone)
        Task {
           try? await SupabaseManager.shared.updateAMemo(id: updatingMemo.uuid,
                                               content: nil,
                                               isDone: isDone)
        }
        
        
        memoList[updateIndex].isDone = isDone

        memoTableView.reloadRows(at: [IndexPath(row: updateIndex, section: 0)], with: .fade)
    }
    
    fileprivate func updateAMemo(_ updatingMemo : Memo,
                                 _ userInput: String){
        print(#fileID, #function, #line, "- updatingMemo.uuid: \(updatingMemo.uuid), userInput: \(userInput)")
        
        guard let updateIndex = memoList.firstIndex(of: updatingMemo) else {
            print(#fileID, #function, #line, "- ")
            return
        }
       
//        RealmManager.shared.updateAMemo(id: updatingMemo.uuid,
//                                        content: userInput, isDone: nil)
        Task {
            try? await SupabaseManager.shared.updateAMemo(id: updatingMemo.uuid, content: userInput, isDone: nil)
        }
        
        
        memoList[updateIndex].content = userInput
        
        memoTableView.reloadRows(at: [IndexPath(row: updateIndex, section: 0)], with: .fade)
    }
    
    fileprivate func deleteAMemo(_ deleteMemo: Memo){
        print(#fileID, #function, #line, "- deleteMemo: \(deleteMemo.uuid)")
        
        guard let deleteIndex = self.memoList.firstIndex(of: deleteMemo) else {
            print(#fileID, #function, #line, "- ")
            return
        }
        
//        RealmManager.shared.deleteAMemo(id: deleteMemo.uuid)
        Task {
            try? await SupabaseManager.shared.deleteAMemo(id: deleteMemo.uuid)
        }
        
        
        self.memoList.remove(at: deleteIndex)
        
        memoTableView.deleteRows(at: [IndexPath(row: deleteIndex, section: 0)], with: .fade)
    }
    
    fileprivate func addNewMemo(userInput: String) {
        print(#fileID, #function, #line, "- userInput: \(userInput)")
        
        let newMemo = Memo(content: userInput)
        
        Task {
            do {
                try? await SupabaseManager.shared.createNewMemo(content: userInput, isDone: false)
            } catch {
                print("error")
            }
           
        }

    }
    
    fileprivate func updateMemoListUI(_ updatedMemos: [Memo],
                                      animated: Bool = true) {
        print(#fileID, #function, #line, "- updatedMemos: \(updatedMemos.count)")
        
        
        self.memoList = updatedMemos

        self.memoTableView.reloadSections(IndexSet(integer: 0), with: .fade)
    }
}

extension MemoListVC {
    
    fileprivate func configureTableView() {
        let cellNib = UINib(nibName: "MemoCell", bundle: nil)
        self.memoTableView.register(cellNib, forCellReuseIdentifier: "MemoCell")
        self.memoTableView.dataSource = self
        
        self.memoTableView.refreshControl = self.refreshControl
    }
}

extension MemoListVC : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return memoList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "MemoCell", for: indexPath) as? MemoCell else {
            return UITableViewCell()
        }
        
        let item = memoList[indexPath.row]
        
        cell.updateUI(with: item, delegate: self)
        
        return cell
    }
}


extension MemoListVC : SwipeTableViewCellDelegate {
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeCellKit.SwipeActionsOrientation) -> [SwipeCellKit.SwipeAction]? {
        
        let cellItem : Memo = memoList[indexPath.row]
        
        switch orientation {
        case .right:
            let editAction = SwipeAction(style: .default, title: "수정하기", handler: { [weak self] action, indexPath in
                guard let self = self else { return }
                #warning("TODO : - 수정하기")
                print(#fileID, #function, #line, "- 수정하기 indexPath: \(indexPath.row)")
                self.showEditAMemoAlert(existingMemo: cellItem)
            })
            editAction.hidesWhenSelected = true
            editAction.backgroundColor = .systemOrange
            editAction.image = UIImage(systemName: "square.and.pencil")
            
            let deleteAction = SwipeAction(style: .destructive, title: "삭제", handler: { [weak self] action, indexPath in
                guard let self = self else { return }
                #warning("TODO : - 삭제하기")
                print(#fileID, #function, #line, "- 삭제하기 indexPath: \(indexPath.row)")
                self.deleteAMemo(cellItem)
            })
            deleteAction.hidesWhenSelected = true
            deleteAction.backgroundColor = .systemRed
            deleteAction.image = UIImage(systemName: "trash.fill")
            
            return [deleteAction, editAction]
        case .left:
            let checkDoneAction = SwipeAction(style: .default, title: "완료여부", handler: { action, indexPath in
                
                print(#fileID, #function, #line, "- 완료처리 indexPath: \(indexPath.row)")
                self.updateAMemoIsDone(cellItem, !cellItem.isDone)
                
            })
            checkDoneAction.hidesWhenSelected = true
            checkDoneAction.backgroundColor = .systemGreen
            checkDoneAction.image = UIImage(systemName: "checkmark.seal.fill")
            
            return [checkDoneAction]
        }
        
    }
    
    func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeOptions {
        
        var options = SwipeOptions()
        options.expansionStyle = orientation == .left ? .selection : .selection
        options.transitionStyle = .drag
        
        return options
    }
    
}

extension MemoListVC : UISearchBarDelegate {

    //검색버튼 클릭시
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        let searchTerm: String = searchBar.text ?? ""
        
        //검색 API호출
        Task {
            do {
                //데이터 fetch
               let foundMemoEntities = try await SupabaseManager.shared.fetchMemos(searchTerm: searchTerm)
                memoList = foundMemoEntities.map{ Memo(serverEntity: $0) }
               
                //업데이트 reload
                self.updateMemoListUI(memoList)
            } catch {
                print("error")
            }
        }
        
//        //기존 검색어 지우기
//        searchBar.text = ""
//        
//        //키보드 포커스 없애기
//        searchBar.searchTextField.resignFirstResponder()
        
    }
    //글자 변경시
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            print("x버튼 클릭됨 = 비어있음")
            self.reloadData()
        }
    }
    //포커스가 일어났을때
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        return true
    }
    
    
}
