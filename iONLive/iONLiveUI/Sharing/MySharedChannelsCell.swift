//
//  MySharedChannelsCell.swift
//  iONLive
//
//  Created by Gadgeon on 12/22/15.
//  Copyright © 2015 Gadgeon. All rights reserved.
//

import UIKit

class MySharedChannelsCell: UITableViewCell {
    
    static let identifier = "MySharedChannelsCell"
    
    @IBOutlet weak var avatarIconImageView: UIImageView!
    @IBOutlet weak var channelNameLabel: UILabel!
    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var sharedCountLabel: UILabel!
    @IBOutlet weak var channelSelectionButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    @IBAction func channelSelectionClicked(sender: AnyObject)
    {
        let tag = sender.tag
        NSNotificationCenter.defaultCenter().postNotificationName("refreshMySharedChannelTableView", object:tag)
    }
}
