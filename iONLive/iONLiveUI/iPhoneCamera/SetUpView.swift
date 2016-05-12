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
                
                ErrorManager.sharedInstance.inValidResponseError()
  
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
        userImages.removeAll()
        let userThumbnailImage = channelDetails["sharedUserThumbnails"]
        let cameraController = IPhoneCameraViewController()
        let sizeThumb = CGSizeMake(28,28)
        if userThumbnailImage != nil
        {
            if userThumbnailImage?.count > 0
            {
                for var i = 0; i < userThumbnailImage?.count; i += 1
                {
                    var image = UIImage()
                    if let imageByteArray: NSArray = userThumbnailImage![i]["data"] as? NSArray{
                        var bytes:[UInt8] = []
                        for serverByte in imageByteArray {
                            bytes.append(UInt8(serverByte as! UInt))
                        }
                        let imageData:NSData = NSData(bytes: bytes, length: bytes.count)
                        if let datas = imageData as NSData? {
                            image = UIImage(data: datas)!
                            let imageAfterConversionThumbnail = cameraController.thumbnaleImage(image, scaledToFillSize: sizeThumb)
                            userImages.append(imageAfterConversionThumbnail)
                        }
                    }
                }
            }
        }
        let controller = PhotoViewerInstance.iphoneCam as! IPhoneCameraViewController
        controller.loggedInDetails(channelDetails as [NSObject : AnyObject], userImages: userImages as NSArray as! [UIImage])
    }
    
    
    //channelMediaLike
    
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
        //    postLikeDetails()
        }
        else
        {
            ErrorManager.sharedInstance.inValidResponseError()
        }
    }
    
//    func postLikeDetails(){
//        
//        let controller = PhotoViewerInstance.iphoneCam as! MovieViewController
//        controller.mediaDetails(status)
//    }
}
