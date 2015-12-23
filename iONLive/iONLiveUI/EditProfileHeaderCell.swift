//
//  EditProfileHeaderCell.swift
//  iONLive
//
//  Created by Gadgeon on 12/21/15.
//  Copyright © 2015 Gadgeon. All rights reserved.
//

import UIKit

class EditProfileHeaderCell: UITableViewCell {

    static let identifier = "EditProfileHeaderCell"
    
    @IBOutlet weak var topBorderLine: UILabel!
    @IBOutlet weak var borderLine: UILabel!
    @IBOutlet weak var headerTitleLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
