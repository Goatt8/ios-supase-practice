//
//  MemoCell.swift
//  MyLocalTodoApp-tutorial
//
//  Created by Jeff Jeong on 2023/04/21.
//

import UIKit
import SwipeCellKit

class MemoCell: SwipeTableViewCell {

    @IBOutlet weak var isDoneLabel: UILabel!
    
    @IBOutlet weak var todoContentLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func updateUI(with cellData: Memo, delegate : SwipeTableViewCellDelegate) {
        print(#fileID, #function, #line, "- cellData.isDone: \(cellData.isDone)")
        self.delegate = delegate
        
        self.isDoneLabel.text = cellData.isDone ? "✅" : "☑️"
        self.todoContentLabel.text = cellData.content
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
