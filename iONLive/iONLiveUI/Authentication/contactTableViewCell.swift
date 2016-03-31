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
    var cellDataSource:[String:String]?
    let selectionKey = "selection"
    
    @IBAction func contactSelectionButtonClicked(sender: AnyObject) {
  
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
