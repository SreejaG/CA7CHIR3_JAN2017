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
    
    let nameKey = "user_name"
    let selectionKey = "selection"
    
    var cellDataSource:[String:AnyObject]?
    
    var selectedArray: NSMutableArray = NSMutableArray()
    var deselectedArray: NSMutableArray = NSMutableArray()
    
    @IBAction func contactSelectionButtonClicked(sender: AnyObject) {
        
        if cellDataSource != nil{
            let selectedValue: String = cellDataSource![nameKey] as! String
            if(selectedArray.containsObject(selectedValue)){
                selectedArray.removeObject(selectedValue)
                deselectedArray.addObject(selectedValue)
                contactSelectionButton.setImage(UIImage(named:"red-circle"), forState: .Normal)
            }
            else{
                selectedArray.addObject(selectedValue)
                deselectedArray.removeObject(selectedValue)
                contactSelectionButton.setImage(UIImage(named:"CheckOn"), forState: .Normal)
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
