//
//  TimeTapseCell.swift
//  iONLive
//
//  Created by Gadgeon on 12/23/15.
//  Copyright © 2015 Gadgeon. All rights reserved.
//

import UIKit

class TimeTapseCell: UITableViewCell {

    static let identifier = "TimeTapseCell"
    @IBOutlet weak var timelapseOptionLabel: UILabel!
    @IBOutlet weak var selectionImageView: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
