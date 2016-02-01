//
//  iONLiveCamVideoViewController.swift
//  iONLive
//
//  Created by Vinitha on 2/1/16.
//  Copyright © 2016 Gadgeon. All rights reserved.
//

import UIKit

class iONLiveCamVideoViewController: UIViewController {
    
    static let identifier = "iONLiveCamVideoViewController"

    var videoAPIResult =  [String : String]()
    
    @IBOutlet var numberOfSegementsLabel: UILabel!
    @IBOutlet var videoID: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        self.videoID.preferredMaxLayoutWidth = 100;
//        self.videoIDLabel.hidden = true;
        
//        let trimmedString = videoAPIResult["videoID"]!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())

        videoID.text =  "videoID = " + videoAPIResult["videoID"]!
        numberOfSegementsLabel.text = "No: of Segements = " + videoAPIResult["numSegments"]!
    }
    
    @IBAction func didTapBackButton(sender: AnyObject) {
        
        self.navigationController?.popViewControllerAnimated(true)
    }
}


