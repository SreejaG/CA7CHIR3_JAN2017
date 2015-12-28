//
//  ProgramCameraButtonCell.swift
//  iONLive
//
//  Created by Gadgeon on 12/28/15.
//  Copyright © 2015 Gadgeon. All rights reserved.
//

import UIKit

class ProgramCameraButtonCell: UITableViewCell {

    static let identifier = "ProgramCameraButtonCell"
    @IBOutlet weak var cameraOptionslabel: UILabel!
    @IBOutlet weak var selectionImage: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
