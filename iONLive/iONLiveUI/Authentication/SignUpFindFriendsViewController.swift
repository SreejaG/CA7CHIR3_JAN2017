//
//  SignUpFindFriendsViewController.swift
//  iONLive
//
//  Created by Gadgeon Smart Systems  on 24/02/16.
//  Copyright © 2016 Gadgeon. All rights reserved.
//

import UIKit

class SignUpFindFriendsViewController: UIViewController {

    static let identifier = "SignUpFindFriendsViewController"
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        self.navigationController?.navigationBarHidden = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialise()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func initialise()
    {
        self.title = "FIND FRIENDS"
    }
    
   
    @IBAction func continueButtonClicked(sender: AnyObject) {
        
        generateContactSynchronizeAlert()
    }
    
    func generateContactSynchronizeAlert()
    {
        let alert = UIAlertController(title: "\"Catch\" would like to access your contacts", message: "The contacts in your address book will be transmitted to Catch for you to decide who to add", preferredStyle: UIAlertControllerStyle.Alert)
        
        alert.addAction(UIAlertAction(title: "Don't Allow", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
          // self.loadLiveStreamView()
           self.loadCameraViewController()
        }))
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            
        }))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func loadLiveStreamView()
    {
        let vc = MovieViewController.movieViewControllerWithContentPath("rtsp://192.168.42.1:554/live", parameters: nil , liveVideo: true) as! UIViewController
        let backItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        vc.navigationItem.backBarButtonItem = backItem
        self.navigationController?.pushViewController(vc, animated: false)
    }
    func loadCameraViewController()
    {
        let cameraViewStoryboard = UIStoryboard(name:"IPhoneCameraView" , bundle: nil)
        let iPhoneCameraViewController = cameraViewStoryboard.instantiateViewControllerWithIdentifier("IPhoneCameraViewController") as! IPhoneCameraViewController
        self.navigationController?.pushViewController(iPhoneCameraViewController, animated: false)
    }

}
