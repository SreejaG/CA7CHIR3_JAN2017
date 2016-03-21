//
//  PhotoViewerViewController.swift
//  iONLive
//
//  Created by Gadgeon on 12/3/15.
//  Copyright © 2015 Gadgeon. All rights reserved.
//

import UIKit

protocol progressviewDelegate 
{
    func ProgresviewUpdate (value : Float)
}
let dataSourceURL = NSURL(string:"http://www.raywenderlich.com/downloads/ClassicPhotosDictionary.plist")

class PhotoViewerViewController: UIViewController,UIGestureRecognizerDelegate,NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate  {
     let channelManager = ChannelManager.sharedInstance
    var photos = [PhotoRecord]()
    let pendingOperations = PendingOperations()
    var channelDict = Dictionary<String, AnyObject>()
    var thumbImage : UIImage = UIImage()
    var fullImage  : UIImage = UIImage()
    var delegate:progressviewDelegate?
    let signedURLResponse: NSMutableDictionary = NSMutableDictionary()
    var channelDetails: NSMutableArray = NSMutableArray()

    @IBOutlet var progressView: UIProgressView!
    let thumbImageKey = "thumbImage"
    let fullImageKey = "fullImageKey"
     static let identifier = "PhotoViewerViewController"
    let imageUploadManger = ImageUpload.sharedInstance
    let requestManager = RequestManager.sharedInstance
    @IBOutlet weak var photoThumpCollectionView: UICollectionView!
    @IBOutlet weak var fullScrenImageView: UIImageView!
    var dataSource:[[String:UIImage]] = [[String:UIImage]]()
    var cloudImage: [[String:UIImage]] = [[String:UIImage]]()
    let photo : PhotoThumbCollectionViewCell = PhotoThumbCollectionViewCell()
    @IBOutlet var fullScreenZoomView: UIImageView!
    var snapShots : NSMutableDictionary = NSMutableDictionary()
    var cells: NSArray = NSArray()
    var progrs: Float = 0.0
    var queue = NSOperationQueue()
    override func viewDidLoad() {
        super.viewDidLoad()
        initialise()
        getSignedURL()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    func getSignedURL()
    {
        self.queue = NSOperationQueue()
        queue.addOperationWithBlock { () -> Void in
            
            let defaults = NSUserDefaults .standardUserDefaults()
            let userId = defaults.valueForKey(userLoginIdKey) as! String
            let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
            //call api to fetch cloud datas
            self.imageUploadManger.getSignedURL(userId, accessToken: accessToken, success: { (response) -> () in
                self.authenticationSuccessHandlerSignedURL(response)
                }, failure: { (error, message) -> () in
                    self.authenticationFailureHandlerSignedURL(error, code: message)
                    
            })
            NSOperationQueue.mainQueue().addOperationWithBlock({
                //   self.readImageFromDataBase()
                
            })
        }

    }
    func  fetchCollectionViewDataSource()
    {
      
        
        if dataSource.count < 0{
         
                }
        else
        {
//          
//            if dataSourceCount < 8
//            {
//                
//                
//            }
            
        }
        
        
        
        
    }
    func authenticationSuccessHandlerSignedURL(response:AnyObject?)
    {
    //  fetchCollectionViewDataSource()
        self.readImageFromDataBase()
        photoThumpCollectionView.reloadData()
       
                if let json = response as? [String: AnyObject]
                {
                   // print(json)
                    if let name = json["UploadObjectUrl"]{
                        signedURLResponse.setValue(name, forKey: "UploadObjectUrl")
                    }
                    if let name = json["ObjectName"]{
                        signedURLResponse.setValue(name, forKey: "ObjectName")
                    }
                    if let name = json["UploadThumbnailUrl"]{
                        signedURLResponse.setValue(name, forKey: "UploadThumbnailUrl")
                    }
                    
                  
            
        

               }
                else
                {
                    ErrorManager.sharedInstance.inValidResponseError()
                }
        
        let defaults = NSUserDefaults .standardUserDefaults()
        let userId = defaults.valueForKey(userLoginIdKey) as! String
        let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
        getChannelDetails(userId, token: accessToken)
        
        
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
    
    func authenticationSuccessHandlerForDefaultMediaMapping(response:AnyObject?)
    {
        if let json = response as? [String: AnyObject]
        {
        }
        
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
    func initialise()
    {
        
//        let kKeychainItemName: String = "ion-live-1120"
//        let kMyClientID: String = "821885679497-88oi8625g6g9kmpojmi5edv8t6qibu59.apps.googleusercontent.com"
//        let kMyClientSecret: String = "YjoqEGOdqEKuQHVuDxH0bYgW"
//        let kScope: String = "signedurl@ion-live-1120.iam.gserviceaccount.com"
        
        fullScreenZoomView.userInteractionEnabled = true
        fullScreenZoomView.hidden = true
        fullScrenImageView.userInteractionEnabled = true
        
        let enlargeImageViewRecognizer = UITapGestureRecognizer(target: self, action: "enlargeImageView:")
        enlargeImageViewRecognizer.numberOfTapsRequired = 1
        fullScrenImageView.addGestureRecognizer(enlargeImageViewRecognizer)
        
        let shrinkImageViewRecognizer = UITapGestureRecognizer(target: self, action: "shrinkImageView:")
        shrinkImageViewRecognizer.numberOfTapsRequired = 1
        fullScreenZoomView.addGestureRecognizer(shrinkImageViewRecognizer)
    
//        let lpgr = UILongPressGestureRecognizer(target: self, action: "handleLongPress:")
//        lpgr.minimumPressDuration = 0.5
//        lpgr.delaysTouchesBegan = true
//        lpgr.delegate = self
//        self.photoThumpCollectionView.addGestureRecognizer(lpgr)
        
    }

    func enlargeImageView(Recognizer:UITapGestureRecognizer){
        fullScreenZoomView.hidden = false
    }
    
    func shrinkImageView(Recognizer:UITapGestureRecognizer){
        fullScreenZoomView.hidden = true
    }
    func fetchPhotoDetails() {
        let request = NSURLRequest(URL:dataSourceURL!)
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue()) {response,data,error in
            if data != nil {
              
                
             //   self.photoThumpCollectionView.reloadData()
            }
            
            if error != nil {
                let alert = UIAlertView(title:"Oops!",message:error!.localizedDescription, delegate:nil, cancelButtonTitle:"OK")
                alert.show()
            }
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        }
    }
//    func handleLongPress(gestureReconizer: UILongPressGestureRecognizer) {
//        if gestureReconizer.state != UIGestureRecognizerState.Ended {
//            return
//        }
//        
//        let p = gestureReconizer.locationInView(self.photoThumpCollectionView)
//        let indexPath = self.photoThumpCollectionView.indexPathForItemAtPoint(p)
//        
//        if let index = indexPath {
//            let cell = self.photoThumpCollectionView.cellForItemAtIndexPath(index)
//            cell?.layer.borderWidth = 1.0
//            cell?.layer.borderColor = UIColor.blueColor().CGColor
//            
//            let singleTapImageViewRecognizer = UITapGestureRecognizer(target: self, action: "singleTap:")
//            singleTapImageViewRecognizer.numberOfTapsRequired = 1
//            cell!.addGestureRecognizer(singleTapImageViewRecognizer)
//            
//            print(index.row)
//        } else {
//            print("Could not find index path")
//        }
//    }
//
//    func singleTap(Recognizer:UITapGestureRecognizer){
//        let p = Recognizer.locationInView(self.photoThumpCollectionView)
//        let indexPath = self.photoThumpCollectionView.indexPathForItemAtPoint(p)
//        
//        if let index = indexPath {
//            let cell = self.photoThumpCollectionView.cellForItemAtIndexPath(index)
//            cell?.layer.borderColor = UIColor.clearColor().CGColor
//            cell?.removeGestureRecognizer(Recognizer)
//        }
//    }
    
    @IBAction func didTapAddChannelButton(sender: AnyObject) {
        let storyboard = UIStoryboard(name:"MyChannel" , bundle: nil)
        let addChannelVC = storyboard.instantiateViewControllerWithIdentifier(AddChannelViewController.identifier) as! AddChannelViewController
        let backItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        addChannelVC.navigationItem.backBarButtonItem = backItem
        self.navigationController?.pushViewController(addChannelVC, animated: false)
    }
    func readImageFromDataBase()
    {
        let cameraController = IPhoneCameraViewController()
        
        if snapShots.count > 0
        {
            let snapShotsKeys = snapShots.allKeys as NSArray
            
            let descriptor: NSSortDescriptor = NSSortDescriptor(key: nil, ascending: false)
            let sortedSnapShotsKeys: NSArray = snapShotsKeys.sortedArrayUsingDescriptors([descriptor])
            
            var dummyImagesDataSource :[[String:UIImage]]  = [[String:UIImage]]()
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
                        let sizeThumb = CGSizeMake(50,50)
                        let sizeFull = CGSizeMake(screenWidth*4,screenHeight*3)
                        let imageAfterConversionThumbnail = cameraController.thumbnaleImage(imageToConvert, scaledToFillSize: sizeThumb)
                        let imageAfterConversionFullscreen = cameraController.thumbnaleImage(imageToConvert, scaledToFillSize: sizeFull)
                        dummyImagesDataSource.append([thumbImageKey:imageAfterConversionThumbnail,fullImageKey:imageAfterConversionFullscreen!])
                    }
                }
            }
            
            dataSource = dummyImagesDataSource
            print(dataSource)
            if dummyImagesDataSource.count > 0
            {
                if let imagePath = dummyImagesDataSource[0][fullImageKey]
                {
                
                    self.fullScrenImageView.image = imagePath
                    self.fullScreenZoomView.image = imagePath
                }
            }
        }
    }
    //PRAGMA MARK:- IBActions

    @IBAction func channelButtonClicked(sender: AnyObject)
    {
        let myChannelStoryboard = UIStoryboard(name:"MyChannel" , bundle: nil)
        let myChannelVC = myChannelStoryboard.instantiateViewControllerWithIdentifier(MyChannelViewController.identifier)
        myChannelVC.navigationController?.navigationBarHidden = true
        self.navigationController?.pushViewController(myChannelVC, animated: true)
    }
    @IBAction func donebuttonClicked(sender: AnyObject)
    {
        self.dismissViewControllerAnimated(true) { () -> Void in
            
        }
    }
    
}

extension PhotoViewerViewController:UICollectionViewDelegate,UICollectionViewDelegateFlowLayout
{
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        print(dataSource.count)
        return dataSource.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoThumbCollectionViewCell", forIndexPath: indexPath) as! PhotoThumbCollectionViewCell
        
        //cell for live streams
        
        if dataSource.count > indexPath.row
        {
            var dict = dataSource[indexPath.row]
            if let thumpImage = dict[thumbImageKey]
            {
                cell.thumbImageView.image = thumpImage
                if progrs != 0.0
                {
                      cell.progressView.progress = progrs
                }
                else
                {
                    uploadData( cell,rowIndex: indexPath.row)
                    cell.progressView.progress = progrs

                }
                [NSNotificationCenter.defaultCenter().addObserver(self, selector:"ProgresviewUpdate:", name:"MyNotification" , object:nil)]
              

            }
        }
       
        return cell
    }
    func uploadData (celldata : UICollectionViewCell ,rowIndex : Int)
    {
        var dict = dataSource[rowIndex]
        let  uploadImage = dict[fullImageKey]
        let imageData = UIImageJPEGRepresentation(uploadImage!, 0.5)

       // let imageData = UIImagePNGRepresentation(uploadImage!)
        let defaults = NSUserDefaults .standardUserDefaults()
        let userId = defaults.valueForKey(userLoginIdKey) as! String
        let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
        if(imageData == nil )  { return }
        test(imageData!)

        
    }
    func test( imagedata : NSData)
{
    
    let url = NSURL(string: signedURLResponse.valueForKey("UploadObjectUrl") as! String) //Remember to put ATS exception if the URL is not https
    let request = NSMutableURLRequest(URL: url!)
    request.HTTPMethod = "PUT"
    let session = NSURLSession(configuration:NSURLSessionConfiguration.defaultSessionConfiguration(), delegate: self, delegateQueue: NSOperationQueue.mainQueue())
    request.HTTPBody = imagedata
    let dataTask = session.dataTaskWithRequest(request) { (data, response, error) -> Void in
        if error != nil {
            //handle error
        }
        else {
            let jsonStr = NSString(data: data!, encoding: NSUTF8StringEncoding)
            print("Parsed JSON: '\(jsonStr)'")
        } 
    }
    dataTask.resume()
    }
    func authenticationSuccessHandler(response:AnyObject?)
    {
        
//        if let json = response as? [String: AnyObject]
//        {
//            print(json)
//        }
//        else
//        {
//            ErrorManager.sharedInstance.inValidResponseError()
//        }
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

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath)
    {
        if dataSource.count > indexPath.row
        {
            var dict = dataSource[indexPath.row]
            
            if let fullImage = dict[fullImageKey]
            {
                self.fullScrenImageView.image = fullImage
                self.fullScreenZoomView.image = fullImage
            }
        }
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(1, 1, 1, 1)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 1
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?)
    {
        let myAlert = UIAlertView(title: "Alert", message: error?.localizedDescription, delegate: nil, cancelButtonTitle: "Ok")
        myAlert.show()
        
     //   self.uploadButton.enabled = true
        
    }
    
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64)
    {
        let uploadProgress:Float = Float(totalBytesSent) / Float(totalBytesExpectedToSend)
        progrs=uploadProgress
        [photoThumpCollectionView .reloadData()]
        print(uploadProgress)
      if uploadProgress == 1.0
      {
        let defaults = NSUserDefaults .standardUserDefaults()
        let userId = defaults.valueForKey(userLoginIdKey) as! String
        let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
        imageUploadManger.setDefaultMediaChannelMapping(userId, accessToken: accessToken, objectName: signedURLResponse.valueForKey("ObjectName") as! String, success: { (response) -> () in
            self.authenticationSuccessHandlerForDefaultMediaMapping(response)
            }, failure: { (error, message) -> () in
                self.authenticationFailureHandlerForDefaultMediaMapping(error, code: message)
                
        })
        
        }
        
    }
    
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveResponse response: NSURLResponse, completionHandler: (NSURLSessionResponseDisposition) -> Void)
    {
      //  self.uploadButton.enabled = true
    }
    override func viewWillDisappear(animated: Bool) {
        
        super.viewWillDisappear(true)
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
        
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
       
        for var index = 0; index < channelDetails.count; index++
        {
            let channelName = channelDetails[index].valueForKey("channel_name") as! String
            let channelId = channelDetails[index].valueForKey("channel_detail_id")
            channelDict[channelName] = channelId
            
           
        }
        
        getMediaFromCloud()
    }
    func getMediaFromCloud()
    {
        let defaults = NSUserDefaults .standardUserDefaults()
        let userId = defaults.valueForKey(userLoginIdKey) as! String
        let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
        //let channelId = channelDict["My Day"] as! NSNumber
        let channelId:String = String(format:"%d",channelDict["My Day"] as! NSNumber)
        print(channelId)
        imageUploadManger.getChannelMediaDetails(channelId , userName: userId, accessToken: accessToken, limit: "8", offset: "0" , success: { (response) -> () in
            self.authenticationSuccessHandlerForFetchMedia(response)

            }) { (error, message) -> () in
                self.authenticationFailureHandler(error, code: message)

        }
    }
    
    func authenticationSuccessHandlerForFetchMedia(response:AnyObject?)
    {
        let mediaDict: NSMutableDictionary = NSMutableDictionary()

        if let json = response as? [String: AnyObject]
        {
            let responseArr = json["objectJson"] as! [AnyObject]
            
            for element in responseArr{
                mediaDict.setDictionary(element as! [NSObject : AnyObject])
            }

            //print(json)
        }
        downloadCloudData(mediaDict)
        
    }
    
    
    func getDataFromUrl(url:NSURL, completion: ((data: NSData?, response: NSURLResponse?, error: NSError? ) -> Void)) {
        
        NSURLSession.sharedSession().dataTaskWithURL(url) { (data, response, error) in
            completion(data: data, response: response, error: error)
            }.resume()
    }
    func stringToURL( stringURl :String) -> NSURL
    {
        let url : NSString = stringURl
        let urlStr : NSString = url.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
        let searchURL : NSURL = NSURL(string: urlStr as String)!
        return searchURL
    }
    func downloadCloudData(mediaDict : NSMutableDictionary)
        
    {
        var dummyImagesDataSource :[[String:UIImage]]  = [[String:UIImage]]()
        queue = NSOperationQueue()
        for var i = 1 ; i <=  mediaDict.count ; ++i {
        let operation1 = NSBlockOperation( block: {
            
                let mediaURL = self.stringToURL(mediaDict["gcs_object_name_SignedUrl"] as! String)
                let thumbnailURL = self.stringToURL(mediaDict["thumbnail_name_SignedUrl"] as! String)
                // print(mediaURL)
                let request = NSURLRequest(URL: mediaURL)
                let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
                dispatch_async(queue) { () -> Void in
                    NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue()) {
                        (response: NSURLResponse?, data: NSData?, error: NSError?) -> Void in
                        print(data)
                        if let imageData = data as NSData? {
                            print(imageData)
                            self.thumbImage = UIImage(data: imageData)!
                        }
                    }
                
                    dispatch_async(dispatch_get_main_queue(), {
//                        self.dataSource=dummyImagesDataSource
//                        self.photoThumpCollectionView.reloadData()
                    })
                    
                }
                dispatch_async(queue) { () -> Void in
                    
                    let request1 = NSURLRequest(URL: thumbnailURL)
                    NSURLConnection.sendAsynchronousRequest(request1, queue: NSOperationQueue.mainQueue()) {
                        (response: NSURLResponse?, data: NSData?, error: NSError?) -> Void in
                        if let imageData = data as NSData? {
                            self.fullImage = UIImage(data: imageData)!
                            
                        }}
                        
                        
                        dispatch_async(dispatch_get_main_queue(), {
//                            self.dataSource=dummyImagesDataSource
//                            self.photoThumpCollectionView.reloadData()
                        })
                    }
                    
                
           
            
            
        })
            
        operation1.completionBlock = {
            dummyImagesDataSource.append([self.thumbImageKey:self.thumbImage,self.fullImageKey:self.fullImage])
            
            self.dataSource=dummyImagesDataSource
            print(dummyImagesDataSource)
            self.photoThumpCollectionView.reloadData()
        }
        }
    
        }
    }




