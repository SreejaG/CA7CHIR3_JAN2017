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
    var flag: Int = 0
    
    @IBAction func contactSelectionButtonClicked(sender: AnyObject) {
        if flag == 0
        {
            //selected
            flag = 1
            contactSelectionButton.setImage(UIImage(named:"CheckOn"), forState: .Normal)
        }
        else
        {
            //deselected
            flag = 0
            contactSelectionButton.setImage(UIImage(named:"red-circle"), forState: .Normal)
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
