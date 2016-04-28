//
//  ChannelItemListCollectionViewCell.swift
//  iONLive
//
//  Created by Gadgeon on 12/29/15.
//  Copyright © 2015 Gadgeon. All rights reserved.
//

import UIKit

class ChannelItemListCollectionViewCell: UICollectionViewCell {
   
    static let identifier = "ChannelItemListCollectionViewCell"
    @IBOutlet weak var channelItemImageView: UIImageView!
    @IBOutlet var selectionView: UIView!
    @IBOutlet var tickButton: UIButton!
    @IBOutlet var videoView: UIView!
    @IBOutlet var videoPlayIcon: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
  
}
