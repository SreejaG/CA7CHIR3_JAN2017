//
//  SettingsToggleTableViewCell.swift
//  iONLive
//
//  Created by Gadgeon on 12/10/15.
//  Copyright © 2015 Gadgeon. All rights reserved.
//

import UIKit

class SettingsToggleTableViewCell: UITableViewCell {

    @IBOutlet weak var titlelabel: UILabel!
    @IBOutlet weak var toggleCellSwitch: UISwitch!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
