//
//  PickerViewTableViewCell.swift
//  iONLive
//
//  Created by Vinitha on 2/5/16.
//  Copyright © 2016 Gadgeon. All rights reserved.
//

import UIKit

class PickerViewTableViewCell: UITableViewCell {

    static let identifier = "PickerViewTableViewCell"
    @IBOutlet var inputPickerView: UIPickerView!
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
