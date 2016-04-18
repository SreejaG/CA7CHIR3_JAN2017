//
//  ContactListTableViewCell.swift
//  iONLive
//
//  Created by Gadgeon Smart Systems  on 13/04/16.
//  Copyright © 2016 Gadgeon. All rights reserved.
//

import UIKit

class ContactListTableViewCell: UITableViewCell {

    static let identifier = "ContactListTableViewCell"
    
    @IBOutlet var contactProfileImage: UIImageView!
    @IBOutlet var contactUserName: UILabel!
    @IBOutlet var subscriptionButton: UIButton!
    
    let userNameKey = "userName"
    let selectionKey = "selected"

    var cellDataSource:[String:AnyObject]?
    
    var selectedArray: NSMutableArray = NSMutableArray()
    var deselectedArray: NSMutableArray = NSMutableArray()
    
    @IBAction func contactSharingButtonClicked(sender: AnyObject) {
        if cellDataSource != nil{
            let selectedValue: String = cellDataSource![userNameKey] as! String
            if(selectedArray.containsObject(selectedValue)){
                selectedArray.removeObject(selectedValue)
                deselectedArray.addObject(selectedValue)
                subscriptionButton.setImage(UIImage(named:"red-circle"), forState: .Normal)
            }
            else{
                selectedArray.addObject(selectedValue)
                deselectedArray.removeObject(selectedValue)
                subscriptionButton.setImage(UIImage(named:"CheckOn"), forState: .Normal)
            }
            
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
