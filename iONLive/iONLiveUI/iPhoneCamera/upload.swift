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
    
    var snapShots : NSMutableDictionary = NSMutableDictionary()
    var shotDict : NSMutableDictionary = NSMutableDictionary()
    let requestManager = RequestManager.sharedInstance
    var dummyImagesDataSourceDatabase :[[String:UIImage]]  = [[String:UIImage]]()
    var cacheDictionary : [[String:AnyObject]]  = [[String:AnyObject]]()
    var uploadMediaDict : [[String:AnyObject]]  = [[String:AnyObject]]()
    let thumbImageKey = "thumbImage"
    let fullImageKey = "fullImageKey"
    let imageUploadManger = ImageUpload.sharedInstance
    let signedURLResponse: NSMutableDictionary = NSMutableDictionary()
    var delegate : uploadProgressDelegate?
    var progressDictionary : [[String:AnyObject]]  = [[String:AnyObject]]()
    var checksDataSourceDatabase :[[String:UIImage]]  = [[String:UIImage]]()
    var checkThumb : Bool = false
    var taskIndex :  Int = 0
    var media : NSString = ""
    var videoPath : NSURL = NSURL()
    var thumbnailpath : NSString = ""
    var mediaId :String = String()
    let thumbSignedUrlKey = "thumbnail_name_SignedUrl"
    let fullSignedUrlKey = "gcs_object_name_SignedUrl"
    let mediaIdKey = "media_detail_id"
    let mediaTypeKey = "gcs_object_type"
    let timeStampKey = "created_time_stamp"
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
        self.readImage();
        if shotDict.count > 0
        {
            let i=0;
            let qualityOfServiceClass = QOS_CLASS_BACKGROUND
            let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
            dispatch_async(backgroundQueue, {
                self.uploadData( i,completion: { (result) -> Void in
                })
            })
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
     //   print(shotDict.count)
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
    func  loadInitialViewController(){
        let documentsPath = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0] + "/GCSCA7CH"
        
        if(NSFileManager.defaultManager().fileExistsAtPath(documentsPath))
        {
            let fileManager = NSFileManager.defaultManager()
            do {
                try fileManager.removeItemAtPath(documentsPath)
            }
            catch let error as NSError {
                print("Ooops! Something went wrong: \(error)")
            }
            FileManagerViewController.sharedInstance.createParentDirectory()
        }
        else{
            FileManagerViewController.sharedInstance.createParentDirectory()
        }
        let defaults = NSUserDefaults .standardUserDefaults()
        let deviceToken = defaults.valueForKey("deviceToken") as! String
        defaults.removePersistentDomainForName(NSBundle.mainBundle().bundleIdentifier!)
        defaults.setValue(deviceToken, forKey: "deviceToken")
        defaults.setObject(1, forKey: "shutterActionMode");
        let sharingStoryboard = UIStoryboard(name:"Authentication", bundle: nil)
        let channelItemListVC = sharingStoryboard.instantiateViewControllerWithIdentifier("AuthenticateNavigationController") as! AuthenticateNavigationController
        channelItemListVC.navigationController?.navigationBarHidden = true
        self.navigationController?.presentViewController(channelItemListVC, animated: true, completion: nil)
    }
    func authenticationFailureHandler(error: NSError?, code: String)
    {
        print("message = \(code) andError = \(error?.localizedDescription) ")
        
        if !self.requestManager.validConnection() {
            ErrorManager.sharedInstance.noNetworkConnection()
        }
        else if code.isEmpty == false {
            ErrorManager.sharedInstance.mapErorMessageToErrorCode(code)
            if((code == "USER004") || (code == "USER005") || (code == "USER006")){
                loadInitialViewController()
            }
        }
        else{
            ErrorManager.sharedInstance.inValidResponseError()
        }
    }
    func authenticationSuccessHandlerSignedURL(response:AnyObject? , rowIndex : Int ,completion: (result: String) -> Void)
    {
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
                    if ((videoPath.path?.isEmpty) != nil)
                    {
                        if let imageDatadup = NSData(contentsOfURL: videoPath){
                            imageData = imageDatadup
                            
                         //   if let imageData = data as NSData? {
                                let mediaIdForFilePath = "\(self.signedURLResponse.valueForKey("mediaId")!)"
                                let parentPath = FileManagerViewController.sharedInstance.getParentDirectoryPath().absoluteString
                                let savingPath = "\(parentPath)/\(mediaIdForFilePath)video.mov"
                                let url = NSURL(fileURLWithPath: savingPath)
                                let writeFlag = imageData.writeToURL(url, atomically: true)
                                if(writeFlag){
                                    
                                }
                            
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
                let mediaId = self.signedURLResponse.valueForKey("mediaId")
                let defaults = NSUserDefaults .standardUserDefaults()
                if defaults.objectForKey("uploaObjectDict") != nil{
                    let data  =  defaults.objectForKey("uploaObjectDict") as! NSData
                    uploadMediaDict =  NSKeyedUnarchiver.unarchiveObjectWithData(data) as! [[String : AnyObject]]
                }
                let type = self.signedURLResponse.valueForKey("type")
                let cameraController = IPhoneCameraViewController()
                var imageToConvert : UIImage = UIImage()

                if( String(type!) == "video")
                {
                    var dict = dummyImagesDataSourceDatabase[rowIndex]
                    let  uploadImageThumb = dict[thumbImageKey]
                    imageToConvert = uploadImageThumb!
                }
                else
                {
                    imageToConvert = UIImage(data:imageData)!
                }
                let sizeThumb = CGSizeMake(70,70)
                let imageAfterConversionThumbnail = cameraController.thumbnaleImage(imageToConvert, scaledToFillSize: sizeThumb)
                print(imageAfterConversionThumbnail)
                uploadMediaDict.append([mediaIdKey : mediaId!,mediaTypeKey : self.signedURLResponse.valueForKey("type") as! String,timeStampKey:"",thumbSignedUrlKey :signedURLResponse.valueForKey("UploadThumbnailUrl") as! String!,fullSignedUrlKey : signedURLResponse.valueForKey("UploadObjectUrl") as! String!,thumbImageKey:imageAfterConversionThumbnail,fullImageKey:imageAfterConversionThumbnail])
                let data = NSKeyedArchiver.archivedDataWithRootObject(uploadMediaDict)
                defaults.setObject(data , forKey :"uploaObjectDict")
                if PhotoViewerInstance.controller != nil
                {
                    let controller = PhotoViewerInstance.controller as! PhotoViewerViewController
                    controller.uploadMediaProgress()
                }
                self.uploadFullImage(imageData, row: rowIndex , completion: { (result) -> Void in
                    if result == "Success"
                    {
                        self.uploadThumbImage(rowIndex, completion: { (result) -> Void in
                            if result == "Success"
                            {
                                
                                print(self.dummyImagesDataSourceDatabase.count)
                                self.dummyImagesDataSourceDatabase.removeAll()
                                self.checksDataSourceDatabase.removeLast()
                                // self.deleteCOreData()
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
                                completion(result:"Failed")
                            }
                        })
                    }
                    else
                    {
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
            if((code == "USER004") || (code == "USER005") || (code == "USER006")){
                loadInitialViewController()
            }
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
            if((code == "USER004") || (code == "USER005") || (code == "USER006")){
                loadInitialViewController()
            }
        }
        else{
            ErrorManager.sharedInstance.inValidResponseError()
        }
    }
    func saveProgressToDefault(value : Float)
    {
        let defaults = NSUserDefaults .standardUserDefaults()
        if defaults.objectForKey("ProgressDict") != nil{
            //  let data  =  defaults.objectForKey("ProgressDict")!
            progressDictionary = NSUserDefaults .standardUserDefaults().valueForKey("ProgressDict") as! NSArray as! [[String : AnyObject]]
        }
        progressDictionary.append([mediaIdKey:(signedURLResponse.valueForKey("mediaId")?.stringValue)!,"progress": value])
        //  let data = NSKeyedArchiver.archivedDataWithRootObject(progressDictionary)
        defaults.setValue(progressDictionary , forKey :"ProgressDict")
    }
    
    func uploadFullImage( imagedata : NSData ,row : Int ,completion: (result: String) -> Void)
    {
        taskIndex = row
        let value : Float = 0.0
        saveProgressToDefault(value)
        self.checkThumb = true
        let url = NSURL(string: signedURLResponse.valueForKey("UploadObjectUrl") as! String)
        let request = NSMutableURLRequest(URL: url!)
        request.HTTPMethod = "PUT"
        let session = NSURLSession(configuration:NSURLSessionConfiguration.defaultSessionConfiguration(), delegate: self, delegateQueue: NSOperationQueue.mainQueue())
        request.HTTPBody = imagedata
        let dataTask = session.dataTaskWithRequest(request) { (data, response, error) -> Void in
            if error != nil {
                completion(result:"Failed")
            }
            else {
                let jsonStr = NSString(data: data!, encoding: NSUTF8StringEncoding)
                self.deletePathContent()
                self.clearTempFolder()
                self.completeProgress()
                completion(result:"Success")
            }
        }
        dataTask.resume()
    }
    func completeProgress()
    {
        let value : Float = 1.0
        let defaults = NSUserDefaults .standardUserDefaults()
        if defaults.objectForKey("ProgressDict") != nil{
            //  let data  =  defaults.objectForKey("ProgressDict") as! NSData
            progressDictionary =  NSUserDefaults .standardUserDefaults().valueForKey("ProgressDict") as! NSArray as![[String : AnyObject]]
        }
        for(var i = 0 ; i < progressDictionary.count ; i++)
        {
            if progressDictionary[i][self.mediaIdKey]?.stringValue == mediaId
            {
                progressDictionary[i]["progress"] = value
            }
        }
        self.checkThumb = false
        print(progressDictionary)
        defaults.setValue(progressDictionary, forKey: "ProgressDict")
        if PhotoViewerInstance.controller != nil
        {
            let controller = PhotoViewerInstance.controller as! PhotoViewerViewController
            controller.uploadProgress(progressDictionary)
        }
        if PhotoViewerInstance.iphoneCam != nil
        {
            let controller = PhotoViewerInstance.iphoneCam as! IPhoneCameraViewController
            controller.uploadprogress(2.0)
        }
        
    }
    func deletePathContent()
    {
        let documents = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let fm = NSFileManager.defaultManager()
        do {
            let items = try fm.contentsOfDirectoryAtPath(documents)
            
            for item in items {
                if self.thumbnailpath.lastPathComponent == item
                {
                }
            }
        } catch {
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
                }
            }
            else
            {
                if (checkValidation.fileExistsAtPath(self.thumbnailpath as String))
                {
                    try fm.removeItemAtPath(self.thumbnailpath as String)
                }
            }
        }
        catch let error as NSError {
            print("Ooops! Something went wrong: \(error)")
        }
    }
    
    func uploadThumbImage(row : Int,completion: (result: String) -> Void)
    {
        if(dummyImagesDataSourceDatabase.count > 0)
        {
            var dict = dummyImagesDataSourceDatabase[row]
            let  uploadImageThumb = dict[thumbImageKey]
            let imageData = UIImageJPEGRepresentation(uploadImageThumb!, 0.5)
            if(imageData == nil)
            {
                return
            }
            let url = NSURL(string: signedURLResponse.valueForKey("UploadThumbnailUrl") as! String)
            let request = NSMutableURLRequest(URL: url!)
            request.HTTPMethod = "PUT"
            let session = NSURLSession(configuration:NSURLSessionConfiguration.defaultSessionConfiguration(), delegate: self, delegateQueue: NSOperationQueue.mainQueue())
            request.HTTPBody = imageData
            let dataTask = session.dataTaskWithRequest(request) { (data, response, error) -> Void in
                if error != nil {
                }
                else {
                    let jsonStr = NSString(data: data!, encoding: NSUTF8StringEncoding)
                    let controller = PhotoViewerInstance.iphoneCam as! IPhoneCameraViewController
                    controller.uploadprogress(1.0)
                    
                }
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
                    self.authenticationSuccessHandlerSignedURL(response, rowIndex: index, completion: { (result) -> Void in
                        completion(result : "Success")
                    })
                    }, failure: { (error, message) -> () in
                        completion(result: "Failed")
                        self.authenticationFailureHandlerSignedURL(error, code: message)
                })
                
            }
        }
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?)
    {
        let myAlert = UIAlertView(title: "Alert", message: error?.localizedDescription, delegate: nil, cancelButtonTitle: "Ok")
        myAlert.show()
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64)
    {
        mediaId = String(signedURLResponse.valueForKey("mediaId")!)
        
        let uploadProgress:Float = Float(totalBytesSent) / Float(totalBytesExpectedToSend)
        print(uploadProgress)
        updateProgressToDefault(uploadProgress)
        
    }
    func updateProgressToDefault(progress:Float)
    {
        //if(checkThumb)
        //  {
        
        let defaults = NSUserDefaults .standardUserDefaults()
        if defaults.objectForKey("ProgressDict") != nil{
            //  let data  =  defaults.objectForKey("ProgressDict")!
            progressDictionary = NSUserDefaults .standardUserDefaults().valueForKey("ProgressDict") as! NSArray as! [[String : AnyObject]]
        }
        for(var i = 0 ; i < progressDictionary.count ; i++)
        {
            print(String(progressDictionary[i][mediaIdKey]!))
            print(String(signedURLResponse.valueForKey("mediaId")!))
            if String(progressDictionary[i][mediaIdKey]!) == mediaId
            {
                progressDictionary[i]["progress"] = progress
            }
        }
   //     print(progressDictionary)
        
        defaults.setValue(progressDictionary, forKey: "ProgressDict")
        if PhotoViewerInstance.controller != nil
        {
            if(progressDictionary.count>0)
            {
            let controller = PhotoViewerInstance.controller as! PhotoViewerViewController
            controller.uploadProgress(progressDictionary)
            }
        }
    }
    
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveResponse response: NSURLResponse, completionHandler: (NSURLSessionResponseDisposition) -> Void)
    {
        print("Completed")
    }
    
}
