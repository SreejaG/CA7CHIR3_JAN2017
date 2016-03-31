//
//  contactTableViewCell.swift
//  iONLive
//
//  Created by Gadgeon Smart Systems  on 17/03/16.
//  Copyright © 2016 Gadgeon. All rights reserved.
//

import UIKit

class contactTableViewCell: UITableViewCell {
    
    @IBOutlet var contactProfileImage: UIImageView!
    @IBOutlet var contactProfileName: UILabel!
    @IBOutlet var contactSelectionButton: UIButton!
    var cellsDataSource:[String:AnyObject]?
    var selectedCells : [[String:AnyObject]] = [[String:AnyObject]]()
    
    let inviteKey = "invitationKey"
    let phoneKey = "mobile_no"
    
    @IBAction func contactSelectionButtonClicked(sender: AnyObject) {
        if cellsDataSource != nil{
            if cellsDataSource![inviteKey]! as! String == "0"
            {
                //selected
                cellsDataSource![inviteKey] = "1"
                contactSelectionButton.setImage(UIImage(named:"CheckOn"), forState: .Normal)
                selectedCells.append([inviteKey:"1", phoneKey:cellsDataSource![phoneKey] as! String])
            }
            else
            {
                //deselected
                cellsDataSource![inviteKey] = "0"
                contactSelectionButton.setImage(UIImage(named:"red-circle"), forState: .Normal)
                selectedCells.append([inviteKey:"0", phoneKey:cellsDataSource![phoneKey] as! String])
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        contactProfileImage.layer.cornerRadius = contactProfileImage.frame.size.width/2
        contactProfileImage.layer.masksToBounds = true
        
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
}
