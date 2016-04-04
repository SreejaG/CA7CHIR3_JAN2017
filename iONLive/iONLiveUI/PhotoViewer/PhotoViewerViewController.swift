
//
//  PhotoViewerViewController.swift
//  iONLive
//
//  Created by Gadgeon on 12/3/15.
//  Copyright © 2015 Gadgeon. All rights reserved.
//

import UIKit
import MediaPlayer
import Foundation


protocol progressviewDelegate
{
    func ProgresviewUpdate (value : Float)
}

class PhotoViewerViewController: UIViewController,UIGestureRecognizerDelegate,NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate,uploadProgressDelegate,NSURLSessionDownloadDelegate  {
    let channelManager = ChannelManager.sharedInstance
    var channelDict = Dictionary<String, AnyObject>()
    var thumbImage : UIImage = UIImage()
    var fullImage  : UIImage = UIImage()
    var delegate:progressviewDelegate?
    let signedURLResponse: NSMutableDictionary = NSMutableDictionary()
    var channelDetails: NSMutableArray = NSMutableArray()
    var thumbLinkArray: NSMutableArray = NSMutableArray()
    var mediaTypeArray: NSMutableArray = NSMutableArray()
    var selectedCollectionViewIndex : Int = 0
    var mediaIdArray: NSMutableArray = NSMutableArray()
    var medianameArray: NSArray = NSArray()
    var moviePlayer : MPMoviePlayerController!
    
    var fullImageLinkArray: NSMutableArray = NSMutableArray()
    var dummyImagesDataSourceDatabase :[[String:UIImage]]  = [[String:UIImage]]()
    var checksDataSourceDatabase :[[String:UIImage]]  = [[String:UIImage]]()
    var progressViewDownload: UIProgressView?
    var progressLabelDownload: UILabel?
    var loadingOverlay: UIView?
    var progressDict : NSMutableArray = NSMutableArray()
    
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
    var mediaDictionary: NSMutableDictionary = NSMutableDictionary()
    
    let photo : PhotoThumbCollectionViewCell = PhotoThumbCollectionViewCell()
    @IBOutlet var fullScreenZoomView: UIImageView!
    var snapShots : NSMutableDictionary = NSMutableDictionary()
    var cells: NSArray = NSArray()
    var progrs: Float = 0.0
    var queue = NSOperationQueue()
    var uploadCount : Int = 0
    
    
    
    private var downloadTask: NSURLSessionDownloadTask?
    class var sharedInstance: PhotoViewerViewController {
        struct Singleton {
            static let instance = PhotoViewerViewController()
        }
        return Singleton.instance
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        initialise()
        getSignedURL()
        PhotoViewerInstance.controller = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillDisappear(animated: Bool) {
        
        super.viewWillDisappear(true)
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
        
    }
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        //        if (segue.identifier == "Load View") {
        //            // pass data to next view
        //        }
        //        let uploadVC = segue.destinationViewController as! upload
        //        uploadVC.delegate = self;
    }
    func  uploadProgress ( progressDictionary : NSMutableArray)
    {
        
        progressDict = progressDictionary
        
        
        self.photoThumpCollectionView.reloadData();
        // }
        print(progressDictionary)
        
    }
    func getSignedURL()
    {
        showOverlay()
        let defaults = NSUserDefaults .standardUserDefaults()
        let userId = defaults.valueForKey(userLoginIdKey) as! String
        let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
        getChannelDetails(userId, token: accessToken)
    }
    //Loading Overlay Methods
    func showOverlay(){
        let loadingOverlayController:IONLLoadingView=IONLLoadingView(nibName:"IONLLoadingOverlay", bundle: nil)
        loadingOverlayController.view.frame = self.view.bounds
        loadingOverlayController.startLoading()
        self.loadingOverlay = loadingOverlayController.view
        self.navigationController?.view.addSubview(self.loadingOverlay!)
    }
    func removeOverlay(){
        self.loadingOverlay?.removeFromSuperview()
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
        
        let mediaType = mediaTypeArray[selectedCollectionViewIndex] as! String
        
        
        if mediaType == "video"
        {
            
            downloadVideo(selectedCollectionViewIndex)
            
        }
        else
        {
            fullScreenZoomView.hidden = false
        }
    }
    func downloadVideo(index : Int)
    {
        let videoDownloadUrl = convertStringtoURL(self.fullImageLinkArray[index] as! String)
        
        //   self.showOverlay()
        
        
        // Create Progress View Control
        
        
        // Add Label
        
        let downloadRequest = NSMutableURLRequest(URL: videoDownloadUrl)
        let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration(), delegate: self, delegateQueue: NSOperationQueue.mainQueue())
        
        downloadTask = session.downloadTaskWithRequest(downloadRequest)
        progressViewDownload = UIProgressView(progressViewStyle: UIProgressViewStyle.Default)
        progressViewDownload?.center = fullScrenImageView.center
        
        view.addSubview(progressViewDownload!)
        
        // Add Label
        progressLabelDownload = UILabel()
        let frame = CGRectMake(fullScrenImageView.center.x - 25, fullScrenImageView.center.y - 100, 100, 50)
        progressLabelDownload?.frame = frame
        view.addSubview(progressLabelDownload!)
        fullScrenImageView.alpha = 0.2
        
        downloadTask!.resume()
        
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        // let p = progressViewLayer()
        
        //   p.animateProgressViewToProgress(progress)
        //   p.updateProgressViewLabelWithProgress(progress * 100)
        //  p.updateProgressViewWith(Float(totalBytesWritten), totalFileSize: Float(totalBytesExpectedToWrite))
        //  self.view.addSubview(p)
        progressViewDownload!.progress = progress
        //  let progressValue = self.progressView?.progress
        //  let s = NSString(format: "%.2f",progress*100)
        let y = Int(round(progress*100))
        
        progressLabelDownload?.text = "\(y) %"
        print(progress)
        print(progress * 100)
        if progress == 1.0
        {
            fullScrenImageView.alpha = 1.0
            
            progressLabelDownload?.removeFromSuperview()
            progressViewDownload?.removeFromSuperview()
        }
        // progressView.updateProgressViewWith(Float(totalBytesWritten), totalFileSize: Float(totalByte
        
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        
        print(location)
        
        let data = NSData(contentsOfURL: location)
        if let imageData = data as NSData? {
            
            //    self.removeOverlay()
            let documents = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
            let writePath = documents.stringByAppendingString("/")
            let pa = writePath.stringByAppendingString("video.mov")
            let url = NSURL(fileURLWithPath: pa)
            print(url)
            let fm = NSFileManager.defaultManager()
            do {
                let items = try fm.contentsOfDirectoryAtPath(documents)
                
                for item in items {
                    print("Found \(item)")
                }
            } catch {
                // failed to read directory – bad permissions, perhaps?
            }
            if(imageData.writeToURL(url, atomically:true))
            {
                //   let path = NSBundle.mainBundle().pathForResource("Video", ofType:"mp4")
                //     let url = NSURL.fileURLWithPath(url)
                
                NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("playerDidFinish:"), name: MPMoviePlayerPlaybackDidFinishNotification, object: self.moviePlayer)
                
                
                self.moviePlayer = MPMoviePlayerController(contentURL: url)
                if let player = self.moviePlayer {
                    player.view.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height)
                    player.view.sizeToFit()
                    player.scalingMode = MPMovieScalingMode.Fill
                    player.fullscreen = true
                    player.controlStyle = MPMovieControlStyle.None
                    player.movieSourceType = MPMovieSourceType.File
                    player.repeatMode = MPMovieRepeatMode.None
                    self.view.addSubview(player.view)
                    
                    player.prepareToPlay()
                }
                
            }
        }
    }
    func playerDidFinish(notif:NSNotification)
    {
        self.moviePlayer.view.removeFromSuperview()
        
    }
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        
    }
    func shrinkImageView(Recognizer:UITapGestureRecognizer){
        fullScreenZoomView.hidden = true
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
                        medianameArray.arrayByAddingObject(thumbNailImagePath)
                        
                        let imageToConvert = UIImage(data: NSData(contentsOfFile: thumbNailImagePath as! String)!)
                        let sizeThumb = CGSizeMake(70,70)
                        let sizeFull = CGSizeMake(screenWidth*4,screenHeight*3)
                        let imageAfterConversionThumbnail = cameraController.thumbnaleImage(imageToConvert, scaledToFillSize: sizeThumb)
                        let imageAfterConversionFullscreen = cameraController.thumbnaleImage(imageToConvert, scaledToFillSize: sizeFull)
                        dummyImagesDataSourceDatabase.append([thumbImageKey:imageAfterConversionThumbnail,fullImageKey:imageAfterConversionFullscreen!])
                    }
                }
            }
            
            dataSource = dummyImagesDataSourceDatabase
            checksDataSourceDatabase = dummyImagesDataSourceDatabase
            uploadCount = dummyImagesDataSourceDatabase.count
            print(uploadCount)
            if dummyImagesDataSourceDatabase.count > 0
            {
                if let imagePath = dummyImagesDataSourceDatabase[0][fullImageKey]
                {
                    print(imagePath)
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

//PRAGMA MARK:- Collection View Delegates

extension PhotoViewerViewController:UICollectionViewDelegate,UICollectionViewDelegateFlowLayout
{
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
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
                if(progressDict.count>0)
                {
                    for var i = 0; i < progressDict.count ;i++
                    {
                        if(indexPath.row == i)
                            
                        {
                            fullScrenImageView.userInteractionEnabled = false
                            cell.progressView.hidden = false
                            
                            cell.progressView.progress = progressDict[i].floatValue
                            if(progressDict[i].floatValue == 1.0)
                            {
                                cell.progressView.hidden = true
                                fullScrenImageView.userInteractionEnabled = true
                                
                                
                            }
                            
                        }
                        else
                        {
                            cell.progressView.hidden = true
                        }
                    }
                }
                else
                {
                    cell.progressView.hidden = true
                    
                }
                
                [NSNotificationCenter.defaultCenter().addObserver(self, selector:"ProgresviewUpdate:", name:"MyNotification" , object:nil)]
            }
        }
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath)
    {
        if dataSource.count > indexPath.row
        {
            var dict = dataSource[indexPath.row]
            selectedCollectionViewIndex = indexPath.row
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
    //PRAGMA MARK:- Upload
    
    func uploadData (index : Int ,completion: (result: String) -> Void)
    {
        
        if(checksDataSourceDatabase.count>0)
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
                
                self.imageUploadManger.getSignedURL(userId, accessToken: accessToken, mediaType : "image", success: { (response) -> () in
                    //    self.authenticationSuccessHandlerSignedURL(response,rowIndex: rowIndex)
                    self.authenticationSuccessHandlerSignedURL(response, rowIndex: index, completion: { (result) -> Void in
                        completion(result : "Success")
                    })
                    }, failure: { (error, message) -> () in
                        completion(result: "Failed")
                        self.authenticationFailureHandlerSignedURL(error, code: message)
                        //   return
                        
                })
                
            }}
    }
    func uploadFullImage( imagedata : NSData ,row : Int ,completion: (result: String) -> Void)
    {
        
        let url = NSURL(string: signedURLResponse.valueForKey("UploadObjectUrl") as! String) //Remember to put ATS exception if the URL is not https
        let request = NSMutableURLRequest(URL: url!)
        request.HTTPMethod = "PUT"
        let session = NSURLSession(configuration:NSURLSessionConfiguration.defaultSessionConfiguration(), delegate: self, delegateQueue: NSOperationQueue.mainQueue())
        request.HTTPBody = imagedata
        let dataTask = session.dataTaskWithRequest(request) { (data, response, error) -> Void in
            if error != nil {
                //handle error
                //  completion(result:"Failed")
                
            }
            else {
                let jsonStr = NSString(data: data!, encoding: NSUTF8StringEncoding)
                print("Parsed JSON photoviewer: '\(jsonStr)'")
                //  completion(result:"Success")
                
                
                
            }
            //  completion(result:"Success")
            
        }
        completion(result:"Success")
        
        dataTask.resume()
    }
    
    
    func uploadThumbImage(row : Int,completion: (result: String) -> Void)
    {
        var dict = dataSource[row]
        let  uploadImageThumb = dict[thumbImageKey]
        
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
                print("Parsed JSON for thumbanil photoviwewr: '\(jsonStr)'")
                //    completion(result:"Success")
                
                
            }
            // completion(result:"Success")
            
        }
        completion(result:"Success")
        
        dataTask.resume()
        
        
        
    }
    
    
    //PRAGMA MARK:- URL Session , delegates
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64)
    {
        let uploadProgress:Float = Float(totalBytesSent) / Float(totalBytesExpectedToSend)
        progrs=uploadProgress
        [photoThumpCollectionView .reloadData()]
        if uploadProgress == 1.0
        {
            
        }
        
    }
    
    
    
    
    //PRAGMA MARK:- Channel details
    
    func getChannelDetails(userName: String, token: String)
    {
        channelManager.getChannelDetails(userName, accessToken: token, success: { (response) -> () in
            self.authenticationSuccessHandlerList(response)
            }) { (error, message) -> () in
                self.authenticationFailureHandler(error, code: message)
                return
        }
    }
    
    //PRAGMA MARK:- Authentication Handler
    
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
    func authenticationSuccessHandler(response:AnyObject?)
    {
        
    }
    func authenticationFailureHandler(error: NSError?, code: String)
    {
        self.removeOverlay()
        photoThumpCollectionView.reloadData()
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
    
    
    func authenticationSuccessHandlerForFetchMedia(response:AnyObject?)
    {
        self.readImageFromDataBase()
        
        let mediaDict: NSMutableDictionary = NSMutableDictionary()
        thumbLinkArray.removeAllObjects()
        fullImageLinkArray.removeAllObjects()
        if let json = response as? [String: AnyObject]
        {
            let responseArr = json["objectJson"] as! [AnyObject]
            
            for element in responseArr{
                //  print(element)
                for (key,value) in element as! NSDictionary {
                    let thumbKey = key as! String
                    if thumbKey == "thumbnail_name_SignedUrl"
                    {
                        thumbLinkArray.addObject(value)
                    }
                    else if thumbKey == "gcs_object_name_SignedUrl"
                    {
                        fullImageLinkArray.addObject(value)
                        
                    }
                    else if thumbKey == "media_detail_id"
                    {
                        mediaIdArray.addObject(value)
                    }
                    else if thumbKey == "gcs_object_type"
                    {
                        mediaTypeArray.addObject(value)
                    }
                }
                
            }
            
        }
        downloadFirstEntry()
        
    }
    func authenticationFailureHandlerForFetchMedia(error: NSError?, code: String)
    {
        self.removeOverlay()
        photoThumpCollectionView.reloadData()
        print("message = \(code) andError = \(error?.localizedDescription) ")
        
        if !self.requestManager.validConnection() {
            ErrorManager.sharedInstance.noNetworkConnection()
        }
        else if code.isEmpty == false {
            ErrorManager.sharedInstance.mapErorMessageToErrorCode(code)
            
            self.readImageFromDataBase()
            
            if dummyImagesDataSourceDatabase.count > 0
            {
                for(var i = dummyImagesDataSourceDatabase.count-1 ; i >= 0 ; i--)
                {
                    
                    //                    uploadData( i,completion: { (result) -> Void in
                    //                        self.photoThumpCollectionView.reloadData()
                    //
                    //                    })
                    
                    
                }
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
                let imageData = UIImageJPEGRepresentation(uploadImageFull!, 0.5)
                self.uploadFullImage(imageData!, row: rowIndex , completion: { (result) -> Void in
                    
                    if result == "Success"
                    {
                        
                        self.uploadThumbImage(rowIndex, completion: { (result) -> Void in
                            
                            if result == "Success"
                            {
                                if self.checksDataSourceDatabase.count > 0
                                {
                                    self.checksDataSourceDatabase.removeFirst()
                                    
                                    
                                }
                                
                                if  self.checksDataSourceDatabase.count==0
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
    
    func authenticationFailureHandlerSignedURL(error: NSError?, code: String)
    {
        self.removeOverlay()
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
        
    }
    func authenticationFailureHandlerForDefaultMediaMapping(error: NSError?, code: String)
    {
        self.removeOverlay()
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
    
    //PRAGMA MARK:- Set Channel
    
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
        let channelId = channelDict["My Day"] as! NSNumber
        
        
        
        imageUploadManger.getChannelMediaDetails(channelId.stringValue , userName: userId, accessToken: accessToken, limit: "8", offset: "0" , success: { (response) -> () in
            self.authenticationSuccessHandlerForFetchMedia(response)
            
            }) { (error, message) -> () in
                self.authenticationFailureHandlerForFetchMedia(error, code: message)
                
        }
    }
    func downloadFirstEntry()
    {
        
        var dummyImagesDataSource :[[String:UIImage]]  = [[String:UIImage]]()
        
        if(self.fullImageLinkArray.count > 0 && self.thumbLinkArray.count > 0)
        {
            var downloadedFullImage : UIImage = UIImage()
            var downloadedThumbImage : UIImage = UIImage()
            
            let mediaDict: NSMutableDictionary = NSMutableDictionary()
            
            
            dummyImagesDataSource = self.dataSource
            self.dataSource .removeAll()
            let fullImageDownloadUrl = convertStringtoURL(self.fullImageLinkArray[0] as! String)
            //   downloadMedia(fullImageDownloadUrl, key: "FullImage")
            let downloadThumbURL =  self.convertStringtoURL(self.thumbLinkArray[0] as! String)
            
            
            let mediaType = self.mediaTypeArray[0] as! String
            if mediaType == "image"
            {
                downloadMedia(fullImageDownloadUrl, key:  "FullImage") { (result) -> Void in
                    
                    mediaDict.setValue(result, forKey: "FullImage")
                    
                    
                    self.downloadMedia(downloadThumbURL, key: "ThumbImage", completion: { (result) -> Void in
                        print("Execution Completed 2",result)
                        mediaDict.setValue(result, forKey: "ThumbImage")
                        if dummyImagesDataSource.count > 0
                        {
                            self.fullScrenImageView.image = dummyImagesDataSource[0][self.fullImageKey]
                            self.fullScreenZoomView.image = dummyImagesDataSource[0][self.fullImageKey]
                        }
                        else
                        {
                            self.fullScrenImageView.image = mediaDict["FullImage"] as? UIImage
                            self.fullScreenZoomView.image = mediaDict["FullImage"] as? UIImage
                        }
                        let image: UIImage? = mediaDict["ThumbImage"] as? UIImage
                        
                        if(image == nil)
                        {
                            dummyImagesDataSource.append([self.thumbImageKey:mediaDict["ThumbImage"] as! UIImage,self.fullImageKey:mediaDict["ThumbImage"] as! UIImage])
                        }
                        else
                        {
                            dummyImagesDataSource.append([self.thumbImageKey:mediaDict["ThumbImage"] as! UIImage,self.fullImageKey:mediaDict["FullImage"] as! UIImage])
                        }
                        self.dataSource = dummyImagesDataSource
                        self.photoThumpCollectionView.reloadData()
                        self.mediaDictionary.setValue(mediaDict, forKey: "0")
                        self.removeOverlay()
                        
                        
                    })
                }
                
            }
            else
            {
                
                //if media type video set thumbnail image as fullview
                self.downloadMedia(downloadThumbURL, key: "ThumbImage", completion: { (result) -> Void in
                    print("Execution Completed 2",result)
                    mediaDict.setValue(result, forKey: "ThumbImage")
                    if dummyImagesDataSource.count > 0
                    {
                        self.fullScrenImageView.image = dummyImagesDataSource[0][self.fullImageKey]
                        self.fullScreenZoomView.image = dummyImagesDataSource[0][self.fullImageKey]
                    }
                    else
                    {
                        self.fullScrenImageView.image = mediaDict["ThumbImage"] as? UIImage
                        self.fullScreenZoomView.image = mediaDict["ThumbImage"] as? UIImage
                    }
                    dummyImagesDataSource.append([self.thumbImageKey:mediaDict["ThumbImage"] as! UIImage,self.fullImageKey:mediaDict["ThumbImage"] as! UIImage])
                    
                    self.dataSource = dummyImagesDataSource
                    self.photoThumpCollectionView.reloadData()
                    self.mediaDictionary.setValue(mediaDict, forKey: "0")
                    self.removeOverlay()
                    
                    
                })
            }
            downloadCloudData(mediaDict)
            if dummyImagesDataSourceDatabase.count > 0
            {
                for(var i = dummyImagesDataSourceDatabase.count-1 ; i >= 0 ; i--)
                {
                    
                    //                    uploadData( i,completion: { (result) -> Void in
                    //                        self.photoThumpCollectionView.reloadData()
                    //
                    //                    })
                }
            }
            
        }
        else
        {
            self.dataSource = dummyImagesDataSource
            self.photoThumpCollectionView.reloadData()
            
        }
        
        
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
        
        dummyImagesDataSource=self.dataSource
        self.dataSource.removeAll()
        for var i = 1; i < thumbLinkArray.count-1 ; ++i {
            let downloadURL =  self.convertStringtoURL(self.thumbLinkArray[i] as! String)
            
            downloadMedia(downloadURL, key:  "ThumbImage", completion: { (result) -> Void in
                dummyImagesDataSource.append([self.thumbImageKey:result,self.fullImageKey:result])
                self.dataSource = dummyImagesDataSource
                self.photoThumpCollectionView.reloadData()
            })
        }
        self.dataSource = dummyImagesDataSource
        self.photoThumpCollectionView.reloadData()
        
        
    }
    func downloadMedia(downloadURL : NSURL ,key : String , completion: (result: UIImage) -> Void)
    {
        var dummyImagesDataSource :[[String:UIImage]]  = [[String:UIImage]]()
        var mediaImage : UIImage = UIImage()
        let data = NSData(contentsOfURL: downloadURL)
        if let imageData = data as NSData? {
            if let mediaImage1 = UIImage(data: imageData)
            {
                mediaImage = UIImage(data: imageData)!
            }
            //                let documents = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
            //                let writePath = documents.stringByAppendingString("video.mov")
            //                let url = NSURL(fileURLWithPath: writePath)
            //
            //                  imageData.writeToURL(url, atomically:true)
            
            completion(result: UIImage(data: imageData)!)
        }
        else
        {
            completion(result:mediaImage)
        }
    }
    func convertStringtoURL(url : String) -> NSURL
    {
        let url : NSString = url
        let searchURL : NSURL = NSURL(string: url as String)!
        return searchURL
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
    
}



