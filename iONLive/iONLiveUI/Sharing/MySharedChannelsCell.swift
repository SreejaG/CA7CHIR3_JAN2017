//
//  MySharedChannelsCell.swift
//  iONLive
//
//  Created by Gadgeon on 12/22/15.
//  Copyright © 2015 Gadgeon. All rights reserved.
//

import UIKit

class MySharedChannelsCell: UITableViewCell {
    
    let channelNameKey = "channelName"
    let channelShareCountKey = "channelShareCount"
    let channelSelectionKey = "channelSelection"

    static let identifier = "MySharedChannelsCell"
    @IBOutlet weak var avatarIconImageView: UIImageView!
    @IBOutlet weak var channelNameLabel: UILabel!
    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var sharedCountLabel: UILabel!
    @IBOutlet weak var channelSelectionButton: UIButton!
    var cellDataSource:[String:String]?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    @IBAction func channelSelectionClicked(sender: AnyObject)
    {
        if cellDataSource != nil{
            if Int(cellDataSource![channelSelectionKey]!) == 0
            {
                //selected
                cellDataSource![channelSelectionKey] = "1"
                channelSelectionButton.setImage(UIImage(named:"CheckOn"), forState: .Normal)
                sharedCountLabel.hidden = false
                avatarIconImageView.hidden = false
            }
            else
            {
                //deselected
                cellDataSource![channelSelectionKey] = "0"
                channelSelectionButton.setImage(UIImage(named:"red-circle"), forState: .Normal)
                sharedCountLabel.hidden = true
                avatarIconImageView.hidden = true
            }
        }
    }
}
