//
//  ChannelSharedCell.swift
//  iONLive
//
//  Created by Gadgeon Smart Systems  on 4/11/16.
//  Copyright © 2016 Gadgeon. All rights reserved.
//

import UIKit
class ChannelSharedCell: UITableViewCell {
    
     static let identifier = "ChannelSharedCell"
    @IBOutlet weak var channelNameLabel: UILabel!

    @IBOutlet weak var channelProfileImage: UIImageView!
    
    @IBOutlet weak var detailLabel: UILabel!
    
    
    @IBOutlet weak var countLabel: UILabel!
    @IBOutlet weak var currentUpdationImage: UIImageView!
}
