//
//  MyChannelCell.swift
//  iONLive
//
//  Created by Gadgeon on 12/29/15.
//  Copyright © 2015 Gadgeon. All rights reserved.
//

import UIKit

class MyChannelCell: UITableViewCell {

    static let identifier = "MyChannelCell"
    @IBOutlet weak var channelHeadImageView: UIImageView!
    @IBOutlet weak var channelItemCount: UILabel!
    @IBOutlet weak var channelNameLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
    }
}
