//
//  SimpleTextFieldTableViewCell.swift
//  iONLive
//
//  Created by Vinitha on 2/5/16.
//  Copyright © 2016 Gadgeon. All rights reserved.
//

import UIKit

class SimpleTextFieldTableViewCell: UITableViewCell {

    static let identifier = "SimpleTextFieldTableViewCell"
    @IBOutlet var inputTextField: UITextField!
    @IBOutlet var inputLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
