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
    let profileManager = ProfileManager.sharedInstance
    
    var channelDetails: NSDictionary = NSDictionary()
    var status: Int = Int()
    var userImages : [UIImage] = [UIImage]()
    
    
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
          //  ErrorManager.sharedInstance.inValidResponseError()
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
    
    func convertStringtoURL(url : String) -> NSURL
    {
        let url : NSString = url
        let searchURL : NSURL = NSURL(string: url as String)!
        return searchURL
    }

    func setChannelDetails()
    {
        userImages.removeAll()
        print(channelDetails)
        
        let userThumbnailImage = channelDetails["sharedUserThumbnails"] as! NSArray
        let cameraController = IPhoneCameraViewController()
        let sizeThumb = CGSizeMake(28,28)
        
        for i in 0 ..< userThumbnailImage.count
        {
            var image = UIImage()
            let thumbUrl =  userThumbnailImage[i] as! String
            if(thumbUrl != "")
            {
                let url: NSURL = convertStringtoURL(thumbUrl)
                if let data = NSData(contentsOfURL: url){
                    var convertImage : UIImage = UIImage()
                    let imageDetailsData = (data as NSData?)!
                    convertImage = UIImage(data: imageDetailsData)!
                    let imageAfterConversionThumbnail = cameraController.thumbnaleImage(convertImage, scaledToFillSize: sizeThumb)
                    image = imageAfterConversionThumbnail
                }
                else{
                    image = UIImage(named: "dummyUser")!
                }
            }
            else{
                image = UIImage(named: "dummyUser")!
            }
            userImages.append(image)
        }
        
        let controller = PhotoViewerInstance.iphoneCam as! IPhoneCameraViewController
        controller.loggedInDetails(channelDetails as [NSObject : AnyObject], userImages: userImages as NSArray as! [UIImage])
    }
    
    func setMediaLikes(userName: String, accessToken: String, notifType: String, mediaDetailId: String)
    {
        channelManager.postMediaInteractionDetails(userName, accessToken: accessToken, notifType: notifType, mediaDetailId: Int(mediaDetailId)!, success: { (response) in
            self.authenticationSuccessHandlerSetMedia(response)
        }) { (error, message) in
            
        }
    }
    
    func authenticationSuccessHandlerSetMedia(response:AnyObject?)
    {
        if let json = response as? [String: AnyObject]
        {
            status = json["status"] as! Int
        }
        else
        {
            ErrorManager.sharedInstance.inValidResponseError()
        }
    }
}
