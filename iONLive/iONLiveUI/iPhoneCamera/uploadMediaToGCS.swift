//
//  upload1.swift
//  iONLive
//
//  Created by Sreeja on 01/07/16.
//  Copyright © 2016 Gadgeon. All rights reserved.
//

import UIKit

class uploadMediaToGCS: UIViewController, NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate {

    let cameraController = IPhoneCameraViewController()
    let imageUploadManager = ImageUpload.sharedInstance
    let requestManager = RequestManager.sharedInstance
    let mediaBeforeUploadCompleteManager = MediaBeforeUploadComplete.sharedInstance
    
    let defaults = NSUserDefaults .standardUserDefaults()
    
    var userId : String = String()
    var accessToken : String = String()
    
    var path : String = String()
    var media : String = String()
    var videoSavedURL : NSURL = NSURL()
    
    var imageFromDB : UIImage = UIImage()
    var imageAfterConversionThumbnail : UIImage = UIImage()
    
    var uploadThumbImageURLGCS : String = String()
    var uploadFullImageOrVideoURLGCS : String = String()
    var uploadImageNameForGCS : String = String()
    var mediaId : String = String()
    
    var videoData : NSData = NSData()
    
    var dataRowFromLocal : [String:AnyObject] = [String:AnyObject]()
    
    let thumbImageKey = "thumbImage"
    let fullImageKey = "fullImageKey"
    let thumbSignedUrlKey = "thumbnail_name_SignedUrl"
    let fullSignedUrlKey = "gcs_object_name_SignedUrl"
    let mediaIdKey = "media_detail_id"
    let mediaTypeKey = "gcs_object_type"
    let timeStampKey = "created_time_stamp"
    let progressKey = "progress"
    
    var progressDictionary : [[String:AnyObject]]  = [[String:AnyObject]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func initialise(){
        userId = defaults.valueForKey(userLoginIdKey) as! String
        accessToken = defaults.valueForKey(userAccessTockenKey) as! String
        
        getMediaFromDB()
    }
    
    //get image from local db
    func getMediaFromDB(){
        imageFromDB = FileManagerViewController.sharedInstance.getImageFromFilePath(path)!
        var sizeThumb : CGSize = CGSize()
        if(media == "image"){
            sizeThumb = CGSizeMake(70,70)
        }
        else{
            sizeThumb = CGSizeMake(140, 140)
        }
        imageAfterConversionThumbnail = cameraController.thumbnaleImage(imageFromDB, scaledToFillSize: sizeThumb)
        
        getSignedURLFromCloud()
    }
    
    //get signed url from cloud
    func getSignedURLFromCloud(){
        self.imageUploadManager.getSignedURL(userId, accessToken: accessToken, mediaType: media, success: { (response) -> () in
                self.authenticationSuccessHandlerSignedURL(response)
            }, failure: { (error, message) -> () in
                self.authenticationFailureHandler(error, code: message)
        })
    }
    
    func authenticationSuccessHandlerSignedURL(response:AnyObject?)
    {
        if let json = response as? [String: AnyObject]
        {
            uploadFullImageOrVideoURLGCS = json["UploadObjectUrl"] as! String
            uploadThumbImageURLGCS = json["UploadThumbnailUrl"] as! String
            let mediaDetailId = json["MediaDetailId"]
            mediaId = "\(mediaDetailId!)"
            uploadImageNameForGCS = json["ObjectName"] as! String
            self.saveImageToLocalCache()
       
            startUploadingToGCS()
        }
    }
    
    func authenticationFailureHandler(error: NSError?, code: String)
    {
        print("message = \(code) andError = \(error?.localizedDescription) ")
        
        if !self.requestManager.validConnection() {
            ErrorManager.sharedInstance.noNetworkConnection()
        }
        else if code.isEmpty == false {
            if((code == "USER004") || (code == "USER005") || (code == "USER006")){
               
            }
            else{
                ErrorManager.sharedInstance.mapErorMessageToErrorCode(code)
            }
        }
        else{
            ErrorManager.sharedInstance.inValidResponseError()
        }
    }
    
    //save image to local cache
    func saveImageToLocalCache(){

            let filePathToSaveThumb = "\(mediaId)thumb"
            FileManagerViewController.sharedInstance.saveImageToFilePath(filePathToSaveThumb, mediaImage: imageAfterConversionThumbnail)
            let filePathToSaveFull = "\(mediaId)full"
            FileManagerViewController.sharedInstance.saveImageToFilePath(filePathToSaveFull, mediaImage: imageFromDB)
            if (media == "video"){
                saveVideoToCahce()
            }
        
            updateDataToLocalDataSource()
    }
    
    func  saveVideoToCahce()  {
        if ((videoSavedURL.path?.isEmpty) != nil)
        {
            if let imageDatadup = NSData(contentsOfURL: videoSavedURL){
                videoData = imageDatadup
                let parentPath = FileManagerViewController.sharedInstance.getParentDirectoryPath().absoluteString
                let savingPath = "\(parentPath)/\(mediaId)video.mov"
                let url = NSURL(fileURLWithPath: savingPath)
                videoData.writeToURL(url, atomically: true)
            }
        }
    }
    
    func updateDataToLocalDataSource() {
        dataRowFromLocal.removeAll()
        
        let currentTimeStamp : String = getCurrentTimeStamp()
        
        dataRowFromLocal = [thumbSignedUrlKey:uploadThumbImageURLGCS,fullSignedUrlKey:uploadFullImageOrVideoURLGCS,mediaIdKey:Int(mediaId)!,mediaTypeKey:media,timeStampKey:currentTimeStamp,thumbImageKey:imageAfterConversionThumbnail,fullImageKey:imageFromDB,progressKey:0.0]
   
        mediaBeforeUploadCompleteManager.updateDataSource(dataRowFromLocal)
    }
    
    func getCurrentTimeStamp() -> String {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        dateFormatter.timeZone = NSTimeZone(name: "UTC")
        let localDateStr = dateFormatter.stringFromDate(NSDate())
        return localDateStr
    }
    
    //start Image upload after getting signed url
    func startUploadingToGCS()  {
        let qualityOfServiceClass = QOS_CLASS_BACKGROUND
        let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
        dispatch_async(backgroundQueue, {
            self.uploadFullImageOrVideoToGCS({(result) -> Void in
                if(result == "Success"){
            
                    self.uploadThumbImageToGCS({(result) -> Void in
                        if(result == "Success"){
                            self.mediaBeforeUploadCompleteManager.deleteRowFromDataSource(self.mediaId)
                            self.deleteDataFromDB()
                            self.mapMediaToDefaultChannels()
                        }
                        else{
                        }
                    })
                
                }
                else{
                }
            })
        })
    }
    
    //full image upload to cloud
    func uploadFullImageOrVideoToGCS(completion: (result: String) -> Void)
    {
        let url = NSURL(string: uploadFullImageOrVideoURLGCS)
        let request = NSMutableURLRequest(URL: url!)
        request.HTTPMethod = "PUT"
        let session = NSURLSession(configuration:NSURLSessionConfiguration.defaultSessionConfiguration(), delegate: self, delegateQueue: NSOperationQueue.mainQueue())
        var imageOrVideoData: NSData = NSData()
        if(media == "image"){
            imageOrVideoData = UIImageJPEGRepresentation(imageFromDB, 0.5)!
        }
        else{
            imageOrVideoData = NSData(contentsOfURL: videoSavedURL)!
        }
        request.HTTPBody = imageOrVideoData
        let dataTask = session.dataTaskWithRequest(request) { (data, response, error) -> Void in
            if error != nil {
                completion(result:"Failed")
            }
            else {
                completion(result:"Success")
            }
        }
        dataTask.resume()
    }
    
    //thumb image upload to cloud
    func uploadThumbImageToGCS(completion: (result: String) -> Void)
    {
        let url = NSURL(string: uploadThumbImageURLGCS)
        let request = NSMutableURLRequest(URL: url!)
        request.HTTPMethod = "PUT"
        let session = NSURLSession(configuration:NSURLSessionConfiguration.defaultSessionConfiguration(), delegate: self, delegateQueue: NSOperationQueue.mainQueue())
        var imageData: NSData = NSData()
        imageData = UIImageJPEGRepresentation(imageAfterConversionThumbnail, 0.5)!
        request.HTTPBody = imageData
        let dataTask = session.dataTaskWithRequest(request) { (data, response, error) -> Void in
            if error != nil {
                completion(result:"Failed")
            }
            else {
                completion(result:"Success")
            }
        }
        dataTask.resume()
        
    }
    
    //after upload complete delete data from local file and db
    func deleteDataFromDB(){
        let fileManager : NSFileManager = NSFileManager()
        if(fileManager.fileExistsAtPath(path)){
            do {
                try fileManager.removeItemAtPath(path)
            } catch let error as NSError {
                print(error.debugDescription)
            }
        }
        
        let videoUrlString = videoSavedURL.absoluteString
        if(fileManager.fileExistsAtPath(videoUrlString)){
            do {
                try fileManager.removeItemAtPath(videoUrlString)
            } catch let error as NSError {
                print(error.debugDescription)
            }
        }
        
        let appDel : AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let context : NSManagedObjectContext = appDel.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: "SnapShots")
        fetchRequest.returnsObjectsAsFaults=false
        do
        {
            let results = try context.executeFetchRequest(fetchRequest)
            for managedObject in results
            {
                let managedObjectData:NSManagedObject = managedObject as! NSManagedObject
                context.deleteObject(managedObjectData)
            }
        }
        catch let error as NSError {
            print(error.debugDescription)
        }
    }
    
    //after uploading map media to channels
    func mapMediaToDefaultChannels(){
        imageUploadManager.setDefaultMediaChannelMapping(userId, accessToken: accessToken, objectName: mediaId , success: { (response) -> () in
            
            }, failure: { (error, message) -> () in
                self.authenticationFailureHandler(error, code: message)
        })
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?)
    {
        let myAlert = UIAlertView(title: "Alert", message: error?.localizedDescription, delegate: nil, cancelButtonTitle: "Ok")
        myAlert.show()
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64)
    {
        let uploadProgress:Float = Float(totalBytesSent) / Float(totalBytesExpectedToSend)
        updateProgressToDefault(uploadProgress,mediaIds: mediaId)
    }
    
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveResponse response: NSURLResponse, completionHandler: (NSURLSessionResponseDisposition) -> Void)
    {
    }
    
    func updateProgressToDefault(progress:Float, mediaIds: String)
    {
        let dict = [mediaIdKey: mediaIds, "progress": progress]
        NSNotificationCenter.defaultCenter().postNotificationName("upload", object:dict)
    }
}
