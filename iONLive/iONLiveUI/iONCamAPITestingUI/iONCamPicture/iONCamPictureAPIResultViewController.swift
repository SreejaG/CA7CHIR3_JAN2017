//
//  iONCamPictureAPIResultViewController.swift
//  iONLive
//
//  Created by Gadgeon on 1/29/16.
//  Copyright © 2016 Gadgeon. All rights reserved.
//

import UIKit

class iONCamPictureAPIResultViewController: UIViewController {
    
   static let identifier = "iONCamPictureAPIResultViewController"
    var imageBurstId:String = ""

    

    @IBOutlet weak var resultImageView: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        if(imageBurstId != "")
        {
            resultImageView.setImageWithURL( NSURL(string: UrlManager.sharedInstance.getiONLiveCamImageDownloadUrl(self.imageBurstId))!)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
