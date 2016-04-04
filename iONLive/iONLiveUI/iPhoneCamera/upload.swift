//
//  upload.swift
//  iONLive
//
//  Created by Gadgeon Smart Systems  on 3/30/16.
//  Copyright © 2016 Gadgeon. All rights reserved.
//

import UIKit

protocol uploadProgressDelegate
{
    func  uploadProgress ( progressDict : NSMutableArray)
}

@objc class upload: UIViewController ,NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate {
    
    let channelManager = ChannelManager.sharedInstance
    var channelDict = Dictionary<String, AnyObject>()
    var snapShots : NSMutableDictionary = NSMutableDictionary()
    var channelDetails: NSMutableArray = NSMutableArray()
    let requestManager = RequestManager.sharedInstance
    var dummyImagesDataSourceDatabase :[[String:UIImage]]  = [[String:UIImage]]()
    let thumbImageKey = "thumbImage"
    let fullImageKey = "fullImageKey"
    let imageUploadManger = ImageUpload.sharedInstance
    let signedURLResponse: NSMutableDictionary = NSMutableDictionary()
    var delegate : uploadProgressDelegate?
    var progressDictionary : NSMutableArray = NSMutableArray()
    
    var taskIndex :  Int = 0
  var media : NSString = ""
    var videoPath : NSURL = NSURL()
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func uploadMedia()
    {
          getSignedURL()
        
        
    }
    func getSignedURL()
    {
        let defaults = NSUserDefaults .standardUserDefaults()
        let userId = defaults.valueForKey(userLoginIdKey) as! String
        let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
        getChannelDetails(userId, token: accessToken)
    }
    func getChannelDetails(userName: String, token: String)
    {
        channelManager.getChannelDetails(userName, accessToken: token, success: { (response) -> () in
            self.authenticationSuccessHandlerList(response)
            }) { (error, message) -> () in
                self.authenticationFailureHandler(error, code: message)
                return
        }
    }
    func authenticationSuccessHandlerList(response:AnyObject?)
    {
        if let json = response as? [String: AnyObject]
        {
            channelDetails = json["channels"] as! NSMutableArray
            setChannelDetails()
        }
        else
        {
            ErrorManager.sharedInstance.inValidResponseError()
        }
    }
    func setChannelDetails()
    {
        self.readImageFromDataBase()

        
        for var index = 0; index < channelDetails.count; index++
        {
            let channelName = channelDetails[index].valueForKey("channel_name") as! String
            let channelId = channelDetails[index].valueForKey("channel_detail_id")
            channelDict[channelName] = channelId
            
            
        }
        if dummyImagesDataSourceDatabase.count > 0
        {
            for(var i = dummyImagesDataSourceDatabase.count-1 ; i >= 0 ; i--)
            {
                
                uploadData( i,completion: { (result) -> Void in
                    
                })
            }
        }

        
    }
    func readImageFromDataBase()
    {
        let cameraController = IPhoneCameraViewController()
        
        if snapShots.count > 0
        {
            let snapShotsKeys = snapShots.allKeys as NSArray
            
            let descriptor: NSSortDescriptor = NSSortDescriptor(key: nil, ascending: false)
            let sortedSnapShotsKeys: NSArray = snapShotsKeys.sortedArrayUsingDescriptors([descriptor])
            
            let screenRect : CGRect = UIScreen.mainScreen().bounds
            let screenWidth = screenRect.size.width
            let screenHeight = screenRect.size.height
            let checkValidation = NSFileManager.defaultManager()
            for var index = 0; index < sortedSnapShotsKeys.count; index++
            {
                if let thumbNailImagePath = snapShots.valueForKey(sortedSnapShotsKeys[index] as! String)
                {
                    if (checkValidation.fileExistsAtPath(thumbNailImagePath as! String))
                    {
                        
                        let imageToConvert = UIImage(data: NSData(contentsOfFile: thumbNailImagePath as! String)!)
                        let sizeThumb = CGSizeMake(70,70)
                        let sizeFull = CGSizeMake(screenWidth*4,screenHeight*3)
                        let imageAfterConversionThumbnail = cameraController.thumbnaleImage(imageToConvert, scaledToFillSize: sizeThumb)
                        let imageAfterConversionFullscreen = cameraController.thumbnaleImage(imageToConvert, scaledToFillSize: sizeFull)
                    if media == "video"
                    {
                        dummyImagesDataSourceDatabase.append([thumbImageKey:imageAfterConversionFullscreen,fullImageKey:imageAfterConversionFullscreen!])
                        }
                        else
                    {
                        dummyImagesDataSourceDatabase.append([thumbImageKey:imageAfterConversionThumbnail,fullImageKey:imageAfterConversionFullscreen!])
                        }
                    }
                }
            }
            
            if dummyImagesDataSourceDatabase.count > 0
            {
                if let imagePath = dummyImagesDataSourceDatabase[0][fullImageKey]
                {
                    print(imagePath)
                }
            }
        }
    }

    func authenticationFailureHandler(error: NSError?, code: String)
    {
        print("message = \(code) andError = \(error?.localizedDescription) ")
        
        if !self.requestManager.validConnection() {
            ErrorManager.sharedInstance.noNetworkConnection()
        }
        else if code.isEmpty == false {
            ErrorManager.sharedInstance.mapErorMessageToErrorCode(code)
        }
        else{
            ErrorManager.sharedInstance.inValidResponseError()
        }
    }
    func authenticationSuccessHandlerSignedURL(response:AnyObject? , rowIndex : Int ,completion: (result: String) -> Void)
    {
        //  fetchCollectionViewDataSource()
        //  self.readImageFromDataBase()
        // photoThumpCollectionView.reloadData()
        
        if let json = response as? [String: AnyObject]
        {
            
            
            if let name = json["UploadObjectUrl"]{
                signedURLResponse.setValue(name, forKey: "UploadObjectUrl")
            }
            if let name = json["ObjectName"]{
                signedURLResponse.setValue(name, forKey: "ObjectName")
            }
            if let name = json["UploadThumbnailUrl"]{
                signedURLResponse.setValue(name, forKey: "UploadThumbnailUrl")
            }
            if let name = json["MediaDetailId"]{
                
                signedURLResponse.setValue(name, forKey: "mediaId")
            }

            
            
            if dummyImagesDataSourceDatabase.count > 0
            {
                
                //                let mediaPath = medianameArray[rowIndex]
                //                if mediaPath.pathExtension == "mov"
                //                {
                //
                //                    print("it has extension")
                //
                //
                //                }
                var dict = dummyImagesDataSourceDatabase[rowIndex]
                let  uploadImageFull = dict[fullImageKey]
                let imageData : NSData
                if media == "video"
                {
                   // NSData *movieData = [NSData dataWithContentsOfURL:videoPath];

                     imageData = NSData(contentsOfURL: videoPath)!

                    
                }
                else
                {
                  imageData = UIImageJPEGRepresentation(uploadImageFull!, 0.5)!

                }
                //  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                //All stuff here
                //  self.uploadFullImage(imageData!, row: rowIndex )
                self.uploadFullImage(imageData, row: rowIndex , completion: { (result) -> Void in
                    
                    if result == "Success"
                    {
                        
                        self.uploadThumbImage(rowIndex, completion: { (result) -> Void in
                            
                            if result == "Success"
                            {
                                if self.dummyImagesDataSourceDatabase.count > 0
                                {
                                    self.dummyImagesDataSourceDatabase.removeFirst()
                                    
                                    
                                }
                                
                                if  self.dummyImagesDataSourceDatabase.count==0
                                {
                                    self.dummyImagesDataSourceDatabase.removeAll()
                                    
                                    self.deleteCOreData()
                                    
                                }
                                let defaults = NSUserDefaults .standardUserDefaults()
                                let userId = defaults.valueForKey(userLoginIdKey) as! String
                                let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
                                let mediaId = self.signedURLResponse.valueForKey("mediaId")!.stringValue

                                self.imageUploadManger.setDefaultMediaChannelMapping(userId, accessToken: accessToken, objectName: mediaId as String, success: { (response) -> () in
                                    self.authenticationSuccessHandlerForDefaultMediaMapping(response)
                                    }, failure: { (error, message) -> () in
                                        self.authenticationFailureHandlerForDefaultMediaMapping(error, code: message)
                                        
                                })
                                completion(result:"Success")
                                
                            }
                            else
                            {
                                print("failed thumb upload")
                                completion(result:"Failed")
                                
                            }
                        })
                    }
                    else
                    {
                        print("failed full upload")
                        completion(result:"Failed")
                        
                    }
                })
                
                // })
                
            }
        }
        else
        {
            ErrorManager.sharedInstance.inValidResponseError()
        }
        
        
        
    }
    func deleteCOreData()
    {
        let appDel = UIApplication.sharedApplication().delegate as! AppDelegate
        let context: NSManagedObjectContext = appDel.managedObjectContext
        let fetchRequest: NSFetchRequest = NSFetchRequest(entityName: "SnapShots")
        fetchRequest.returnsObjectsAsFaults = false
        
        do
        {
            let results = try context.executeFetchRequest(fetchRequest)
            for managedObject in results
            {
                let managedObjectData:NSManagedObject = managedObject as! NSManagedObject
                context.deleteObject(managedObjectData)
            }
            
        } catch let error as NSError {
            print("Detele all data ")
        }
        
        
    }

    func authenticationSuccessHandlerForDefaultMediaMapping(response:AnyObject?)
    {
        
    }
    func authenticationFailureHandlerForDefaultMediaMapping(error: NSError?, code: String)
    {
        print("message = \(code) andError = \(error?.localizedDescription) ")
        
        if !self.requestManager.validConnection() {
            ErrorManager.sharedInstance.noNetworkConnection()
        }
        else if code.isEmpty == false {
            ErrorManager.sharedInstance.mapErorMessageToErrorCode(code)
        }
        else{
            ErrorManager.sharedInstance.inValidResponseError()
        }
        
    }
    func authenticationFailureHandlerSignedURL(error: NSError?, code: String)
    {
        print("message = \(code) andError = \(error?.localizedDescription) ")
        
        if !self.requestManager.validConnection() {
            ErrorManager.sharedInstance.noNetworkConnection()
        }
        else if code.isEmpty == false {
            ErrorManager.sharedInstance.mapErorMessageToErrorCode(code)
        }
        else{
            ErrorManager.sharedInstance.inValidResponseError()
        }
    }
    func uploadFullImage( imagedata : NSData ,row : Int ,completion: (result: String) -> Void)
    {
        taskIndex = row
        progressDictionary.addObject(0.0)
      
        let url = NSURL(string: signedURLResponse.valueForKey("UploadObjectUrl") as! String) //Remember to put ATS exception if the URL is not https
        let request = NSMutableURLRequest(URL: url!)
        request.HTTPMethod = "PUT"
//        let mimeType = "text/csv"
//        let contentTypeString = "Content-Type: \(mimeType)\r\n\r\n"

        let session = NSURLSession(configuration:NSURLSessionConfiguration.defaultSessionConfiguration(), delegate: self, delegateQueue: NSOperationQueue.mainQueue())
        request.HTTPBody = imagedata
        let dataTask = session.dataTaskWithRequest(request) { (data, response, error) -> Void in
            if error != nil {
                //handle error
                //  completion(result:"Failed")
                
            }
            else {
                let jsonStr = NSString(data: data!, encoding: NSUTF8StringEncoding)
                print("Parsed JSON: '\(jsonStr)'")
                //  completion(result:"Success")
                
                self.progressDictionary[self.taskIndex] = 1.0
                // self.delegate?.uploadProgress(progressDictionary)
               // [NSNotificationCenter.defaultCenter().addObserver(self, selector:"uploadProgress:", name:"Notification" , object:progressDictionary)]
                
                
                if PhotoViewerInstance.controller != nil
                {
                    let controller = PhotoViewerInstance.controller as! PhotoViewerViewController
                    controller.uploadProgress(self.progressDictionary)
                }
                if(self.media == "video")
                {
                let fileManager = NSFileManager.defaultManager()
                
               
                let checkValidation = NSFileManager.defaultManager()

                do {
                    if (checkValidation.fileExistsAtPath(self.videoPath.path!))
                    {
                    try fileManager.removeItemAtURL(self.videoPath)
                    }
                }
                catch let error as NSError {
                    print("Ooops! Something went wrong: \(error)")
                }
                }
                
            }
            //  completion(result:"Success")
            
        }
        completion(result:"Success")
        
        dataTask.resume()
    }
    
    func uploadThumbImage(row : Int,completion: (result: String) -> Void)
    {
        var dict = dummyImagesDataSourceDatabase[row]
        let  uploadImageThumb = dict[thumbImageKey]
        print(uploadImageThumb)
        
        let imageData = UIImageJPEGRepresentation(uploadImageThumb!, 0.5)
        if(imageData == nil)
        {
            return
        }
        let url = NSURL(string: signedURLResponse.valueForKey("UploadThumbnailUrl") as! String) //Remember to put ATS exception if the URL is not https
        let request = NSMutableURLRequest(URL: url!)
        request.HTTPMethod = "PUT"
        let session = NSURLSession(configuration:NSURLSessionConfiguration.defaultSessionConfiguration(), delegate: self, delegateQueue: NSOperationQueue.mainQueue())
        request.HTTPBody = imageData
        let dataTask = session.dataTaskWithRequest(request) { (data, response, error) -> Void in
            if error != nil {
                //  completion(result:"Failed")
                
                //handle error
            }
            else {
                let jsonStr = NSString(data: data!, encoding: NSUTF8StringEncoding)
                print("Parsed JSON for thumbanil: '\(jsonStr)'")
                //    completion(result:"Success")
                
                
            }
            // completion(result:"Success")
            
        }
        completion(result:"Success")
        
        dataTask.resume()
        
        
        
    }
    
    func uploadData (index : Int ,completion: (result: String) -> Void)
    {
        
        
        var dict = dummyImagesDataSourceDatabase[index]
        
        let  uploadImageFull = dict[fullImageKey]
        let imageData = UIImageJPEGRepresentation(uploadImageFull!, 0.5)
        
        // let imageData = UIImagePNGRepresentation(uploadImage!)
        let defaults = NSUserDefaults .standardUserDefaults()
        let userId = defaults.valueForKey(userLoginIdKey) as! String
        let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
        if(imageData == nil )  {
            
        }
        else
        {
            
            let defaults = NSUserDefaults .standardUserDefaults()
            let userId = defaults.valueForKey(userLoginIdKey) as! String
            let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
            
            self.imageUploadManger.getSignedURL(userId, accessToken: accessToken, mediaType: media as String,success: { (response) -> () in
                //    self.authenticationSuccessHandlerSignedURL(response,rowIndex: rowIndex)
                self.authenticationSuccessHandlerSignedURL(response, rowIndex: index, completion: { (result) -> Void in
                    completion(result : "Success")
                })
                }, failure: { (error, message) -> () in
                    completion(result: "Failed")
                    self.authenticationFailureHandlerSignedURL(error, code: message)
                    //   return
                    
            })
            
        }
    }
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?)
    {
        let myAlert = UIAlertView(title: "Alert", message: error?.localizedDescription, delegate: nil, cancelButtonTitle: "Ok")
        myAlert.show()
        
        //   self.uploadButton.enabled = true
        print("Task completed -----------------------------:")

    }
    
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64)
    {
        let uploadProgress:Float = Float(totalBytesSent) / Float(totalBytesExpectedToSend)
     //   progrs=uploadProgress
     //   [photoThumpCollectionView .reloadData()]
        print(uploadProgress)
        progressDictionary[taskIndex] = uploadProgress
       // self.delegate?.uploadProgress(progressDictionary)
    [NSNotificationCenter.defaultCenter().addObserver(self, selector:"uploadProgress:", name:"Notification" , object:progressDictionary)]
       
        
        if PhotoViewerInstance.controller != nil
        {
        let controller = PhotoViewerInstance.controller as! PhotoViewerViewController
        controller.uploadProgress(progressDictionary)
        }
    //    let controller = PhotoViewerViewController.sharedInstance

     //   controller.uploadProgress(progressDictionary)
       if uploadProgress == 1.0
        {
            
            
        }
        
    }
    
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveResponse response: NSURLResponse, completionHandler: (NSURLSessionResponseDisposition) -> Void)
    {
        //  self.uploadButton.enabled = true
        
        print("Task completed:")
 
        
    }

}