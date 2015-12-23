//
//  TimeLapseHeaderCell.swift
//  iONLive
//
//  Created by Gadgeon on 12/23/15.
//  Copyright © 2015 Gadgeon. All rights reserved.
//

import UIKit

class TimeLapseHeaderCell: UITableViewCell {

    static let identifier = "TimeLapseHeaderCell"
    @IBOutlet weak var bottomBorder: UILabel!
    @IBOutlet weak var topBorder: UILabel!
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
