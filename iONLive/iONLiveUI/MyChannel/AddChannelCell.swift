//
//  AddChannelCell.swift
//  iONLive
//
//  Created by Gadgeon Smart Systems  on 04/03/16.
//  Copyright © 2016 Gadgeon. All rights reserved.
//

import UIKit

class AddChannelCell: UITableViewCell {

    static let identifier = "AddChannelCell"
    
    @IBOutlet var addChannelImageView: UIImageView!
    @IBOutlet var addChannelTextLabel: UILabel!
    @IBOutlet var addChannelCountLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    // Initialization code
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
