//
//  SnapCamTableViewCell.swift
//  iONLive
//
//  Created by Gadgeon on 12/1/15.
//  Copyright © 2015 Gadgeon. All rights reserved.
//

import UIKit

class SnapCamTableViewCell: UITableViewCell {
    static let identifier = "SnapCamTableViewCell"
    @IBOutlet weak var optionlabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
