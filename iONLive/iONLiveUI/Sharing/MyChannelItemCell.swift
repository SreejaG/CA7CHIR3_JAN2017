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
    
    @IBOutlet var videoView: UIView!
    
    @IBOutlet var videoPlayIcon: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        videoPlayIcon.center = videoView.center
    }
}
