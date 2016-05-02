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
    var shotDict : NSMutableDictionary = NSMutableDictionary()
    var channelDetails: NSMutableArray = NSMutableArray()
    let requestManager = RequestManager.sharedInstance
    var dummyImagesDataSourceDatabase :[[String:UIImage]]  = [[String:UIImage]]()
    
    var cacheDictionary : [[String:AnyObject]]  = [[String:AnyObject]]()
    let thumbImageKey = "thumbImage"
    let fullImageKey = "fullImageKey"
    let imageUploadManger = ImageUpload.sharedInstance
    let signedURLResponse: NSMutableDictionary = NSMutableDictionary()
    var delegate : uploadProgressDelegate?
    var progressDictionary : NSMutableArray = NSMutableArray()
    var checksDataSourceDatabase :[[String:UIImage]]  = [[String:UIImage]]()
    var checkThumb : Bool = false
    var taskIndex :  Int = 0
    var media : NSString = ""
    var videoPath : NSURL = NSURL()
    var thumbnailpath : NSString = ""
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
        //  self.readImageFromDataBase()
        self.readImage();
        
        for index in 0 ..< channelDetails.count
        {
            let channelName = channelDetails[index].valueForKey("channel_name") as! String
            let channelId = channelDetails[index].valueForKey("channel_detail_id")
            channelDict[channelName] = channelId
            
            
        }
        if shotDict.count > 0
        {
            //            for(var i = dummyImagesDataSourceDatabase.count-1 ; i > 0 ; --i)
            //            {
            let i=0;
            print( "checking count =-------- %d",i)
            let qualityOfServiceClass = QOS_CLASS_BACKGROUND
            let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
            dispatch_async(backgroundQueue, {
                self.uploadData( i,completion: { (result) -> Void in
                    
                })
            })
            
            // }
        }
        
        
    }
    func clearTempFolder() {
        let fileManager = NSFileManager.defaultManager()
        let tempFolderPath = NSTemporaryDirectory()
        do {
            let filePaths = try fileManager.contentsOfDirectoryAtPath(tempFolderPath)
            for filePath in filePaths {
                try fileManager.removeItemAtPath(NSTemporaryDirectory() + filePath)
            }
        } catch {
            print("Could not clear temp folder: \(error)")
        }
    }
    func readImage()
    {
        let cameraController = IPhoneCameraViewController()
        
        if shotDict.count > 0
        {
            
            let snapShotsKeys = shotDict.allKeys as NSArray
            
            let descriptor: NSSortDescriptor = NSSortDescriptor(key: nil, ascending: false)
            let sortedSnapShotsKeys: NSArray = snapShotsKeys.sortedArrayUsingDescriptors([descriptor])
            
            let screenRect : CGRect = UIScreen.mainScreen().bounds
            let screenWidth = screenRect.size.width
            let screenHeight = screenRect.size.height
            let checkValidation = NSFileManager.defaultManager()
            for index in 0 ..< sortedSnapShotsKeys.count
            {
                if let thumbNailImagePath = shotDict.valueForKey(sortedSnapShotsKeys[index] as! String)
                {
                    if (checkValidation.fileExistsAtPath(thumbNailImagePath as! String))
                    {
                        thumbnailpath = thumbNailImagePath as! NSString
                        
                        let imageToConvert = UIImage(data: NSData(contentsOfFile: thumbNailImagePath as! String)!)
                        let sizeThumb = CGSizeMake(70,70)
                        let sizeFull = CGSizeMake(screenWidth*4,screenHeight*3)
                        let imageAfterConversionThumbnail = cameraController.thumbnaleImage(imageToConvert, scaledToFillSize: sizeThumb)
                        let imageAfterConversionFullscreen = cameraController.thumbnaleImage(imageToConvert, scaledToFillSize: sizeFull)
                        if media == "video"
                        {
                            let sizeFull = CGSizeMake(140,140)

                            let imageAfterConversionFullscreen = cameraController.thumbnaleImage(imageToConvert, scaledToFillSize: sizeFull)

                            dummyImagesDataSourceDatabase.append([thumbImageKey:imageAfterConversionFullscreen,fullImageKey:imageAfterConversionFullscreen!])
                        }
                        else
                        {
                            dummyImagesDataSourceDatabase.append([thumbImageKey:imageAfterConversionThumbnail,fullImageKey:imageAfterConversionFullscreen!])
                        }
                    }
                }
            }
            checksDataSourceDatabase = dummyImagesDataSourceDatabase
            
            
            
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
            for index in 0 ..< sortedSnapShotsKeys.count
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
            checksDataSourceDatabase = dummyImagesDataSourceDatabase
            
            if dummyImagesDataSourceDatabase.count > 0
            {
                //                if let imagePath = dummyImagesDataSourceDatabase[0][fullImageKey]
                //                {
                //                    print(imagePath)
                //                }
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
           
            if checksDataSourceDatabase.count > 0
            {
                var dict = dummyImagesDataSourceDatabase[rowIndex]
                let  uploadImageFull = dict[fullImageKey]
                let imageData : NSData
                if media == "video"
                {
                    signedURLResponse.setValue("video", forKey: "type")
                    // NSData *movieData = [NSData dataWithContentsOfURL:videoPath];
                    if ((videoPath.path?.isEmpty) != nil)
                    {
                        if let imageDatadup = NSData(contentsOfURL: videoPath){
                            imageData = imageDatadup
                        }
                        else{
                            return
                        }
                    }
                    else
                    {
                        return
                    }
                }
                else
                {
                    signedURLResponse.setValue("image", forKey: "type")

                    imageData = UIImageJPEGRepresentation(uploadImageFull!, 0.5)!
                }
            
                saveToCache()
                
                self.uploadFullImage(imageData, row: rowIndex , completion: { (result) -> Void in
                    
                    if result == "Success"
                    {
                        self.uploadThumbImage(rowIndex, completion: { (result) -> Void in
                            
                            if result == "Success"
                            {
                                    self.dummyImagesDataSourceDatabase.removeAll()
                                   self.checksDataSourceDatabase.removeAll()
                                    self.deleteCOreData()
                            //       self.shotDict.removeAllObjects()
                          //     self.snapShots.removeAllObjects()
                                let defaults = NSUserDefaults .standardUserDefaults()
                                let userId = defaults.valueForKey(userLoginIdKey) as! String
                                let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
                                let mediaId = self.signedURLResponse.valueForKey("mediaId")?.stringValue
                                
                                self.imageUploadManger.setDefaultMediaChannelMapping(userId, accessToken: accessToken, objectName: mediaId! as String, success: { (response) -> () in
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
            }
        }
        else
        {
            ErrorManager.sharedInstance.inValidResponseError()
        }
        
        
        
    }
    func saveToCache()
    {
        let mediaCachemanager = MediaCache.sharedInstance
        mediaCachemanager.setResponse(signedURLResponse)
        for( var i = 0 ; i < dummyImagesDataSourceDatabase.count ; i += 1 )
        {
            if(mediaCachemanager.createCa7chDirectory())
            {
                let path = mediaCachemanager.getDocumentsURL().URLByAppendingPathComponent((self.signedURLResponse.valueForKey("mediaId")?.stringValue)!)
                mediaCachemanager.saveImage(dummyImagesDataSourceDatabase[i][thumbImageKey]!, path: String(String(path)+"thumb"))
                mediaCachemanager.saveImage(dummyImagesDataSourceDatabase[i][fullImageKey]!, path: String(String(path)+"full"))
            }
            
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
            print("Detele all data \(error)")
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
          self.checkThumb = true
        let url = NSURL(string: signedURLResponse.valueForKey("UploadObjectUrl") as! String) //Remember to put ATS exception if the URL is not https
        let request = NSMutableURLRequest(URL: url!)
        request.HTTPMethod = "PUT"
        let session = NSURLSession(configuration:NSURLSessionConfiguration.defaultSessionConfiguration(), delegate: self, delegateQueue: NSOperationQueue.mainQueue())
        request.HTTPBody = imagedata
        let dataTask = session.dataTaskWithRequest(request) { (data, response, error) -> Void in
            if error != nil {
                //handle error
                  completion(result:"Failed")
                
            }
            else {
                let jsonStr = NSString(data: data!, encoding: NSUTF8StringEncoding)
                print("Parsed JSON: '\(jsonStr)'")
                //  completion(result:"Success")
                
                self.progressDictionary[self.taskIndex] = 1.0
                self.checkThumb = false
                // self.delegate?.uploadProgress(progressDictionary)
                // [NSNotificationCenter.defaultCenter().addObserver(self, selector:"uploadProgress:", name:"Notification" , object:progressDictionary)]
                print("inside parsed full json")

                
                if PhotoViewerInstance.controller != nil
                {
                    let controller = PhotoViewerInstance.controller as! PhotoViewerViewController
                    controller.uploadProgress(self.progressDictionary)
                }
                if PhotoViewerInstance.iphoneCam != nil
                {
                    let controller = PhotoViewerInstance.iphoneCam as! IPhoneCameraViewController
                    controller.uploadprogress(2.0)
                }
                
                self.deletePathContent()
                self.clearTempFolder()
                
                completion(result:"Success")
  
            }
            //  completion(result:"Success")
            
        }
        
        dataTask.resume()
    }
    func deletePathContent()
    {
        
        
        let documents2 = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        
        
        let fm2 = NSFileManager.defaultManager()
        do {
            let items = try fm2.contentsOfDirectoryAtPath(documents2)
            
            for item in items {
                print("Items before------> \(item)")
            }
        } catch {
            // failed to read directory – bad permissions, perhaps?
        }
        let documents = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let fm = NSFileManager.defaultManager()
        do {
            let items = try fm.contentsOfDirectoryAtPath(documents)
            
            for item in items {
                if self.thumbnailpath.lastPathComponent == item
                {
                    // try fm.removeItemAtPath(self.thumbnailpath as String)
                    
                    print("Removed \(item)")
                    
                }
               // print("Found \(item)")
            }
        } catch {
            // failed to read directory – bad permissions, perhaps?
        }
        let fileManager = NSFileManager.defaultManager()
        
        
        let checkValidation = NSFileManager.defaultManager()
        
        do {
            if self.media == "video"
            {
                if (checkValidation.fileExistsAtPath(self.videoPath.path!))
                {
                    try fileManager.removeItemAtURL(self.videoPath)
                }
                if (checkValidation.fileExistsAtPath(self.thumbnailpath as String))
                {
                    try fm.removeItemAtPath(self.thumbnailpath as String)
                    print("Removed error )")
                    
                }
            }
            else
            {
                if (checkValidation.fileExistsAtPath(self.thumbnailpath as String))
                {
                    try fm.removeItemAtPath(self.thumbnailpath as String)
                    print("Removed error else)")
                    
                    
                    
                }
            }
        }
        catch let error as NSError {
            print("Ooops! Something went wrong: \(error)")
        }
        
        let documents1 = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        
        
        let fm1 = NSFileManager.defaultManager()
        do {
            let items = try fm1.contentsOfDirectoryAtPath(documents1)
            
            for item in items {
            print("Items after------> \(item)")
            }
        } catch {
            // failed to read directory – bad permissions, perhaps?
        }
    }
    
 
    
    func uploadThumbImage(row : Int,completion: (result: String) -> Void)
    {
        if(dummyImagesDataSourceDatabase.count > 0)
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
               // self.checkThumb = true

                let controller = PhotoViewerInstance.iphoneCam as! IPhoneCameraViewController
                controller.uploadprogress(1.0)
                
            }
            // completion(result:"Success")
            
        }
        completion(result:"Success")
        
        dataTask.resume()
        
        }
        
    }
    
    func uploadData (index : Int ,completion: (result: String) -> Void)
    {
        if(dummyImagesDataSourceDatabase.count > 0)
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
        // self.delegate?.uploadProgress(progressDictionary)
//        [NSNotificationCenter.defaultCenter().addObserver(self, selector:"uploadProgress:", name:"Notification" , object:progressDictionary)]
        print("inside url session")
        if(checkThumb)
        {
            progressDictionary[taskIndex] = uploadProgress

        if PhotoViewerInstance.controller != nil
        {
            let controller = PhotoViewerInstance.controller as! PhotoViewerViewController
            controller.uploadProgress(progressDictionary)
        }
    }
    }
    
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveResponse response: NSURLResponse, completionHandler: (NSURLSessionResponseDisposition) -> Void)
    {
        //  self.uploadButton.enabled = true
        
        print("Task completed:")
        
        
    }
    
}
