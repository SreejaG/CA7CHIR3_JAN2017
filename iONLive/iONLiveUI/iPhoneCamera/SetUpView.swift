//
//  SetUpView.swift
//  iONLive
//
//  Created by Gadgeon Smart Systems  on 4/27/16.
//  Copyright © 2016 Gadgeon. All rights reserved.
//

import UIKit

@objc class SetUpView: UIViewController {
 let channelManager = ChannelManager.sharedInstance
    let requestManager = RequestManager.sharedInstance
    let imageUploadManger = ImageUpload.sharedInstance
    var channelDetails: NSDictionary = NSDictionary()

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
  func getValue()
  {
    let defaults = NSUserDefaults .standardUserDefaults()
    let userId = defaults.valueForKey(userLoginIdKey) as! String
    let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
    getLoginDetails(userId, token: accessToken)
    }
    
    func getLoginDetails(userName: String, token: String)
    {
        channelManager.getLoggedInDetails(userName, accessToken: token, success: { (response) in
            self.authenticationSuccessHandlerList(response)

            }) { (error, code) in
                
        }
    }
    func authenticationSuccessHandlerList(response:AnyObject?)
    {
        if let json = response as? [String: AnyObject]
        {
            channelDetails = json as NSDictionary
            setChannelDetails()
        }
        else
        {
            ErrorManager.sharedInstance.inValidResponseError()
        }
    }
    func setChannelDetails()
    {
        let controller = PhotoViewerInstance.iphoneCam as! IPhoneCameraViewController
        controller.loggedInDetails(channelDetails as [NSObject : AnyObject])
    }
}
