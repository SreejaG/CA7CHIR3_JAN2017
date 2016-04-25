//
//  MediaViewController.swift
//  iONLive
//
//  Created by Gadgeon Smart Systems  on 25/04/16.
//  Copyright © 2016 Gadgeon. All rights reserved.
//

import UIKit

class MediaViewController: UIViewController {

    static let identifier = "MediaViewController"
    
    @IBOutlet var heartOutlineButton: UIButton!
    @IBOutlet var heart3Image: UIImageView!
    @IBOutlet var heart2Image: UIImageView!
    @IBOutlet var heart1Image: UIImageView!
    @IBOutlet var heartView: UIView!
    
    @IBOutlet var heart4Image: UIImageView!
    var runner = NSTimer()
    var index = 0
    var likeFlag : Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        heart1Image.hidden = true
        heart2Image.hidden = true
        heart3Image.hidden = true
        heart4Image.hidden = true

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
 

    @IBAction func didTapHeartButton(sender: AnyObject) {
        if likeFlag == false{
            likeFlag = true
        }
        else{
            likeFlag = false
        }
        index = 0
        self.runner = NSTimer.scheduledTimerWithTimeInterval(0.2, target: self, selector: "enableButton", userInfo: nil, repeats: true)
              
    }
    
    func  enableButton() {
        index += 1
        if index == 1
        {
            heartOutlineButton.hidden = true
            heart1Image.hidden = false
        }
        else if index == 2
        {
            heart1Image.hidden = false
            heart2Image.hidden = false
        }
        else if index == 3
        {
            heart1Image.hidden = false
            heart2Image.hidden = false
            heart3Image.hidden = false
        }
        else if index == 4
        {
            heart1Image.hidden = false
            heart2Image.hidden = false
            heart3Image.hidden = false
            heart4Image.hidden = false
        }
        else{
            runner.invalidate()
            heartOutlineButton.hidden = false
            if likeFlag == true{
                heartOutlineButton.setImage(UIImage(named: "hearth"), forState: .Normal)
            }
            else{
                heartOutlineButton.setImage(UIImage(named: "hearth_outline"), forState: .Normal)
            }
            heart1Image.hidden = true
            heart2Image.hidden = true
            heart3Image.hidden = true
            heart4Image.hidden = true
        }
    }

}
