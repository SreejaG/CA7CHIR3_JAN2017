//
//  DeleteMediaOptionCell.swift
//  iONLive
//
//  Created by Gadgeon on 12/24/15.
//  Copyright © 2015 Gadgeon. All rights reserved.
//

import UIKit

class DeleteMediaOptionCell: UITableViewCell {

    static let identifier = "DeleteMediaOptionCell"
    @IBOutlet weak var mediaDeleteOptionLabel: UILabel!
    @IBOutlet weak var selectionImageView: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
