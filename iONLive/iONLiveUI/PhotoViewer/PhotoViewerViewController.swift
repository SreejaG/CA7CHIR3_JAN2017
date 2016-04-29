
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

class PhotoViewerViewController: UIViewController,UIGestureRecognizerDelegate,NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate,uploadProgressDelegate,NSURLSessionDownloadDelegate,UIScrollViewDelegate  {
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
    var mediaSharedCount : String = "0"
    var fullImageLinkArray: NSMutableArray = NSMutableArray()
    var mediaTimeArray: NSMutableArray = NSMutableArray()
    var dummyImagesDataSourceDatabase :[[String:UIImage]]  = [[String:UIImage]]()
    var checksDataSourceDatabase :[[String:UIImage]]  = [[String:UIImage]]()
    var progressViewDownload: UIProgressView?
    var progressLabelDownload: UILabel?
    var loadingOverlay: UIView?
    var progressDict : NSMutableArray = NSMutableArray()
    var mediaSelected: NSMutableArray = NSMutableArray()
    
    var offset: String = "0"
    var offsetToInt : Int = Int()
    var totalMediaCount: Int = Int()
    var limitMediaCount : Int = Int()
    var totalCount: Int = 0
    var fixedLimit : Int =  0
    var longPressActive : Bool = false
    @IBOutlet var playIconInFullView: UIImageView!
    
    @IBOutlet weak var mediaTimeLabel: UILabel!
    @IBOutlet var progressView: UIProgressView!
    let thumbImageKey = "thumbImage"
    let fullImageKey = "fullImageKey"
    static let identifier = "PhotoViewerViewController"
    let imageUploadManger = ImageUpload.sharedInstance
    let requestManager = RequestManager.sharedInstance
    @IBOutlet weak var photoThumpCollectionView: UICollectionView!
    @IBOutlet weak var fullScrenImageView: UIImageView!
    var dataSource:[[String:UIImage]] = [[String:UIImage]]()
    var mediaDictionary: NSMutableDictionary = NSMutableDictionary()
    let photo : PhotoThumbCollectionViewCell = PhotoThumbCollectionViewCell()
    @IBOutlet var fullScreenZoomView: UIImageView!
    var snapShots : NSMutableDictionary = NSMutableDictionary()
    var ShotsDictionary : NSMutableDictionary = NSMutableDictionary()
    var cells: NSArray = NSArray()
    var progrs: Float = 0.0
    var queue = NSOperationQueue()
    var uploadCount : Int = 0
    var selectedArray:[Int] = [Int]()
    var isLimitReached : Bool = true
    var currentLimit : Int = 0
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
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let fullyScrolledContentOffset:CGFloat = photoThumpCollectionView.frame.size.width
        
        if (scrollView.contentOffset.x >= fullyScrolledContentOffset)
        {
            print("this is end, see you in console")
            
            if(isLimitReached)
            {
                isLimitReached = false
                let qualityOfServiceClass = QOS_CLASS_BACKGROUND
                let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
                dispatch_async(backgroundQueue, {
                    self.downloadCloudData(15, scrolled: true)
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    })
                })
            }
            if(scrollView.contentOffset.x == fullyScrolledContentOffset)
            {
            }
        }
        if offsetY > contentHeight - scrollView.frame.size.height {
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillDisappear(animated: Bool) {
        
        super.viewWillDisappear(true)
        NSNotificationCenter.defaultCenter().removeObserver(self)
        
    }
    @IBAction func deleteButtonAction(sender: AnyObject) {
        for i in 0 ..< selectedArray.count
        {
            if selectedArray[i] == 1
            {
                mediaSelected.addObject(mediaIdArray[i])
            }
        }
        if(mediaSelected.count > 0)
        {
            var channelIds : [Int] = [Int]()
            
            channelIds.append(channelDict["Archive"] as! Int)
            
            let defaults = NSUserDefaults .standardUserDefaults()
            let userId = defaults.valueForKey(userLoginIdKey) as! String
            let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
            self.fullScrenImageView.alpha = 0.2
            showOverlay()
            
            imageUploadManger.deleteMediasByChannel(userId, accessToken: accessToken, mediaIds: mediaSelected, channelId: channelIds, success: { (response) -> () in
                self.authenticationSuccessHandlerDelete(response)
                }, failure: { (error, message) -> () in
                    self.authenticationFailureHandlerDelete(error, code: message)
            })
        }
        
    }
    
    func setLabelValue(index: NSInteger)
    {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat =  "yyyy-MM-dd'T'HH:mm:ss.sssZ"
        if(mediaTimeArray.count > 0)
        {
            let date = dateFormatter.dateFromString(mediaTimeArray[index] as! String)
            print(date)
            let fromdate = NSDate();
            var sdifferentString =  offsetFrom(date!, todate: fromdate)
            switch(sdifferentString)
            {
            case "TODAY" :
                break;
            case "1d" : sdifferentString = "YESTERDAY"
            break;
            default :
                
                let formatter = NSDateFormatter()
                formatter.dateStyle = NSDateFormatterStyle.MediumStyle
                let dateString = formatter.stringFromDate(date!)
                let strSplit = dateString.characters.split("-").map(String.init)
                sdifferentString = dateString
                sdifferentString = "Date(" + strSplit[1] + " " + strSplit[0] + "," + strSplit[2] + " )"
                break;
            }
            
            mediaTimeLabel.text = sdifferentString
        }
    }
    func authenticationSuccessHandlerDelete(response:AnyObject?)
    {
        removeOverlay()
        if let json = response as? [String: AnyObject]
        {
            print(json)
            
            dataSource.removeAll()
            mediaSelected.removeAllObjects()
            selectedArray.removeAll()
            mediaTypeArray.removeAllObjects()
            mediaDictionary.removeAllObjects()
            longPressActive = false
            dummyImagesDataSourceDatabase.removeAll()
            selectedCollectionViewIndex = 0
            currentLimit = 0
            limitMediaCount = 0
            getSignedURL()
        }
    }
    
    func authenticationFailureHandlerDelete(error: NSError?, code: String)
    {
        self.removeOverlay()
        self.fullScrenImageView.alpha = 1.0
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
    func  uploadProgress ( progressDictionary : NSMutableArray)
    {
        
        progressDict = progressDictionary
        self.photoThumpCollectionView.reloadData();
        
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
        playIconInFullView.hidden = true;
        
        let enlargeImageViewRecognizer = UITapGestureRecognizer(target: self, action: "enlargeImageView:")
        enlargeImageViewRecognizer.numberOfTapsRequired = 1
        fullScrenImageView.addGestureRecognizer(enlargeImageViewRecognizer)
        
        let shrinkImageViewRecognizer = UITapGestureRecognizer(target: self, action: "shrinkImageView:")
        shrinkImageViewRecognizer.numberOfTapsRequired = 1
        fullScreenZoomView.addGestureRecognizer(shrinkImageViewRecognizer)
        
        let lpgr = UILongPressGestureRecognizer(target: self, action: "handleLongPress:")
        lpgr.minimumPressDuration = 0.5
        lpgr.delaysTouchesBegan = true
        lpgr.delegate = self
        self.photoThumpCollectionView.addGestureRecognizer(lpgr)
        self.photoThumpCollectionView.allowsMultipleSelection = true;
        
    }
    
    func enlargeImageView(Recognizer:UITapGestureRecognizer){
        
        let mediaType = mediaTypeArray[selectedCollectionViewIndex] as! String
        
        
        if mediaType == "video"
        {
            //fullScreenZoomView.hidden = false
            playIconInFullView.hidden = true
            
            downloadVideo(selectedCollectionViewIndex)
            self.view.userInteractionEnabled = false
            
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
        let frame = CGRectMake(fullScrenImageView.center.x - 100, fullScrenImageView.center.y - 100, 200, 50)
        progressLabelDownload?.frame = frame
        view.addSubview(progressLabelDownload!)
        fullScrenImageView.alpha = 0.2
        
        downloadTask!.resume()
        
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        let y = Int(round(progress*100))
        
        progressLabelDownload?.text = "Downloading  \(y) %"
        progressLabelDownload!.textAlignment = NSTextAlignment.Center
        progressViewDownload!.progress = progress
        print(progress)
        print(progress * 100)
        if progress == 1.0
        {
            fullScrenImageView.alpha = 1.0
            self.view.userInteractionEnabled = true
            
            progressLabelDownload?.removeFromSuperview()
            progressViewDownload?.removeFromSuperview()
        }
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        print(location)
        let data = NSData(contentsOfURL: location)
        if let imageData = data as NSData? {
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
                NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("playerDidFinish:"), name: MPMoviePlayerPlaybackDidFinishNotification, object: self.moviePlayer)
                
                
                self.moviePlayer = MPMoviePlayerController(contentURL: url)
                if let player = self.moviePlayer {
                    player.view.frame = CGRect(x: fullScrenImageView.frame.origin.x, y: fullScrenImageView.frame.origin.y, width: fullScrenImageView.frame.size.width, height: fullScrenImageView.frame.size.height)
                    player.view.sizeToFit()
                    player.scalingMode = MPMovieScalingMode.Fill
                    //  player.fullscreen = true
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
        playIconInFullView.hidden = false
        
    }
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        
    }
    func shrinkImageView(Recognizer:UITapGestureRecognizer){
        fullScreenZoomView.hidden = true
    }
    func handleLongPress(gestureReconizer: UILongPressGestureRecognizer) {
        if gestureReconizer.state != UIGestureRecognizerState.Ended {
            return
        }
        
        let p = gestureReconizer.locationInView(self.photoThumpCollectionView)
        let indexPath = self.photoThumpCollectionView.indexPathForItemAtPoint(p)
        
        if let index = indexPath {
            let cell = self.photoThumpCollectionView.cellForItemAtIndexPath(index)
            // cell?.layer.borderWidth = 2.0
            // cell?.layer.borderColor = UIColor.blueColor().CGColor
            //
            let singleTapImageViewRecognizer = UITapGestureRecognizer(target: self, action: "singleTap:")
            singleTapImageViewRecognizer.numberOfTapsRequired = 1
            cell!.addGestureRecognizer(singleTapImageViewRecognizer)
            longPressActive = true
            
            selectedArray[(indexPath?.row)!] = 1
            photoThumpCollectionView.reloadData()
            print(index.row)
        } else {
            print("Could not find index path")
        }
    }
    
    func singleTap(Recognizer:UITapGestureRecognizer){
        let p = Recognizer.locationInView(self.photoThumpCollectionView)
        let indexPath = self.photoThumpCollectionView.indexPathForItemAtPoint(p)
        
        if let index = indexPath {
            let cell = self.photoThumpCollectionView.cellForItemAtIndexPath(index)
            cell?.layer.borderColor = UIColor.clearColor().CGColor
            cell?.removeGestureRecognizer(Recognizer)
            //   longPressActive = false;
        }
    }
    
    @IBAction func didTapAddChannelButton(sender: AnyObject) {
        mediaSelected.removeAllObjects()
        for i in 0 ..< selectedArray.count
        {
            
            if selectedArray[i] == 1
            {
                mediaSelected.addObject(mediaIdArray[i])
            }
        }
        print(mediaSelected)
        
        if(mediaSelected.count > 0)
        {
            let channelStoryboard = UIStoryboard(name:"MyChannel", bundle: nil)
            let addChannelVC = channelStoryboard.instantiateViewControllerWithIdentifier(AddChannelViewController.identifier) as! AddChannelViewController
            addChannelVC.mediaDetailSelected = mediaSelected
            addChannelVC.navigationController?.navigationBarHidden = true
            self.navigationController?.pushViewController(addChannelVC, animated: true)
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
            
            // dataSource = dummyImagesDataSourceDatabase
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
            
            if(dataSource.count == selectedArray.count){
            }
            else{
                selectedArray.append(0)
            }
            var dict = dataSource[indexPath.row]
            if let thumpImage = dict[thumbImageKey]
            {
                
                if mediaTypeArray[indexPath.row] as! String == "video"
                {
                    cell.playIcon.hidden = false
                }
                else
                {
                    cell.playIcon.hidden = true
                    
                }
                cell.thumbImageView.image = thumpImage
                if(progressDict.count>0)
                {
                    for i in 0 ..< progressDict.count 
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
                if(longPressActive)
                {
                    for i in 0 ..< selectedArray.count
                    {
                        if indexPath.row == i
                        {
                            if selectedArray[i] == 1
                            {
                                cell.layer.borderWidth = 2.0
                                cell.layer.borderColor = UIColor.blueColor().CGColor
                            }
                            else{
                                cell.layer.borderWidth = 1.0
                                cell.layer.borderColor = UIColor.clearColor().CGColor
                            }
                        }
                    }
                    
                }
                else
                {
                    cell.layer.borderWidth = 1.0
                    cell.layer.borderColor = UIColor.clearColor().CGColor
                }
                [NSNotificationCenter.defaultCenter().addObserver(self, selector:"ProgresviewUpdate:", name:"MyNotification" , object:nil)]
            }
        }
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath)
    {
        let cell = collectionView.cellForItemAtIndexPath(indexPath)
        
        
        if(!longPressActive)
        {
            //            cell!.layer.borderWidth = 2.0
            //            cell!.layer.borderColor = UIColor.blueColor().CGColor
            if dataSource.count > indexPath.row
            {
                var dict = dataSource[indexPath.row]
                selectedCollectionViewIndex = indexPath.row
                
                
                
                setLabelValue(indexPath.row)
                print("Selected Index %d %d %d ", indexPath.row , thumbLinkArray.count ,mediaTypeArray.count)
                if let fullImage = dict[fullImageKey]
                {
                    
                    
                    if mediaTypeArray[indexPath.row] as! String == "video"
                    {
                        playIconInFullView.hidden = false;
                        self.fullScrenImageView.image = fullImage
                        self.fullScreenZoomView.image = fullImage
                    }
                    else
                    {
                        print(fullImageLinkArray.count)
                        let url = fullImageLinkArray[indexPath.row]
                        
                        let downloadURL =  self.convertStringtoURL(url as! String)
                        
                        self.downloadMedia(downloadURL, key: "FullImage", completion: { (result) -> Void in
                            self.fullScrenImageView.image = result
                            self.fullScreenZoomView.image = result
                        })
                        playIconInFullView.hidden = true;
                        
                        
                    }
                }
            }
        }
        else
        {
            //            cell!.layer.borderWidth = 2.0
            //            cell!.layer.borderColor = UIColor.blueColor().CGColor
            
            for i in 0 ..< selectedArray.count
            {
                
                if i == indexPath.row
                {
                    if selectedArray[i] == 0
                    {
                        selectedArray[i] = 1
                        
                    }else{
                        selectedArray[i] = 0
                    }
                }
            }
            if selectedArray.contains(1) {
                print("yes its have")
            }
            else
            {
                print("no never")
                longPressActive = false
                
            }
            
        }
        photoThumpCollectionView.reloadData()
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
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath)
        if cell?.selected == false{
            cell?.layer.borderColor = UIColor.clearColor().CGColor
        }
        
        
        
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
     //       let defaults = NSUserDefaults .standardUserDefaults()
//            let userId = defaults.valueForKey(userLoginIdKey) as! String
//            let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
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
        
    //    let mediaDict: NSMutableDictionary = NSMutableDictionary()
        
        if let json = response as? [String: AnyObject]
        {
            let responseArr = json["MediaDetail"] as! [AnyObject]
            
            for element in responseArr{
                print(element)
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
                    else if thumbKey == "created_time_stamp"
                    {
                        print(value)
                        mediaTimeArray.addObject(value)
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
                for(var i = dummyImagesDataSourceDatabase.count-1 ; i >= 0 ; i -= 1)
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
        thumbLinkArray.removeAllObjects()
        fullImageLinkArray.removeAllObjects()
        for index in 0 ..< channelDetails.count
        {
            let channelName = channelDetails[index].valueForKey("channel_name") as! String
            let channelId = channelDetails[index].valueForKey("channel_detail_id")
            if channelName == "Archive"
            {
                mediaSharedCount = (channelDetails[index].valueForKey("total_no_media_shared")?.stringValue)!
                
                // mediaSharedCount = "20"
            }
            
            channelDict[channelName] = channelId
            
            
        }
        
        getMediaFromCloud()
    }
    func getMediaFromCloud()
    {
        let defaults = NSUserDefaults .standardUserDefaults()
        let userId = defaults.valueForKey(userLoginIdKey) as! String
        let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
        let channelId = channelDict["Archive"] as! NSNumber
        
        let offsetString : String = String(offsetToInt)
        
        //        imageUploadManger.getChannelMediaDetails(channelId.stringValue , userName: userId, accessToken: accessToken, limit: String(limit), offset: offsetString, success: { (response) -> () in
        //            self.authenticationSuccessHandlerForFetchMedia(response)
        //            }) { (error, message) -> () in
        //                self.authenticationFailureHandlerForFetchMedia(error, code: message)
        //        }
        
        if mediaSharedCount == "0"
        {
            ErrorManager.sharedInstance.emptyMedia()
           removeOverlay()

        }else
        {
        imageUploadManger.getChannelMediaDetails(channelId.stringValue , userName: userId, accessToken: accessToken, limit: mediaSharedCount, offset: "0", success: { (response) -> () in
            self.authenticationSuccessHandlerForFetchMedia(response)
        }) { (error, message) -> () in
            self.authenticationFailureHandlerForFetchMedia(error, code: message)
        }
        }
        
        //        imageUploadManger.getChannelMediaDetails(channelId.stringValue , userName: userId, accessToken: accessToken, limit: "8", offset: "0" , success: { (response) -> () in
        //            self.authenticationSuccessHandlerForFetchMedia(response)
        //
        //            }) { (error, message) -> () in
        //                self.authenticationFailureHandlerForFetchMedia(error, code: message)
        //
        //        }
    }
    func downloadFirstEntry()
    {
        playIconInFullView.hidden = true
        
        var dummyImagesDataSource :[[String:UIImage]]  = [[String:UIImage]]()
        
        if(self.fullImageLinkArray.count > 0 && self.thumbLinkArray.count > 0)
        {
            var downloadedFullImage : UIImage = UIImage()
            var downloadedThumbImage : UIImage = UIImage()
            
            let mediaDict: NSMutableDictionary = NSMutableDictionary()
            
            
            dummyImagesDataSource = self.dataSource
            self.dataSource .removeAll()
            setLabelValue(0)
            let fullImageDownloadUrl = convertStringtoURL(self.fullImageLinkArray[0] as! String)
            //   downloadMedia(fullImageDownloadUrl, key: "FullImage")
            let downloadThumbURL =  self.convertStringtoURL(self.thumbLinkArray[0] as! String)
            
            
            let mediaType = self.mediaTypeArray[0] as! String
            if mediaType == "image"
            {
                downloadMedia(fullImageDownloadUrl, key:  "FullImage") { (result) -> Void in
                    
                    
                    //                    let imgData: NSData = UIImageJPEGRepresentation(result, 0)!
                    //                    print("Size of Image: \(imgData.length) bytes")
                    mediaDict.setValue(result, forKey: "FullImage")
                    
                    
                    self.downloadMedia(downloadThumbURL, key: "ThumbImage", completion: { (result) -> Void in
                        print("Execution Completed 2",result)
                        //  let imgData: NSData = UIImageJPEGRepresentation(result, 0)!
                        //   print("Size of Image thumb  : \(imgData.length) bytes")
                        mediaDict.setValue(result, forKey: "ThumbImage")
                        if dummyImagesDataSource.count > 0
                        {
                            self.fullScrenImageView.image = dummyImagesDataSource[0][self.fullImageKey]
                            self.fullScreenZoomView.image = dummyImagesDataSource[0][self.fullImageKey]
                        }
                        else
                        {
                            print("from media dict")
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
                    //                    let imgData: NSData = UIImageJPEGRepresentation(result, 0)!
                    //                    print("Size of Image thumb for video  : \(imgData.length) bytes")
                    if dummyImagesDataSource.count > 0
                    {
                        self.fullScrenImageView.image = dummyImagesDataSource[0][self.fullImageKey]
                        self.fullScreenZoomView.image = dummyImagesDataSource[0][self.fullImageKey]
                        self.playIconInFullView.hidden = false
                    }
                    else
                    {
                        self.fullScrenImageView.image = mediaDict["ThumbImage"] as? UIImage
                        self.fullScreenZoomView.image = mediaDict["ThumbImage"] as? UIImage
                        self.playIconInFullView.hidden = false
                        
                    }
                    dummyImagesDataSource.append([self.thumbImageKey:mediaDict["ThumbImage"] as! UIImage,self.fullImageKey:mediaDict["ThumbImage"] as! UIImage])
                    
                    
                    self.dataSource = dummyImagesDataSource
                    self.photoThumpCollectionView.reloadData()
                    
                    
                    self.mediaDictionary.setValue(mediaDict, forKey: "0")
                    self.removeOverlay()
                    
                    
                })
            }
            
            downloadCloudData(15, scrolled: false)
            
            
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
    func downloadCloudData(limitMedia : Int , scrolled : Bool)
        
    {
        var dummyImagesDataSource :[[String:UIImage]]  = [[String:UIImage]]()
        
        dummyImagesDataSource=self.dataSource
        self.dataSource.removeAll()
        print(limitMedia)
        
        if(thumbLinkArray.count <  (currentLimit +  limitMedia))
        {
            
            limitMediaCount = currentLimit
            if currentLimit == 0
            {
                limitMediaCount = 1
            }
            currentLimit = currentLimit + (thumbLinkArray.count - currentLimit)
            
        }
        else if (thumbLinkArray.count > (currentLimit +  limitMedia))
        {
            limitMediaCount = currentLimit
            if currentLimit == 0
            {
                limitMediaCount = 1
            }
            currentLimit = currentLimit + 15
            
        }
        else if(currentLimit == thumbLinkArray.count)
        {
            return
            
        }
        
        
        if(!scrolled)
        {
            for var i = limitMediaCount; i <= currentLimit ; i += 1
            {
                print(i)
                print(currentLimit)
                print(thumbLinkArray.count)
                if(thumbLinkArray.count-1 >= i)
                {
                    let downloadURL =  self.convertStringtoURL(self.thumbLinkArray[i] as! String)
                    print("Not scrolled %d",i)
                    downloadMedia(downloadURL, key:  "ThumbImage", completion: { (result) -> Void in
                        dummyImagesDataSource.append([self.thumbImageKey:result,self.fullImageKey:result])
                        
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.dataSource = dummyImagesDataSource
                            self.photoThumpCollectionView.reloadData()
                        })
                        
                        
                        
                        
                    })
                }
            }
        }
        else
        {
            
            for var i = limitMediaCount+1; i <= currentLimit ; i += 1 {
                print(" scrolled %d",i)
                
                if(i >= thumbLinkArray.count - 1)
                {
                    print("endreached")
                    return
                }
                let downloadURL =  self.convertStringtoURL(self.thumbLinkArray[i] as! String)
                
                downloadMedia(downloadURL, key:  "ThumbImage", completion: { (result) -> Void in
                    dummyImagesDataSource.append([self.thumbImageKey:result,self.fullImageKey:result])
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.dataSource = dummyImagesDataSource
                        self.photoThumpCollectionView.reloadData()
                    })
                    
                    
                })
            }
            
        }
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.dataSource = dummyImagesDataSource
            self.photoThumpCollectionView.reloadData()
        })
        isLimitReached = true
        self.fullScrenImageView.alpha = 1.0
        
        
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
            print("null Image")
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
    func yearsFrom(date:NSDate, todate:NSDate) -> Int{
        return NSCalendar.currentCalendar().components(.Year, fromDate: date, toDate: todate, options: []).year
    }
    func monthsFrom(date:NSDate,todate:NSDate) -> Int{
        return NSCalendar.currentCalendar().components(.Month, fromDate: date, toDate: todate, options: []).month
    }
    func weeksFrom(date:NSDate,todate:NSDate) -> Int{
        return NSCalendar.currentCalendar().components(.WeekOfYear, fromDate: date, toDate: todate, options: []).weekOfYear
    }
    func daysFrom(date:NSDate,todate:NSDate) -> Int{
        return NSCalendar.currentCalendar().components(.Day, fromDate: date, toDate: todate, options: []).day
    }
    func hoursFrom(date:NSDate,todate:NSDate) -> Int{
        return NSCalendar.currentCalendar().components(.Hour, fromDate: date, toDate: todate, options: []).hour
    }
    func minutesFrom(date:NSDate,todate:NSDate) -> Int{
        return NSCalendar.currentCalendar().components(.Minute, fromDate: date, toDate: todate, options: []).minute
    }
    func secondsFrom(date:NSDate,todate:NSDate) -> Int{
        return NSCalendar.currentCalendar().components(.Second, fromDate: date, toDate: todate, options: []).second
    }
    func offsetFrom(date:NSDate,todate:NSDate) -> String {
        if yearsFrom(date,todate:todate)   > 0 {
            return "\(yearsFrom(date,todate:todate))y"
        }
        if monthsFrom(date,todate:todate)  > 0 { return "\(monthsFrom(date,todate:todate))M"  }
        if weeksFrom(date,todate:todate)   > 0 {  return "\(weeksFrom(date,todate:todate))w"   }
        if daysFrom(date,todate:todate)    > 0 { return "\(daysFrom(date,todate:todate))d"    }
        if hoursFrom(date,todate:todate)   > 0 { return "TODAY"   }
        if minutesFrom(date,todate:todate) > 0 { return "TODAY"   }
        if secondsFrom(date,todate:todate) > 0 { return "TODAY"   }
        return ""
    }
    
}



