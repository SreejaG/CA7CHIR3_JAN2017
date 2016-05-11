//
//  MyChannelItemCell.swift
//  iONLive
//
//  Created by Gadgeon on 12/23/15.
//  Copyright © 2015 Gadgeon. All rights reserved.
//

import UIKit

class MyChannelItemCell: UICollectionViewCell
{
    static let identifier = "MyChannelItemCell"
    
    @IBOutlet var channelImageView: UIImageView!
    @IBOutlet var videoPlayIcon: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
    }
}
