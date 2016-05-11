//
//  PhotoThumbCollectionViewCell.swift
//  iONLive
//
//  Created by Gadgeon on 12/10/15.
//  Copyright © 2015 Gadgeon. All rights reserved.
//

import UIKit

class PhotoThumbCollectionViewCell: UICollectionViewCell,progressviewDelegate {
   
    @IBOutlet weak var playIcon: UIImageView!
    
    @IBOutlet weak var thumbImageView: UIImageView!
  
    @IBOutlet var progressView: UIProgressView!
    
    func ProgresviewUpdate (value : Float)
    {
        progressView.progress = value
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        progressView.transform = CGAffineTransformScale(progressView.transform, 1,3)
    }
  
}
