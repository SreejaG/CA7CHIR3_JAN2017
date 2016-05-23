
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

class PhotoViewerViewController: UIViewController,UIGestureRecognizerDelegate,NSURLSessionDelegate, NSURLSessionTaskDelegate,NSURLSessionDataDelegate,NSURLSessionDownloadDelegate,UIScrollViewDelegate
{
    let channelManager = ChannelManager.sharedInstance
    let mediaCacheManager = MediaCache.sharedInstance
    var channelDict = Dictionary<String, AnyObject>()
    var thumbImage : UIImage = UIImage()
    var fullImage  : UIImage = UIImage()
    var delegate:progressviewDelegate?
    let signedURLResponse: NSMutableDictionary = NSMutableDictionary()
    var channelDetails: NSMutableArray = NSMutableArray()
    var selectedCollectionViewIndex : Int = 0
    var moviePlayer : MPMoviePlayerController!
    var mediaSharedCount : String = "0"
    var dummyImagesDataSourceDatabase :[[String:AnyObject]] = [[String:AnyObject]]()
    var cacheDatabase :[[String:UIImage]]  = [[String:UIImage]]()
    var progressViewDownload: UIProgressView?
    var progressLabelDownload: UILabel?
    var loadingOverlay: UIView?
    var progressDict : [[String:AnyObject]] = [[String:AnyObject]]()
    var mediaSelected: NSMutableArray = NSMutableArray()
    var imageDataSource: [[String:AnyObject]] = [[String:AnyObject]]()
    var offset: String = "0"
    var offsetToInt : Int = Int()
    var totalMediaCount: Int = Int()
    var limitMediaCount : Int = Int()
    var totalCount: Int = 0
    var fixedLimit : Int =  0
    var videoDownloadIntex : Int = 0
    var timerUpload : NSTimer = NSTimer()
    var timerStop : NSTimer = NSTimer()
    @IBOutlet var playIconInFullView: UIImageView!
    var selectedArray:[Int] = [Int]()

    @IBOutlet var BottomView: UIView!
    @IBOutlet weak var mediaTimeLabel: UILabel!
    @IBOutlet var progressView: UIProgressView!
    let thumbImageKey = "thumbImage"
    let fullImageKey = "fullImageKey"
    static let identifier = "PhotoViewerViewController"
    let imageUploadManger = ImageUpload.sharedInstance
    let requestManager = RequestManager.sharedInstance
    @IBOutlet weak var photoThumpCollectionView: UICollectionView!
    @IBOutlet weak var fullScrenImageView: UIImageView!
    var dataSource:[[String:AnyObject]] = [[String:AnyObject]]()
    var mediaDictionary: NSMutableDictionary = NSMutableDictionary()
    let photo : PhotoThumbCollectionViewCell = PhotoThumbCollectionViewCell()
    @IBOutlet var fullScreenZoomView: UIImageView!
    var snapShots : NSMutableDictionary = NSMutableDictionary()
    var ShotsDictionary : NSMutableDictionary = NSMutableDictionary()
    var cells: NSArray = NSArray()
    var progrs: Float = 0.0
    var queue = NSOperationQueue()
    var uploadCount : Int = 0
    var isLimitReached : Bool = true
    var currentLimit : Int = 0
    let thumbSignedUrlKey = "thumbnail_name_SignedUrl"
    let fullSignedUrlKey = "gcs_object_name_SignedUrl"
    let mediaIdKey = "media_detail_id"
    let mediaTypeKey = "gcs_object_type"
    let timeStampKey = "created_time_stamp"
    var completed : Bool = false
    var uploadMediaDict : [[String:AnyObject]]  = [[String:AnyObject]]()
    var upCount: Int = Int()
    var mediaIdSelected : Int = 0

    
    @IBOutlet var doneButton: UIButton!
    @IBOutlet var addToButton: UIButton!
    @IBOutlet var deletButton: UIButton!
    private var downloadTask: NSURLSessionDownloadTask?
    class var sharedInstance: PhotoViewerViewController {
        struct Singleton {
            static let instance = PhotoViewerViewController()
        }
        return Singleton.instance
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        doneButton.setTitle("Done", forState: .Normal)
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
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(nil, forKey: "uploaObjectDict")
        
        timerUpload.invalidate()
        NSNotificationCenter.defaultCenter().removeObserver(self)
        removeOverlay()
        
        if(downloadTask?.state == .Running)
        {
            downloadTask?.cancel()
        }
    }
    
    @IBAction func deleteButtonAction(sender: AnyObject) {
        
        mediaSelected.removeAllObjects()
        if mediaIdSelected == 0
        {
            mediaIdSelected = dataSource[0][mediaIdKey] as! Int
        }
        print(mediaIdSelected)
        mediaSelected.addObject(mediaIdSelected)
        
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
    
    
    func setLabelValue(index: NSInteger)
    {
                if(dataSource.count > 0)
                {
                    let dateFormatter = NSDateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                    dateFormatter.timeZone = NSTimeZone(name: "UTC")
                    let fromdate = dateFormatter.dateFromString(dataSource[index][timeStampKey] as! String)
                    var dateForDisplay : String
                    if(fromdate != nil){
                        let dateStr = dateFormatter.stringFromDate(NSDate())
                        let currentDate = dateFormatter.dateFromString(dateStr)
                        let sdifferentString =  offsetFrom(fromdate!, todate: currentDate!)
                        print("\(sdifferentString)   \(currentDate!)    \(fromdate)")
                        switch(sdifferentString)
                        {
                            case "TODAY" :
                                dateForDisplay = "TODAY"
                                break;
                            case "1d" : dateForDisplay = "YESTERDAY"
                                    break;
                            default :
        
                                let formatter = NSDateFormatter()
                                formatter.dateStyle = NSDateFormatterStyle.MediumStyle
                                let dateString = formatter.stringFromDate(currentDate!)
                                let strSplit = dateString.characters.split("-").map(String.init)
                                dateForDisplay = dateString
                                dateForDisplay = strSplit[1] + " " + strSplit[0] + "," + strSplit[2] 
                                break;
                        }
                    }
                    else{
                        dateForDisplay = "TODAY"
                    }
        
                    mediaTimeLabel.text = dateForDisplay
                }
    }
    
    func authenticationSuccessHandlerDelete(response:AnyObject?)
    {
        removeOverlay()
        if let json = response as? [String: AnyObject]
        {
            mediaIdSelected = 0
            dataSource.removeAll()
            mediaSelected.removeAllObjects()
            imageDataSource.removeAll()
            mediaDictionary.removeAllObjects()
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
        print(code)
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
    func  uploadProgress ( progressDictionary :  [[String:AnyObject]])
    {
        
        progressDict = progressDictionary
        print(progressDict.count)
        var count: Int = Int()
        count = 0
        for(var  i = 0 ; i < progressDict.count ; i++)
        {
            
            print(progressDict[i][mediaIdKey])
            print(progressDict[i]["progress"] as! Float)
            
            if(progressDict[i]["progress"] as! Float == 1.0 || progressDict[i]["progress"] as! Float == 1)
            {
                count = count+1
            }
            
        }
        if(count == progressDictionary.count)
        {
           // timerUpload .invalidate()
         //  progressDict.removeAll()
          //  NSUserDefaults.standardUserDefaults().setValue(nil, forKey: "ProgressDict")
          //  NSUserDefaults.standardUserDefaults().setValue(nil, forKey: "uploaObjectDict")

        }
        self.photoThumpCollectionView.reloadData();
    }
    
    func getSignedURL()
    {
        showOverlay()
        photoThumpCollectionView.scrollEnabled = true

        selectedArray.removeAll()
        let defaults = NSUserDefaults .standardUserDefaults()
        let userId = defaults.valueForKey(userLoginIdKey) as! String
        let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
        getChannelDetails(userId, token: accessToken)
    }
    
    func showOverlay(){
        let loadingOverlayController:IONLLoadingView=IONLLoadingView(nibName:"IONLLoadingOverlay", bundle: nil)
        loadingOverlayController.view.frame = CGRectMake(0, 64, self.view.frame.width, self.view.frame.height - 64)
        loadingOverlayController.startLoading()
        self.loadingOverlay = loadingOverlayController.view
        self.navigationController?.view.addSubview(self.loadingOverlay!)
    }
    
    func removeOverlay(){
        self.loadingOverlay?.removeFromSuperview()
    }
    
    func initialise()
    {
        selectedArray.removeAll()

        fullScreenZoomView.userInteractionEnabled = true
        fullScreenZoomView.hidden = true
        fullScrenImageView.userInteractionEnabled = true
        playIconInFullView.hidden = true;
        
        let enlargeImageViewRecognizer = UITapGestureRecognizer(target: self, action: #selector(PhotoViewerViewController.enlargeImageView(_:)))
        enlargeImageViewRecognizer.numberOfTapsRequired = 1
        fullScrenImageView.addGestureRecognizer(enlargeImageViewRecognizer)
        
        let shrinkImageViewRecognizer = UITapGestureRecognizer(target: self, action: #selector(PhotoViewerViewController.shrinkImageView(_:)))
        shrinkImageViewRecognizer.numberOfTapsRequired = 1
        fullScreenZoomView.addGestureRecognizer(shrinkImageViewRecognizer)
        
        deletButton.hidden = true
        addToButton.hidden = true
        BottomView.alpha = 0.3
        mediaIdSelected = 0
      
    }
    
    func enlargeImageView(Recognizer:UITapGestureRecognizer){
        
        if dataSource[selectedCollectionViewIndex][mediaTypeKey] != nil
        {
        let mediaType = dataSource[selectedCollectionViewIndex][mediaTypeKey] as! String
        
        if mediaType == "video"
        {
            playIconInFullView.hidden = true
            downloadVideo(selectedCollectionViewIndex)
        }
        else
        {
            fullScreenZoomView.hidden = false
        }
        }
    }
    
    func downloadVideo(index : Int)
    {
        videoDownloadIntex = index
        let videoDownloadUrl = convertStringtoURL(self.imageDataSource[index][fullSignedUrlKey] as! String)
        
        let mediaIdForFilePath = "\(imageDataSource[index][mediaIdKey]!)"
        let parentPath = FileManagerViewController.sharedInstance.getParentDirectoryPath()
        let savingPath = "\(parentPath)/\(mediaIdForFilePath)video.mov"
        
        let fileExistFlag = FileManagerViewController.sharedInstance.fileExist(savingPath)
        if fileExistFlag == true
        {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(PhotoViewerViewController.playerDidFinish(_:)), name: MPMoviePlayerPlaybackDidFinishNotification, object: self.moviePlayer)
            
            let url = NSURL(fileURLWithPath: savingPath)
            self.moviePlayer = MPMoviePlayerController.init(contentURL: url)
            
            if let player = self.moviePlayer
            {
                self.view.userInteractionEnabled = false
                player.shouldAutoplay = true
                player.prepareToPlay()
                player.view.frame = CGRect(x: fullScrenImageView.frame.origin.x, y: fullScrenImageView.frame.origin.y, width: fullScrenImageView.frame.size.width, height: fullScrenImageView.frame.size.height)
                
                player.view.sizeToFit()
                player.scalingMode = MPMovieScalingMode.Fill
                player.controlStyle = MPMovieControlStyle.None
                player.movieSourceType = MPMovieSourceType.File
                player.repeatMode = MPMovieRepeatMode.None
                self.view.addSubview(player.view)
                player.play()
            }
        }
        else{
            let downloadRequest = NSMutableURLRequest(URL: videoDownloadUrl)
            let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration(), delegate: self, delegateQueue: NSOperationQueue.mainQueue())
            
            downloadTask = session.downloadTaskWithRequest(downloadRequest)
            progressViewDownload = UIProgressView(progressViewStyle: UIProgressViewStyle.Default)
            progressViewDownload?.center = fullScrenImageView.center
            
            view.addSubview(progressViewDownload!)
            
            progressLabelDownload = UILabel()
            let frame = CGRectMake(fullScrenImageView.center.x - 100, fullScrenImageView.center.y - 100, 200, 50)
            progressLabelDownload?.frame = frame
            view.addSubview(progressLabelDownload!)
            fullScrenImageView.alpha = 0.2
            downloadTask!.resume()
        }
        
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        let y = Int(round(progress*100))
        
        progressLabelDownload?.text = "Downloading  \(y) %"
        progressLabelDownload!.textAlignment = NSTextAlignment.Center
        progressViewDownload!.progress = progress
        if progress == 1.0
        {
            fullScrenImageView.alpha = 1.0
            progressLabelDownload?.removeFromSuperview()
            progressViewDownload?.removeFromSuperview()
        }
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        let data = NSData(contentsOfURL: location)
        if let imageData = data as NSData? {
            let mediaIdForFilePath = "\(imageDataSource[videoDownloadIntex][mediaIdKey]!)"
            let parentPath = FileManagerViewController.sharedInstance.getParentDirectoryPath().absoluteString
            let savingPath = "\(parentPath)/\(mediaIdForFilePath)video.mov"
            let url = NSURL(fileURLWithPath: savingPath)
            let writeFlag = imageData.writeToURL(url, atomically: true)
            if(writeFlag){
                NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(PhotoViewerViewController.playerDidFinish(_:)), name: MPMoviePlayerPlaybackDidFinishNotification, object: self.moviePlayer)
                videoDownloadIntex = 0
                
                self.moviePlayer = MPMoviePlayerController.init(contentURL: url)
                if let player = self.moviePlayer {
                    self.view.userInteractionEnabled = false
                    player.view.frame = CGRect(x: fullScrenImageView.frame.origin.x, y: fullScrenImageView.frame.origin.y, width: fullScrenImageView.frame.size.width, height: fullScrenImageView.frame.size.height)
                    player.view.sizeToFit()
                    player.scalingMode = MPMovieScalingMode.Fill
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
        self.view.userInteractionEnabled = true
    }
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
    }
    func shrinkImageView(Recognizer:UITapGestureRecognizer){
        fullScreenZoomView.hidden = true
    }
    @IBAction func didTapAddChannelButton(sender: AnyObject) {
        mediaSelected.removeAllObjects()
        if mediaIdSelected == 0
        {
            mediaIdSelected = dataSource[0][mediaIdKey] as! Int
        }
        mediaSelected.addObject(mediaIdSelected)
        mediaIdSelected = 0
        if(mediaSelected.count > 0)
        {
            let channelStoryboard = UIStoryboard(name:"MyChannel", bundle: nil)
            let addChannelVC = channelStoryboard.instantiateViewControllerWithIdentifier(AddChannelViewController.identifier) as! AddChannelViewController
            addChannelVC.mediaDetailSelected = mediaSelected
            addChannelVC.navigationController?.navigationBarHidden = true
            self.navigationController?.pushViewController(addChannelVC, animated: false)
        }
    }
    func checkData()
    {
        let defaults = NSUserDefaults .standardUserDefaults()
        if defaults.objectForKey("uploaObjectDict") != nil{
            let data  =  defaults.objectForKey("uploaObjectDict") as! NSData
            uploadMediaDict =  NSKeyedUnarchiver.unarchiveObjectWithData(data) as! [[String : AnyObject]]
        }
        if(uploadMediaDict.count > 0)
        {
            timerUpload.invalidate()
            timerStop.invalidate()
            timerUpload = NSTimer.scheduledTimerWithTimeInterval(0.4, target: self, selector: #selector(PhotoViewerViewController.update), userInfo: nil, repeats: true)
             timerStop = NSTimer.scheduledTimerWithTimeInterval(5, target: self, selector: #selector(PhotoViewerViewController.stopTimer), userInfo: nil, repeats: true)
            //  update()
        }
    }
    func stopTimer()
    {
        
        update()
        timerUpload.invalidate()
        timerStop.invalidate()
        progressDict.removeAll()
        NSUserDefaults.standardUserDefaults().setValue(nil, forKey: "ProgressDict")
        NSUserDefaults.standardUserDefaults().setValue(nil, forKey: "uploaObjectDict")
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            let imagePath = self.dataSource[0][self.fullImageKey]!
            
            
           self.fullScrenImageView.image = (imagePath as! UIImage)
           self.fullScreenZoomView.image = (imagePath as! UIImage)

            self.photoThumpCollectionView.reloadData()
        })

    }
    func uploadMediaProgress()
    {
        update()
    }
    func update()
    {
        let defaults = NSUserDefaults .standardUserDefaults()
        if  defaults.objectForKey("uploaObjectDict") != nil
        {
            let data  =  defaults.objectForKey("uploaObjectDict") as! NSData
            uploadMediaDict =  NSKeyedUnarchiver.unarchiveObjectWithData(data) as! [[String : AnyObject]]
            upCount = uploadMediaDict.count
            let cameraController = IPhoneCameraViewController()
            uploadCount = snapShots.count
            print(uploadCount)
            print(uploadMediaDict.count)
            if(uploadMediaDict.count != uploadCount)
            {
                var dummyImages :[[String:AnyObject]] = [[String:AnyObject]]()
                dummyImages = dataSource
                dataSource.removeAll()
                // dataSource = uploadMediaDict
                for(var i = uploadMediaDict.count - 1 ;i >= 0 ; i--)
                {
                    self.dataSource.append(uploadMediaDict[i])
                    if(i == uploadMediaDict.count - 1)
                    {
                        if let imagePath = uploadMediaDict[i][fullImageKey]
                        {
                            let type = uploadMediaDict[i][mediaTypeKey] as! String
                            
                            if type == "video"
                            {
                                self.playIconInFullView.hidden = false
                            }
                            else{
                                self.playIconInFullView.hidden = true
                                
                            }
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                
                                self.fullScrenImageView.image = (imagePath as! UIImage)
                                self.fullScreenZoomView.image = (imagePath as! UIImage)
                            })
                        }
                    }
                    
                }
                for element in dummyImages
                {
                    var flag : Bool = false
                    for(var i = 0 ;i < dataSource.count ; i++)
                    {
                        if dataSource[i][mediaIdKey]?.stringValue == element[mediaIdKey]?.stringValue
                        {
                            flag = true
                        }
                    }
                    if(!flag)
                    {
                        self.dataSource.append(element)
                    }
                }
                    self.photoThumpCollectionView.reloadData()
            }
            else
            {
                var dummyImages :[[String:AnyObject]] = [[String:AnyObject]]()
                
                dummyImages = dataSource
                
                dataSource.removeAll()
                for(var i = uploadMediaDict.count - 1 ; i >= 0 ; i--)
                {
                    self.dataSource.append(uploadMediaDict[i])
                    if let imagePath = uploadMediaDict[i][fullImageKey]
                    {
                        let type = uploadMediaDict[i][mediaTypeKey] as! String
                        
                        if type == "video"
                        {
                            self.playIconInFullView.hidden = false
                        }
                        else{
                            self.playIconInFullView.hidden = true
                            
                        }
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            
                            self.fullScrenImageView.image = (imagePath as! UIImage)
                            self.fullScreenZoomView.image = (imagePath as! UIImage)
                        })
                        
                        
                    }
                }
                
                for element in dummyImages
                {
                    var flag : Bool = false
                    for(var i = 0 ;i < dataSource.count ; i++)
                    {
                        if dataSource[i][mediaIdKey]?.stringValue == element[mediaIdKey]?.stringValue
                        {
                            flag = true
                        }
                    }
                    if(!flag)
                    {
                        self.dataSource.append(element)
                        
                    }
                    
                }
                print(dataSource.count)
                timerUpload .invalidate()
                defaults.setObject(nil, forKey: "uploaObjectDict")
                    self.photoThumpCollectionView.reloadData()
            }
        }
    }

    func readImageFromDataBase()
    {
        let cameraController = IPhoneCameraViewController()
        uploadCount = snapShots.count
        checkData()
    }
    
    //PRAGMA MARK:- IBActions
    
    @IBAction func channelButtonClicked(sender: AnyObject)
    {
        let myChannelStoryboard = UIStoryboard(name:"MyChannel" , bundle: nil)
        let myChannelVC = myChannelStoryboard.instantiateViewControllerWithIdentifier(MyChannelViewController.identifier)
        myChannelVC.navigationController?.navigationBarHidden = true
        self.navigationController?.pushViewController(myChannelVC, animated: false)
    }
    
    @IBAction func donebuttonClicked(sender: AnyObject)
    {
        if(doneButton.titleLabel?.text == "Cancel"){
            selectedArray.removeAll()
            for i in 0 ..< dataSource.count
            {
                selectedArray.append(0)
            }
            photoThumpCollectionView.reloadData()
            photoThumpCollectionView.layoutIfNeeded()
            photoThumpCollectionView.scrollEnabled = true
            doneButton.setTitle("Done", forState: .Normal)
            deletButton.hidden = true
            addToButton.hidden = true
        }
        else{
            let cameraViewStoryboard = UIStoryboard(name:"IPhoneCameraView" , bundle: nil)
            let iPhoneCameraViewController = cameraViewStoryboard.instantiateViewControllerWithIdentifier("IPhoneCameraViewController") as! IPhoneCameraViewController
            self.navigationController?.navigationBarHidden = true
            self.navigationController?.pushViewController(iPhoneCameraViewController, animated: false)
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
       // cell.layer.borderColor = UIColor.clearColor().CGColor;
        if(dataSource.count == selectedArray.count){
        }
        else{
            selectedArray.append(0)
        }
        if dataSource.count > indexPath.row
        {
            var dict = dataSource[indexPath.row]
            
            
            
            
            
            for i in 0 ..< selectedArray.count
            {
                if indexPath.row == i
                {
                    if selectedArray[i] == 1
                    {
                        cell.layer.borderWidth = 2;
                        cell.layer.borderColor = UIColor(red: 44.0/255.0, green: 214.0/255.0, blue: 229.0/255.0, alpha: 0.7).CGColor
                    }
                    else{
                        cell.layer.borderWidth = 0;
                        cell.layer.borderColor = UIColor.clearColor().CGColor;
                    }
                }
            }

            if let thumpImage = dict[thumbImageKey]
            {
                if dataSource[indexPath.row][mediaTypeKey] as! String == "video"
                {
                    cell.playIcon.hidden = false
                }
                else
                {
                    cell.playIcon.hidden = true
                }
               cell.progressView.hidden = true

                cell.thumbImageView.image = (thumpImage as! UIImage)
                if(progressDict.count>0)
                {
                    for i in 0 ..< progressDict.count
                    {
                        if(indexPath.row < upCount)
                        {
                            var mediaId : String = String()
                            mediaId = progressDict[i][mediaIdKey] as! String
                            cell.progressView.hidden = false
                            if(upCount == 1)
                            {
                                cell.cloudIcon.hidden = true
                                fullScrenImageView.userInteractionEnabled = false
                                cell.progressView.progress = progressDict[i]["progress"]!.floatValue
                                print(progressDict[i]["progress"]!.floatValue)
                            }
                            if mediaId == String(dataSource[indexPath.row][mediaIdKey]!)
                            {
                                fullScrenImageView.userInteractionEnabled = false
                                
                                cell.progressView.progress = progressDict[i]["progress"]!.floatValue
                                print(progressDict[i]["progress"]!.floatValue)
                                
                                if(progressDict[i]["progress"]!.floatValue == 1.0 || progressDict[i]["progress"]!.floatValue == 1)
                                {
                                    cell.progressView.hidden = true
                                    cell.cloudIcon.hidden = false
                                    fullScrenImageView.userInteractionEnabled = true
                                }
                                else{
                                    cell.cloudIcon.hidden = false
                                }
                            }
                        }
                        else
                        {
                            cell.cloudIcon.hidden = false
                            cell.progressView.hidden = true
                        }
                    }
                }
                else
                {
                    cell.cloudIcon.hidden = false

                    cell.progressView.hidden = true
                }
            }
            
        }
        return cell
    }
  
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath)
    {
        photoThumpCollectionView.scrollEnabled = false
        doneButton.setTitle("Cancel", forState: .Normal)
        for i in 0 ..< selectedArray.count
        {
            
            if i == indexPath.row
            {
                selectedArray[i] = 1
                    
            }
            else{
                selectedArray[i] = 0
            }
        }
        photoThumpCollectionView.reloadData()
        if dataSource.count > indexPath.row
        {
            if(downloadTask?.state == .Running)
            {
                downloadTask?.cancel()
            }
            progressViewDownload?.hidden = true
            progressLabelDownload?.hidden = true
            mediaIdSelected = dataSource[indexPath.row][mediaIdKey] as! Int
            if(mediaIdSelected != 0){
                deletButton.hidden = false
                addToButton.hidden = false
                BottomView.alpha = 1.0
            }
            else{
                deletButton.hidden = true
                addToButton.hidden = true
                BottomView.alpha = 0.3
            }
            var dict = dataSource[indexPath.row]
            selectedCollectionViewIndex = indexPath.row
            setLabelValue(indexPath.row)
            var imageForMedia : UIImage = UIImage()

            if let fullImage = dict[fullImageKey]
            {
                if dataSource[indexPath.row][mediaTypeKey] as! String == "video"
                {
                    playIconInFullView.hidden = false;
                    self.fullScrenImageView.image = (fullImage as! UIImage)
                    self.fullScreenZoomView.image = (fullImage as! UIImage)
                }
                else
                {
                    if(indexPath.row < uploadCount)
                    {
                        imageForMedia = dataSource[indexPath.row][fullImageKey] as! UIImage
                    }
                    else{
                        
                        let mediaUrl = dataSource[indexPath.row][fullSignedUrlKey] as! String
                        if(mediaUrl != ""){
                            let url: NSURL = convertStringtoURL(mediaUrl)
                            
                            
                            downloadMedia(url, key: "ThumbImage", completion: { (result) -> Void in
                                //  FileManagerViewController.sharedInstance.saveImageToFilePath(mediaIdForFilePath, mediaImage: result)
                                if(result != UIImage()){
                                    imageForMedia = result
                                }
                                else{
                                    imageForMedia = UIImage()
                                }
                            })
                        }
                    }
                    
                    fullScrenImageView.alpha = 1.0
                    
                    self.fullScrenImageView.image = imageForMedia as UIImage
                    self.fullScreenZoomView.image = imageForMedia as UIImage
                    playIconInFullView.hidden = true;
                }
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
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath)
        if cell?.selected == false{
            cell?.layer.borderColor = UIColor.clearColor().CGColor
        }
    }
    
    //PRAGMA MARK:- Channel details
    
    func getChannelDetails(userName: String, token: String)
    {
        self.deletButton.hidden = true
        self.addToButton.hidden = true
        BottomView.alpha = 0.3
        mediaIdSelected = 0
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
        
         photoThumpCollectionView.reloadData()
    }
    
    func authenticationSuccessHandlerForFetchMedia(response:AnyObject?)
    {
        self.readImageFromDataBase()
        
        if let json = response as? [String: AnyObject]
        {
            let responseArr = json["MediaDetail"] as! [AnyObject]
            for index in 0 ..< responseArr.count
            {
                let thumb = responseArr[index].valueForKey(thumbSignedUrlKey)
                let fullImage = responseArr[index].valueForKey(fullSignedUrlKey)
                let mediaId = responseArr[index].valueForKey(mediaIdKey)
                let mediaType = responseArr[index].valueForKey(mediaTypeKey)
                
                let timeStamp = responseArr[index].valueForKey(timeStampKey)
                
                imageDataSource.append([thumbSignedUrlKey:thumb!,fullSignedUrlKey: fullImage! ,mediaIdKey:mediaId!,mediaTypeKey:mediaType!,timeStampKey :timeStamp!])
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
            if((code == "USER004") || (code == "USER005") || (code == "USER006")){
                loadInitialViewController()
            }
            
            self.readImageFromDataBase()
        }
        else{
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
            if((code == "USER004") || (code == "USER005") || (code == "USER006")){
                loadInitialViewController()
            }
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
            if((code == "USER004") || (code == "USER005") || (code == "USER006")){
                loadInitialViewController()
            }
        }
        else{
            ErrorManager.sharedInstance.inValidResponseError()
        }
        
    }
    
    //PRAGMA MARK:- Set Channel
    
    func setChannelDetails()
    {
        imageDataSource.removeAll()
        for index in 0 ..< channelDetails.count
        {
            let channelName = channelDetails[index].valueForKey("channel_name") as! String
            let channelId = channelDetails[index].valueForKey("channel_detail_id")
            if channelName == "Archive"
            {
                mediaSharedCount = (channelDetails[index].valueForKey("total_no_media_shared")?.stringValue)!
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
        
        if mediaSharedCount == "0"
        {
            ErrorManager.sharedInstance.emptyMedia()
            removeOverlay()
            dataSource.removeAll()
            imageDataSource.removeAll()
            fullScrenImageView.image = UIImage()
            fullScrenImageView.alpha = 1.0
            photoThumpCollectionView.reloadData()
        }
        else
        {
            imageUploadManger.getChannelMediaDetails(channelId.stringValue , userName: userId, accessToken: accessToken, limit: mediaSharedCount, offset: "0", success: { (response) -> () in
                self.authenticationSuccessHandlerForFetchMedia(response)
            }) { (error, message) -> () in
                self.authenticationFailureHandlerForFetchMedia(error, code: message)
            }
        }
    }
    func downloadFirstEntry()
    {
        var dummyImagesDataSource :[[String:AnyObject]]  = [[String:AnyObject]]()
        
        if( self.imageDataSource.count > 0)
        {
            let mediaDict: NSMutableDictionary = NSMutableDictionary()
            dummyImagesDataSource = self.dataSource
            self.dataSource .removeAll()
            let fullImageDownloadUrl = convertStringtoURL(self.imageDataSource[0][fullSignedUrlKey]  as! String)
            let downloadThumbURL =  self.convertStringtoURL(self.imageDataSource[0][thumbSignedUrlKey] as! String)
            let mediaType = imageDataSource[0][mediaTypeKey] as! String
            if mediaType == "image"
            {
                let mediaIdDownload : String = imageDataSource[0][mediaIdKey]!.stringValue
                let cacheMedia  =   checkCacheMedia(mediaIdDownload)
                
                if(cacheMedia.count > 0)
                {
                    mediaDict.setValue(cacheMedia[0][thumbImageKey], forKey: "ThumbImage")
                    mediaDict.setValue(cacheMedia[0][fullImageKey], forKey: "FullImage")
                    if dummyImagesDataSourceDatabase.count > 0
                    {
                        self.fullScrenImageView.image = dummyImagesDataSourceDatabase[0][self.fullImageKey] as! UIImage
                        self.fullScreenZoomView.image = dummyImagesDataSourceDatabase[0][self.fullImageKey] as!  UIImage
                    }
                    else
                    {
                        playIconInFullView.hidden = true
                        self.fullScrenImageView.image = mediaDict["FullImage"] as? UIImage
                        self.fullScreenZoomView.image = mediaDict["FullImage"] as? UIImage
                        
                    }
                    
                    dummyImagesDataSource.append([thumbSignedUrlKey:imageDataSource[0][thumbSignedUrlKey]!,fullSignedUrlKey: imageDataSource[0][fullSignedUrlKey]! ,mediaIdKey:imageDataSource[0][mediaIdKey]!,mediaTypeKey:imageDataSource[0][mediaTypeKey]!,timeStampKey :imageDataSource[0][timeStampKey]!,self.thumbImageKey:mediaDict["ThumbImage"] as! UIImage,self.fullImageKey:mediaDict["FullImage"] as! UIImage])
                    self.mediaDictionary.setValue(mediaDict, forKey: "0")
                    self.dataSource = dummyImagesDataSource
                    self.photoThumpCollectionView.reloadData()
                    self.removeOverlay()
                }
                else
                {
                    let mediaIdDownload : String = imageDataSource[0][mediaIdKey]!.stringValue
                    
                    let path = self.mediaCacheManager.getDocumentsURL().URLByAppendingPathComponent(mediaIdDownload)
                    downloadMedia(fullImageDownloadUrl, key:  "FullImage") { (result) -> Void in
                        
                        self.mediaCacheManager.saveImage(result, path: String(String(path)+"full"))
                        
                        mediaDict.setValue(result, forKey: "FullImage")
                        
                        
                        self.downloadMedia(downloadThumbURL, key: "ThumbImage", completion: { (result) -> Void in
                            self.mediaCacheManager.saveImage(result, path: String(String(path)+"thumb"))
                            mediaDict.setValue(result, forKey: "ThumbImage")
                            if self.dummyImagesDataSourceDatabase.count > 0
                            {
                                self.fullScrenImageView.image = self.dummyImagesDataSourceDatabase[0][self.fullImageKey] as! UIImage
                                self.fullScreenZoomView.image = self.dummyImagesDataSourceDatabase[0][self.fullImageKey] as! UIImage
                            }
                            else
                            {
                                self.playIconInFullView.hidden = true
                                self.fullScrenImageView.image = mediaDict["FullImage"] as? UIImage
                                self.fullScreenZoomView.image = mediaDict["FullImage"] as? UIImage
                            }
                            let image: UIImage? = mediaDict["ThumbImage"] as? UIImage
                            
                            if(image == nil)
                            {
                                dummyImagesDataSource.append([self.thumbSignedUrlKey:self.imageDataSource[0][self.thumbSignedUrlKey]!,self.fullSignedUrlKey: self.imageDataSource[0][self.fullSignedUrlKey]! ,self.mediaIdKey:self.imageDataSource[0][self.mediaIdKey]!,self.mediaTypeKey:self.imageDataSource[0][self.mediaTypeKey]!,self.timeStampKey :self.imageDataSource[0][self.timeStampKey]!,self.thumbImageKey:mediaDict["ThumbImage"] as! UIImage,self.fullImageKey:mediaDict["ThumbImage"] as! UIImage])
                            }
                            else
                            {
                                dummyImagesDataSource.append([self.thumbSignedUrlKey:self.imageDataSource[0][self.thumbSignedUrlKey]!,self.fullSignedUrlKey: self.imageDataSource[0][self.fullSignedUrlKey]! ,self.mediaIdKey:self.imageDataSource[0][self.mediaIdKey]!,self.mediaTypeKey:self.imageDataSource[0][self.mediaTypeKey]!,self.timeStampKey :self.imageDataSource[0][self.timeStampKey]!,self.thumbImageKey:mediaDict["ThumbImage"] as! UIImage,self.fullImageKey:mediaDict["FullImage"] as! UIImage])
                            }
                            self.dataSource = dummyImagesDataSource
                            self.photoThumpCollectionView.reloadData()
                            self.mediaDictionary.setValue(mediaDict, forKey: "0")
                            self.removeOverlay()
                        })
                    }
                }
            }
            else
            {
                let cacheMedia  =   checkCacheMedia(String(imageDataSource[0][mediaIdKey]))
                if(cacheMedia.count > 0)
                {
                    dummyImagesDataSource.append([self.thumbSignedUrlKey:self.imageDataSource[0][self.thumbSignedUrlKey]!,self.fullSignedUrlKey: self.imageDataSource[0][self.fullSignedUrlKey]! ,self.mediaIdKey:self.imageDataSource[0][self.mediaIdKey]!,self.mediaTypeKey:self.imageDataSource[0][self.mediaTypeKey]!,self.timeStampKey :self.imageDataSource[0][self.timeStampKey]!,self.thumbImageKey:cacheMedia[0]["ThumbImage"]!,self.fullImageKey:cacheMedia[0]["ThumbImage"]!])
                    
                    mediaDict.setValue(cacheMedia[0][thumbImageKey], forKey: "thumbImage")
                    mediaDict.setValue(cacheMedia[0][fullImageKey], forKey: "FullImage")
                    self.playIconInFullView.hidden = false
                    
                    self.fullScrenImageView.image = mediaDict["FullImage"] as? UIImage
                    self.fullScreenZoomView.image = mediaDict["FullImage"] as? UIImage
                    self.dataSource = dummyImagesDataSource
                    self.photoThumpCollectionView.reloadData()
                    
                    self.mediaDictionary.setValue(mediaDict, forKey: "0")
                    self.removeOverlay()
                    
                }
                else
                {
                    self.downloadMedia(downloadThumbURL, key: "ThumbImage", completion: { (result) -> Void in
                        mediaDict.setValue(result, forKey: "ThumbImage")
                        
                        if self.dummyImagesDataSourceDatabase.count > 0
                        {
                            self.fullScrenImageView.image = (self.dummyImagesDataSourceDatabase[0][self.fullImageKey] as! UIImage)
                            self.fullScreenZoomView.image = (self.dummyImagesDataSourceDatabase[0][self.fullImageKey] as! UIImage)
                        }
                        else
                        {
                            self.fullScrenImageView.image = mediaDict["ThumbImage"] as? UIImage
                            self.fullScreenZoomView.image = mediaDict["ThumbImage"] as? UIImage
                            self.playIconInFullView.hidden = false
                            
                        }
                        if(dummyImagesDataSource.count>0)
                        {
                            var flag : Bool = false
                            for(var i = 0 ;i < dummyImagesDataSource.count ; i++)
                            {
                                
                                if dummyImagesDataSource[i][self.mediaIdKey]?.stringValue == self.imageDataSource[0][self.mediaIdKey]?.stringValue
                                {
                                    flag = true
                                    
                                }
                            }
                            if(!flag)
                            {
                                dummyImagesDataSource.append([self.thumbSignedUrlKey:self.imageDataSource[0][self.thumbSignedUrlKey]!,self.fullSignedUrlKey: self.imageDataSource[0][self.fullSignedUrlKey]! ,self.mediaIdKey:self.imageDataSource[0][self.mediaIdKey]!,self.mediaTypeKey:self.imageDataSource[0][self.mediaTypeKey]!,self.timeStampKey :self.imageDataSource[0][self.timeStampKey]!,self.thumbImageKey:mediaDict["ThumbImage"]!,self.fullImageKey:mediaDict["ThumbImage"]!])
                                
                            }
                            
                        }
                        else{
                            dummyImagesDataSource.append([self.thumbSignedUrlKey:self.imageDataSource[0][self.thumbSignedUrlKey]!,self.fullSignedUrlKey: self.imageDataSource[0][self.fullSignedUrlKey]! ,self.mediaIdKey:self.imageDataSource[0][self.mediaIdKey]!,self.mediaTypeKey:self.imageDataSource[0][self.mediaTypeKey]!,self.timeStampKey :self.imageDataSource[0][self.timeStampKey]!,self.thumbImageKey:mediaDict["ThumbImage"]!,self.fullImageKey:mediaDict["ThumbImage"]!])
                            
                            
                        }
                        
                        self.dataSource = dummyImagesDataSource
                        self.photoThumpCollectionView.reloadData()
                        self.mediaDictionary.setValue(mediaDict, forKey: "0")
                        self.removeOverlay()
                    })
                }
            }
            downloadCloudData(15, scrolled: false)
            setLabelValue(0)
        }
        else
        {
            self.dataSource = dummyImagesDataSource
            self.photoThumpCollectionView.reloadData()
        }
    }
    
    func checkCacheMedia(mediaId :String) -> [[String : UIImage]]
    {
        cacheDatabase.removeAll()
        let path = mediaCacheManager.getDocumentsURL().URLByAppendingPathComponent(mediaId)
        if(mediaCacheManager.fileExist(String(String(path)+"thumb")) && mediaCacheManager.fileExist(String(String(path)+"full")))
        {
            let thumbImageCache = mediaCacheManager.loadImageFromPath(String(String(String(path)+"thumb")))
            let fullImageCache = mediaCacheManager.loadImageFromPath(String(String(String(path)+"full")))
            cacheDatabase.append([thumbImageKey:thumbImageCache!,fullImageKey:fullImageCache!])
            return cacheDatabase
        }
        else
        {
            return cacheDatabase
        }
    }
    
    func checkCacheThumb(mediaId :String) -> [[String : UIImage]]
    {
        cacheDatabase.removeAll()
        let path = mediaCacheManager.getDocumentsURL().URLByAppendingPathComponent(mediaId)
        if(mediaCacheManager.fileExist(String(String(String(path)+"thumb"))))
        {
            let thumbImageCache = mediaCacheManager.loadImageFromPath(String(String(String(path)+"thumb")))
            cacheDatabase.append([thumbImageKey:thumbImageCache! as UIImage,fullImageKey:UIImage()])
        }
        return cacheDatabase
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
        var dummyImagesDataSource :[[String:AnyObject]]  = [[String:AnyObject]]()
        dummyImagesDataSource=self.dataSource
        if(imageDataSource.count <  (currentLimit +  limitMedia))
        {
            
            limitMediaCount = currentLimit
            if currentLimit == 0
            {
                limitMediaCount = 1
            }
            currentLimit = currentLimit + (imageDataSource.count - currentLimit)
            
        }
        else if (imageDataSource.count > (currentLimit +  limitMedia))
        {
            limitMediaCount = currentLimit
            if currentLimit == 0
            {
                limitMediaCount = 1
            }
            currentLimit = currentLimit + 15
            
        }
        else if(imageDataSource.count == (currentLimit +  limitMedia))
        {
            currentLimit = imageDataSource.count
        }
        else if(currentLimit == imageDataSource.count)
        {
            return
            
        }
        
        if(!scrolled)
        {
            for var i = limitMediaCount; i <= currentLimit ; i += 1
            {
                if(imageDataSource.count-1 >= i)
                {
                    let downloadURL =  self.convertStringtoURL(imageDataSource[i][thumbSignedUrlKey] as! String)
                    let mediaIdDownload: String = imageDataSource[i][mediaIdKey]!.stringValue
                    let cacheThumb = checkCacheThumb(mediaIdDownload)
                    if(cacheThumb.count>0)
                    {
                        for j in 0  ..< cacheThumb.count
                        {
                            var flag : Bool = false
                            for(var k = 0 ;k < dummyImagesDataSource.count ;k++)
                            {
                                
                                if dummyImagesDataSource[k][self.mediaIdKey]?.stringValue == self.imageDataSource[i][self.mediaIdKey]?.stringValue
                                {
                                    flag = true
                                    
                                }
                            }
                            if(!flag)
                            {
                                dummyImagesDataSource.append([self.thumbSignedUrlKey:self.imageDataSource[i][self.thumbSignedUrlKey]!,self.fullSignedUrlKey: self.imageDataSource[i][self.fullSignedUrlKey]! ,self.mediaIdKey:self.imageDataSource[i][self.mediaIdKey]!,self.mediaTypeKey:self.imageDataSource[i][self.mediaTypeKey]!,self.timeStampKey :self.imageDataSource[i][self.timeStampKey]!,self.thumbImageKey:cacheThumb[j][thumbImageKey]!,self.fullImageKey:cacheThumb[j][thumbImageKey]!])
                                
                            }
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                self.dataSource = dummyImagesDataSource
                                self.photoThumpCollectionView.reloadData()
                            })
                        }
                    }
                    else
                    {
                        downloadMedia(downloadURL, key:  "ThumbImage", completion: { (result) -> Void in
                            let mediaIdDownload : String = self.imageDataSource[i][self.mediaIdKey]!.stringValue
                            let path = self.mediaCacheManager.getDocumentsURL().URLByAppendingPathComponent(mediaIdDownload)
                            self.mediaCacheManager.saveImage(result, path: String(String(path)+"thumb"))
                            dummyImagesDataSource.append([self.thumbSignedUrlKey:self.imageDataSource[i][self.thumbSignedUrlKey]!,self.fullSignedUrlKey: self.imageDataSource[i][self.fullSignedUrlKey]! ,self.mediaIdKey:self.imageDataSource[i][self.mediaIdKey]!,self.mediaTypeKey:self.imageDataSource[i][self.mediaTypeKey]!,self.timeStampKey :self.imageDataSource[i][self.timeStampKey]!,self.thumbImageKey:result,self.fullImageKey:result])
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                self.dataSource = dummyImagesDataSource
                                self.photoThumpCollectionView.reloadData()
                            })
                        })
                    }
                }
            }
        }
        else
        {
            for var i = limitMediaCount+1; i <= currentLimit ; i += 1 {
                if(i >= imageDataSource.count - 1)
                {
                    return
                }
                let downloadURL =  self.convertStringtoURL(self.imageDataSource[i][thumbSignedUrlKey] as! String)
                
                downloadMedia(downloadURL, key:  "ThumbImage", completion: { (result) -> Void in
                    
                    dummyImagesDataSource.append([self.thumbSignedUrlKey:self.imageDataSource[i][self.thumbSignedUrlKey]!,self.fullSignedUrlKey: self.imageDataSource[i][self.fullSignedUrlKey]! ,self.mediaIdKey:self.imageDataSource[i][self.mediaIdKey]!,self.mediaTypeKey:self.imageDataSource[i][self.mediaTypeKey]!,self.timeStampKey :self.imageDataSource[i][self.timeStampKey]!,self.thumbImageKey:result,self.fullImageKey:result])
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.dataSource = dummyImagesDataSource
                        self.photoThumpCollectionView.reloadData()
                    })
                })
            }
            
        }
        isLimitReached = true
        self.fullScrenImageView.alpha = 1.0
        checkData()
        if dataSource.count>0
        {
            self.fullScrenImageView.image = (self.dataSource[0][self.fullImageKey] as! UIImage)
            self.fullScreenZoomView.image = (self.dataSource[0][self.fullImageKey] as! UIImage)
        }
    }
    
    func downloadMedia(downloadURL : NSURL ,key : String , completion: (result: UIImage) -> Void)
    {
        var mediaImage : UIImage = UIImage()
        let data = NSData(contentsOfURL: downloadURL)
        if let imageData = data as NSData? {
            if let mediaImage1 = UIImage(data: imageData)
            {
                mediaImage = UIImage(data: imageData)!
            }
            completion(result: UIImage(data: imageData)!)
        }
        else
        {
            completion(result:UIImage(named: "thumb12")!)
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
        if monthsFrom(date,todate:todate)  > 0 {
            return "\(monthsFrom(date,todate:todate))M"
        }
        if weeksFrom(date,todate:todate)   > 0 {
            return "\(weeksFrom(date,todate:todate))w"
        }
        if daysFrom(date,todate:todate)    > 0 {

            return "\(daysFrom(date,todate:todate))d"
        }
        if hoursFrom(date,todate:todate)   > 0 {
            return "TODAY"
        }
        if minutesFrom(date,todate:todate) > 0 {
            return "TODAY"
        }
        if secondsFrom(date,todate:todate) > 0 {
            return "TODAY"
        }
        return ""
    }
    
}



