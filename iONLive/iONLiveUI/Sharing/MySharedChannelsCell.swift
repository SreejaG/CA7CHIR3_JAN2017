//
//  MySharedChannelsCell.swift
//  iONLive
//
//  Created by Gadgeon on 12/22/15.
//  Copyright © 2015 Gadgeon. All rights reserved.
//

import UIKit

class MySharedChannelsCell: UITableViewCell {
    
    
    let channelIdKey = "channelId"
    let channelSelectionkey = "channelSelection"
    static let identifier = "MySharedChannelsCell"
    
    @IBOutlet weak var avatarIconImageView: UIImageView!
    @IBOutlet weak var channelNameLabel: UILabel!
    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var sharedCountLabel: UILabel!
    @IBOutlet weak var channelSelectionButton: UIButton!
    
    var index: Int = Int()
    var cellDataSource:[String:AnyObject]?
    var selectedArray: NSMutableArray = NSMutableArray()
    var deselectedArray: NSMutableArray = NSMutableArray()
    
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
        
        
//        if cellDataSource != nil{
//            let selectedValue: String = cellDataSource![channelIdKey] as! String
//            if(selectedArray.containsObject(selectedValue)){
//                channelSelectionButton.setImage(UIImage(named:"red-circle"), forState: .Normal)
//                selectedArray.removeObject(selectedValue)
//                deselectedArray.addObject(selectedValue)
//                sharedCountLabel.hidden = true
//                avatarIconImageView.hidden = true
//            }
//            else{
//                channelSelectionButton.setImage(UIImage(named:"CheckOn"), forState: .Normal)
//                selectedArray.addObject(selectedValue)
//                deselectedArray.removeObject(selectedValue)
//                sharedCountLabel.hidden = false
//                avatarIconImageView.hidden = false
//            }
//            
//        }
    }
}
