//
//  contactSharingDetailTableViewCell.swift
//  iONLive
//
//  Created by Gadgeon Smart Systems  on 12/04/16.
//  Copyright © 2016 Gadgeon. All rights reserved.
//

import UIKit

class contactSharingDetailTableViewCell: UITableViewCell {
    
    static let identifier = "contactSharingDetailTableViewCell"
    
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
                subscriptionButton.setImage(UIImage(named:"red-circle"), forState: .Normal)
                selectedArray.removeObject(selectedValue)
                deselectedArray.addObject(selectedValue)
            }
            else{
                subscriptionButton.setImage(UIImage(named:"CheckOn"), forState: .Normal)
                selectedArray.addObject(selectedValue)
                deselectedArray.removeObject(selectedValue)
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        contactProfileImage.layer.cornerRadius = contactProfileImage.frame.size.width/2
        contactProfileImage.layer.masksToBounds = true
        
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}
