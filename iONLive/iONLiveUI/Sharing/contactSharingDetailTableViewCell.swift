//
//  contactSharingDetailTableViewCell.swift
//  iONLive
//
//  Created by Gadgeon Smart Systems  on 12/04/16.
//  Copyright © 2016 Gadgeon. All rights reserved.
//

import UIKit

class contactSharingDetailTableViewCell: UITableViewCell {

    @IBOutlet var contactProfileImage: UIImageView!
    @IBOutlet var contactUserName: UILabel!
    
    
    @IBOutlet var subscriptionButton: UIButton!
    
    @IBAction func contactSharingButtonClicked(sender: AnyObject) {
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
