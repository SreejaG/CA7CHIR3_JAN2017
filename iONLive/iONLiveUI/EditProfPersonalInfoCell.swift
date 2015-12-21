//
//  EditProfPersonalInfoCell.swift
//  iONLive
//
//  Created by Gadgeon on 12/21/15.
//  Copyright © 2015 Gadgeon. All rights reserved.
//

import UIKit

class EditProfPersonalInfoCell: UITableViewCell {
    
   static let identifier = "EditProfPersonalInfoCell"

    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var userNameTextField: UITextField!
    @IBOutlet weak var displayNameTextField: UITextField!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
