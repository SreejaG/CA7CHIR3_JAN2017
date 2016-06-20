

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
    var moviePlayer : MPMoviePlayerController!
    var mediaSharedCount : String = "0"
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
    var channelIdfromLocal : NSNumber = NSNumber()
    var selectedItem : Int = Int()
    
    @IBOutlet var TopView: UIView!
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
        showOverlay()
        initialise()
        getSignedURL()
        PhotoViewerInstance.controller = self
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
        
        if(downloadTask?.state == .Running)
        {
            downloadTask?.cancel()
        }
    }
    
    @IBAction func deleteButtonAction(sender: AnyObject) {
      
        if(downloadTask?.state == .Running)
        {
            downloadTask?.cancel()
        }
        progressViewDownload?.hidden = true
        progressLabelDownload?.hidden = true
        let alert = UIAlertController(title: "", message: "Are you sure you want to permanently delete this picture from all your channels?", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: {(
            
            action:UIAlertAction!) in
            
            self.mediaSelected.removeAllObjects()
            
            if self.mediaIdSelected == 0
            {
                self.mediaIdSelected = self.dataSource[0][self.mediaIdKey] as! Int
            }
            self.mediaSelected.addObject(self.mediaIdSelected)
            
            if(self.mediaSelected.count > 0)
            {
                var channelIds : [Int] = [Int]()
                
                channelIds.append(self.channelDict["Archive"] as! Int)
                
                let defaults = NSUserDefaults .standardUserDefaults()
                let userId = defaults.valueForKey(userLoginIdKey) as! String
                let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
                self.showOverlay()
                self.imageUploadManger.deleteMediasByChannel(userId, accessToken: accessToken, mediaIds: self.mediaSelected, channelId: channelIds, success: { (response) -> () in
                    self.authenticationSuccessHandlerDelete(response)
                    }, failure: { (error, message) -> () in
                        self.authenticationFailureHandlerDelete(error, code: message)
                })
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler: {
            (action:UIAlertAction!) in print("you have pressed the Cancel button")
                self.fullScrenImageView.alpha = 1.0
             //   self.playIconInFullView.hidden = false
        }))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func  loadInitialViewController(code: String){
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            
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
            self.presentViewController(channelItemListVC, animated: false) { () -> Void in
                ErrorManager.sharedInstance.mapErorMessageToErrorCode(code)
            }
        })
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
                switch(sdifferentString)
                {
                case "TODAY" :
                    dateForDisplay = "   TODAY"
                    break;
                case "1d" : dateForDisplay = "  YESTERDAY"
                break;
                default :
                    let dateFormatterDisplay = NSDateFormatter()
                    dateFormatterDisplay.dateFormat = "MMM d, yyyy"
                    let dateString = dateFormatterDisplay.stringFromDate(fromdate!)
                    dateForDisplay = "  \(dateString)"
                    break;
                }
            }
            else{
                dateForDisplay = "   TODAY"
            }
            
            mediaTimeLabel.text = dateForDisplay
        }
    }
    
    func authenticationSuccessHandlerDelete(response:AnyObject?)
    {
        removeOverlay()
        self.fullScrenImageView.alpha = 1.0
        if let json = response as? [String: AnyObject]
        {
            mediaIdSelected = 0
            mediaSelected.removeAllObjects()
            print("selectedItem = \(selectedItem)")
            imageDataSource.removeAtIndex(selectedItem)
            dataSource.removeAtIndex(selectedItem)
            if(selectedItem - 1 <= 0){
                selectedItem = 0
            }
            else{
                selectedItem = selectedItem - 1
            }
          
            let dict = self.dataSource[selectedItem]
            downloadFullImageWhenTapThumb(dict, indexpaths: selectedItem)
            photoThumpCollectionView.reloadData()
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
           
            if((code == "USER004") || (code == "USER005") || (code == "USER006")){
                loadInitialViewController(code)
            }
            else{
                 ErrorManager.sharedInstance.mapErorMessageToErrorCode(code)
            }
        }
        else{
            ErrorManager.sharedInstance.inValidResponseError()
        }
    }
    func  uploadProgress ( progressDictionary :  [[String:AnyObject]])
    {
        progressDict = progressDictionary
        var count: Int = Int()
        count = 0
        for(var  i = 0 ; i < progressDict.count ; i++)
        {
            if(progressDict[i]["progress"] as! Float == 1.0 || progressDict[i]["progress"] as! Float == 1)
            {
                count = count+1
            }
        }
        if(count == progressDictionary.count)
        {
            progressDict.removeAll()
            NSUserDefaults.standardUserDefaults().setValue(nil, forKey: "ProgressDict")
            NSUserDefaults.standardUserDefaults().setValue(nil, forKey: "uploaObjectDict")
            self.photoThumpCollectionView.reloadData();
            
        }
        self.photoThumpCollectionView.reloadData();
    }
    func downloadFullScreenMedia()
    {
        if(dataSource.count>0)
        {
            var imageForMedia : UIImage = UIImage()
            let id = String(dataSource[0][mediaIdKey]!)
            let mediaIdForFilePath = "\(id))full"
            let parentPath = FileManagerViewController.sharedInstance.getParentDirectoryPath()
            let savingPath = "\(parentPath)/\(mediaIdForFilePath)"
            let fileExistFlag = FileManagerViewController.sharedInstance.fileExist(savingPath)
            if fileExistFlag == true{
                let mediaImageFromFile = FileManagerViewController.sharedInstance.getImageFromFilePath(savingPath)
                imageForMedia = mediaImageFromFile!
            }
            else{
                let mediaUrl = dataSource[0][fullSignedUrlKey] as! String
                if(mediaUrl != ""){
                    let url: NSURL = convertStringtoURL(mediaUrl)
                    downloadMedia(url, key: "ThumbImage", completion: { (result) -> Void in
                      
                        if(result != UIImage()){
                            let imageDataFromresult = UIImageJPEGRepresentation(result, 0.5)
                            let imageDataFromresultAsNsdata = (imageDataFromresult as NSData?)!
                            let imageDataFromDefault = UIImageJPEGRepresentation(UIImage(named: "thumb12")!, 0.5)
                            let imageDataFromDefaultAsNsdata = (imageDataFromDefault as NSData?)!
                            if(imageDataFromresultAsNsdata.isEqual(imageDataFromDefaultAsNsdata)){
                                print("not same")
                            }
                            else{
                                FileManagerViewController.sharedInstance.saveImageToFilePath(mediaIdForFilePath, mediaImage: result)
                            }
                            imageForMedia = result
                        }
                        else{
                            imageForMedia = UIImage(named: "thumb12")!
                        }
                    })
                }
            }
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.fullScrenImageView.image = imageForMedia
                self.fullScreenZoomView.image = imageForMedia
            })
            
        }
        
    }
    func getSignedURL()
    {
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
        self.view .addSubview(self.loadingOverlay!)
    }
    
    func removeOverlay(){
        self.loadingOverlay?.removeFromSuperview()
    }
    
    func initialise()
    {
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
        mediaIdSelected = 0
    }
    
    func enlargeImageView(Recognizer:UITapGestureRecognizer){
        if(dataSource.count > 0){
            if dataSource[selectedItem][mediaTypeKey] != nil
            {
                let mediaType = dataSource[selectedItem][mediaTypeKey] as! String
                
                if mediaType == "video"
                {
                    playIconInFullView.hidden = true
                    downloadVideo(selectedItem)
                }
                else
                {
                    fullScreenZoomView.hidden = false
                    fullScrenImageView.alpha = 0.0
                    TopView.hidden = true
                    BottomView.hidden = true
                    photoThumpCollectionView.hidden = true
                    playIconInFullView.hidden = true
                }
            }
        }
    }
    
    func downloadVideo(index : Int)
    {
        videoDownloadIntex = index
        let videoDownloadUrl = convertStringtoURL(self.dataSource[index][fullSignedUrlKey] as! String)
        
        let mediaIdForFilePath = "\(dataSource[index][mediaIdKey]!)"
        let parentPath = FileManagerViewController.sharedInstance.getParentDirectoryPath()
        let savingPath = "\(parentPath)/\(mediaIdForFilePath)video.mov"
        
        let fileExistFlag = FileManagerViewController.sharedInstance.fileExist(savingPath)
        if fileExistFlag == true
        {
            let url = NSURL(fileURLWithPath: savingPath)
            self.moviePlayer = nil
            self.moviePlayer = MPMoviePlayerController.init(contentURL: url)
            
            if let player = self.moviePlayer
            {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(PhotoViewerViewController.playerDidFinish(_:)), name: MPMoviePlayerPlaybackDidFinishNotification, object: self.moviePlayer)
                    self.view.userInteractionEnabled = false
                    player.view .removeFromSuperview()
                    player.shouldAutoplay = true
                    player.prepareToPlay()
                    player.view.frame = CGRect(x: self.fullScrenImageView.frame.origin.x, y: self.fullScrenImageView.frame.origin.y, width: self.fullScrenImageView.frame.size.width, height: self.fullScrenImageView.frame.size.height)
                    player.view.sizeToFit()
                    player.scalingMode = MPMovieScalingMode.Fill
                    player.controlStyle = MPMovieControlStyle.None
                    player.movieSourceType = MPMovieSourceType.File
                    player.repeatMode = MPMovieRepeatMode.None
                    self.view.addSubview(player.view)
                    player.play()
                })
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
            let mediaIdForFilePath = "\(dataSource[videoDownloadIntex][mediaIdKey]!)"
            let parentPath = FileManagerViewController.sharedInstance.getParentDirectoryPath().absoluteString
            let savingPath = "\(parentPath)/\(mediaIdForFilePath)video.mov"
            let url = NSURL(fileURLWithPath: savingPath)
            let writeFlag = imageData.writeToURL(url, atomically: true)
            if(writeFlag){
                NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(PhotoViewerViewController.playerDidFinish(_:)), name: MPMoviePlayerPlaybackDidFinishNotification, object: self.moviePlayer)
                videoDownloadIntex = 0
                
                self.moviePlayer = MPMoviePlayerController.init(contentURL: url)
                if let player = self.moviePlayer {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        
                        self.view.userInteractionEnabled = false
                        player.view.frame = CGRect(x: self.fullScrenImageView.frame.origin.x, y: self.fullScrenImageView.frame.origin.y, width: self.fullScrenImageView.frame.size.width, height: self.fullScrenImageView.frame.size.height)
                        player.view.sizeToFit()
                        player.scalingMode = MPMovieScalingMode.Fill
                        player.controlStyle = MPMovieControlStyle.None
                        player.movieSourceType = MPMovieSourceType.File
                        player.repeatMode = MPMovieRepeatMode.None
                        self.view.addSubview(player.view)
                        player.prepareToPlay()
                    })
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
    func shrinkImageView(Recognizer:UITapGestureRecognizer)
    {
        fullScreenZoomView.hidden = true
        fullScrenImageView.alpha = 1.0
        TopView.hidden = false
        BottomView.hidden = false
        photoThumpCollectionView.hidden = false
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
            addChannelVC.selectedChannelId = channelDict["Archive"]?.stringValue
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
            update()
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
            var dummyImages :[[String:AnyObject]] = [[String:AnyObject]]()
            dummyImages = dataSource
            dataSource.removeAll()
            for(var i = uploadMediaDict.count - 1 ;i >= 0 ; i--)
            {
                self.dataSource.append(uploadMediaDict[i])
            }
            for element in dummyImages
            {
                var flag : Bool = false
                if(dataSource.count > 0){
                for(var i = 0 ;i < dataSource.count ; i++)
                {
                    if dataSource[i][mediaIdKey]?.stringValue == element[mediaIdKey]?.stringValue
                    {
                        flag = true
                    }
                }
                }
                if(!flag)
                {
                    self.dataSource.append(element)
                }
            }
            let dict = self.dataSource[0]
            downloadFullImageWhenTapThumb(dict, indexpaths: 0)
            self.photoThumpCollectionView.reloadData()
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
        let cameraViewStoryboard = UIStoryboard(name:"IPhoneCameraView" , bundle: nil)
        let iPhoneCameraViewController = cameraViewStoryboard.instantiateViewControllerWithIdentifier("IPhoneCameraViewController") as! IPhoneCameraViewController
        self.navigationController?.navigationBarHidden = true
        self.navigationController?.pushViewController(iPhoneCameraViewController, animated: false)
    }
    
    func downloadFullImageWhenTapThumb(imageDict: [String:AnyObject], indexpaths : Int) {
        var imageForMedia : UIImage = UIImage()
        if let fullImage = imageDict[fullImageKey]
        {
            if dataSource[indexpaths][mediaTypeKey] as! String == "video"
            {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.photoThumpCollectionView.alpha = 1.0
                    self.removeOverlay()
                    self.playIconInFullView.hidden = false;
                    self.fullScrenImageView.image = (fullImage as! UIImage)
                    self.fullScreenZoomView.image = (fullImage as! UIImage)

                })
            }
            else
            {
                if(indexpaths < uploadCount)
                {
                    imageForMedia = dataSource[indexpaths][fullImageKey] as! UIImage
                }
                else{
                    let mediaIdForFilePath = "\(dataSource[indexpaths][mediaIdKey]?.stringValue)full"
                    let parentPath = FileManagerViewController.sharedInstance.getParentDirectoryPath()
                    let savingPath = "\(parentPath)/\(mediaIdForFilePath)"
                    let fileExistFlag = FileManagerViewController.sharedInstance.fileExist(savingPath)
                    if fileExistFlag == true{
                        let mediaImageFromFile = FileManagerViewController.sharedInstance.getImageFromFilePath(savingPath)
                        imageForMedia = mediaImageFromFile!
                    }
                    else{
                        let mediaUrl = dataSource[indexpaths][fullSignedUrlKey] as! String
                        if(mediaUrl != ""){
                            let url: NSURL = convertStringtoURL(mediaUrl)
                            downloadMedia(url, key: "ThumbImage", completion: { (result) -> Void in
                                if(result != UIImage()){
                                    let imageDataFromresult = UIImageJPEGRepresentation(result, 0.5)
                                    let imageDataFromresultAsNsdata = (imageDataFromresult as NSData?)!
                                    let imageDataFromDefault = UIImageJPEGRepresentation(UIImage(named: "thumb12")!, 0.5)
                                    let imageDataFromDefaultAsNsdata = (imageDataFromDefault as NSData?)!
                                    if(imageDataFromresultAsNsdata.isEqual(imageDataFromDefaultAsNsdata)){
                                        print("not same")
                                    }
                                    else{
                                        FileManagerViewController.sharedInstance.saveImageToFilePath(mediaIdForFilePath, mediaImage: result)
                                    }
                                    imageForMedia = result
                                }
                                else{
                                    imageForMedia = UIImage(named: "thumb12")!
                                }
                            })
                        }
                    }
                }
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.photoThumpCollectionView.alpha = 1.0
                self.removeOverlay()
                self.fullScrenImageView.image = imageForMedia as UIImage
                self.fullScreenZoomView.image = imageForMedia as UIImage
                self.playIconInFullView.hidden = true;
                })
            }
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
        if dataSource.count > indexPath.row
        {
            if(indexPath.row == selectedItem){
                cell.layer.borderWidth = 2;
                cell.layer.borderColor = UIColor(red: 44.0/255.0, green: 214.0/255.0, blue: 229.0/255.0, alpha: 0.7).CGColor
            }
            else{
                cell.layer.borderWidth = 0;
                cell.layer.borderColor = UIColor.clearColor().CGColor;
            }
            var dict = dataSource[indexPath.row]
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
                                cell.progressView.progress = progressDict[i]["progress"]!.floatValue
                            }
                            if mediaId == String(dataSource[indexPath.row][mediaIdKey]!)
                            {
                                cell.progressView.progress = progressDict[i]["progress"]!.floatValue
                              
                                if(progressDict[i]["progress"]!.floatValue == 1.0 || progressDict[i]["progress"]!.floatValue == 1)
                                {
                                    cell.progressView.hidden = true
                                    cell.cloudIcon.hidden = false
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
        print(indexPath.row)
        selectedItem = indexPath.row
        self.photoThumpCollectionView.reloadData()
        
        if dataSource.count > indexPath.row
        {
            if(downloadTask?.state == .Running)
            {
                downloadTask?.cancel()
            }
            progressViewDownload?.hidden = true
            progressLabelDownload?.hidden = true
            setLabelValue(indexPath.row)
        }
        
        let qualityOfServiceClass = QOS_CLASS_BACKGROUND
        let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
        photoThumpCollectionView.alpha = 0.4
        self.fullScrenImageView.alpha = 1.0
        self.showOverlay()
        dispatch_async(backgroundQueue, {
            if self.dataSource.count > indexPath.row
            {
                self.mediaIdSelected = self.dataSource[indexPath.row][self.mediaIdKey] as! Int
                let dict = self.dataSource[indexPath.row]
                self.downloadFullImageWhenTapThumb(dict, indexpaths: indexPath.row)
            }
        })
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
          
            if((code == "USER004") || (code == "USER005") || (code == "USER006")){
                loadInitialViewController(code)
            }
            else{
                  ErrorManager.sharedInstance.mapErorMessageToErrorCode(code)
            }
        }
        else{
            ErrorManager.sharedInstance.inValidResponseError()
        }
        photoThumpCollectionView.reloadData()
    }
    func authenticationSuccessHandlerForFetchMedia(response:AnyObject?)
    {
        
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
        self.removeOverlay()
        if(imageDataSource.count > 0){
            let qualityOfServiceClass = QOS_CLASS_BACKGROUND
            let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
            dispatch_async(backgroundQueue, {
                self.downloadMediaFromGCS()
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.photoThumpCollectionView.reloadData()
                    self.addToButton.enabled = true
                    self.deletButton.enabled = true
                    self.BottomView.alpha = 1.0
                });
            })
        }
    }
    func downloadMediaFromGCS(){
        self.removeOverlay()
        for(var i = 0; i < imageDataSource.count; i++)
        {
            var imageForMedia : UIImage = UIImage()
            
            let id = String(imageDataSource[i][mediaIdKey]!)
            var flag : Bool = false
            for(var j = 0 ;j < self.dataSource.count ;j++)
            {
                
                if dataSource[j][self.mediaIdKey]?.stringValue == self.imageDataSource[i][self.mediaIdKey]?.stringValue
                {
                    flag = true
                    
                }
            }
            if(!flag)
            {
                let mediaIdForFilePath = "\(id))thumb"
                let parentPath = FileManagerViewController.sharedInstance.getParentDirectoryPath()
                let savingPath = "\(parentPath)/\(mediaIdForFilePath)"
                let fileExistFlag = FileManagerViewController.sharedInstance.fileExist(savingPath)
                if fileExistFlag == true{
                    let mediaImageFromFile = FileManagerViewController.sharedInstance.getImageFromFilePath(savingPath)
                    imageForMedia = mediaImageFromFile!
                }
                else{
                    let mediaUrl = imageDataSource[i][thumbSignedUrlKey] as! String
                    if(mediaUrl != ""){
                        let url: NSURL = convertStringtoURL(mediaUrl)
                        downloadMedia(url, key: "ThumbImage", completion: { (result) -> Void in
                           
                            if(result != UIImage()){
                                let imageDataFromresult = UIImageJPEGRepresentation(result, 0.5)
                                let imageDataFromresultAsNsdata = (imageDataFromresult as NSData?)!
                                let imageDataFromDefault = UIImageJPEGRepresentation(UIImage(named: "thumb12")!, 0.5)
                                let imageDataFromDefaultAsNsdata = (imageDataFromDefault as NSData?)!
                                if(imageDataFromresultAsNsdata.isEqual(imageDataFromDefaultAsNsdata)){
                                    print("not same")
                                }
                                else{
                                     FileManagerViewController.sharedInstance.saveImageToFilePath(mediaIdForFilePath, mediaImage: result)
                                }
                                imageForMedia = result
                            }
                            else{
                                imageForMedia = UIImage(named: "thumb12")!
                            }
                        })
                    }
                }
                dataSource.append([self.thumbSignedUrlKey:self.imageDataSource[i][self.thumbSignedUrlKey]!,self.fullSignedUrlKey: self.imageDataSource[i][self.fullSignedUrlKey]! ,self.mediaIdKey:self.imageDataSource[i][self.mediaIdKey]!,self.mediaTypeKey:self.imageDataSource[i][self.mediaTypeKey]!,self.timeStampKey :self.imageDataSource[i][self.timeStampKey]!,self.thumbImageKey:imageForMedia,self.fullImageKey:imageForMedia])
                
            }
            if( i == 0 )
            {
                if(uploadMediaDict.count > 0){
                
                }
                else{
                    self.setLabelValue(0)
                    let dict = self.dataSource[0]
                    downloadFullImageWhenTapThumb(dict, indexpaths: 0)
                }
            }
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.photoThumpCollectionView.reloadData()
                self.photoThumpCollectionView.layoutIfNeeded()
            })
        }
        
    }
    func downloadFullScreenImageFromCloud(mediaId : String , mediaUrl : String )
    {
        var imageForMedia : UIImage = UIImage()
        let mediaIdForFilePath = "\(mediaId))full"
        let parentPath = FileManagerViewController.sharedInstance.getParentDirectoryPath()
        let savingPath = "\(parentPath)/\(mediaIdForFilePath)"
        let fileExistFlag = FileManagerViewController.sharedInstance.fileExist(savingPath)
        if fileExistFlag == true{
            let mediaImageFromFile = FileManagerViewController.sharedInstance.getImageFromFilePath(savingPath)
            imageForMedia = mediaImageFromFile!
        }
        else{
            if(mediaUrl != ""){
                let url: NSURL = convertStringtoURL(mediaUrl)
                downloadMedia(url, key: "ThumbImage", completion: { (result) -> Void in
                    
                    if(result != UIImage()){
                        let imageDataFromresult = UIImageJPEGRepresentation(result, 0.5)
                        let imageDataFromresultAsNsdata = (imageDataFromresult as NSData?)!
                        let imageDataFromDefault = UIImageJPEGRepresentation(UIImage(named: "thumb12")!, 0.5)
                        let imageDataFromDefaultAsNsdata = (imageDataFromDefault as NSData?)!
                        if(imageDataFromresultAsNsdata.isEqual(imageDataFromDefaultAsNsdata)){
                            print("not same")
                        }
                        else{
                            FileManagerViewController.sharedInstance.saveImageToFilePath(mediaIdForFilePath, mediaImage: result)
                        }
                        imageForMedia = result
                    }
                    else{
                        imageForMedia = UIImage(named: "thumb12")!
                    }
                })
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            
            self.fullScrenImageView.image = imageForMedia as UIImage
            self.fullScreenZoomView.image = imageForMedia as UIImage
            
        })
        
    }
    
    func authenticationFailureHandlerForFetchMedia(error: NSError?, code: String)
    {
        self.removeOverlay()
        print("message = \(code) andError = \(error?.localizedDescription) ")
        if !self.requestManager.validConnection() {
            ErrorManager.sharedInstance.noNetworkConnection()
        }
        else if code.isEmpty == false {
            if(self.dataSource.count == 0)
            {
                ErrorManager.sharedInstance.mapErorMessageToErrorCode(code)
            }
            else if((code == "USER004") || (code == "USER005") || (code == "USER006")){
                loadInitialViewController(code)
            }
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
          
            if((code == "USER004") || (code == "USER005") || (code == "USER006")){
                  loadInitialViewController(code)
            }
            else{
                ErrorManager.sharedInstance.mapErorMessageToErrorCode(code)
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
            
            if((code == "USER004") || (code == "USER005") || (code == "USER006")){
                loadInitialViewController(code)
            }
            else{
                ErrorManager.sharedInstance.mapErorMessageToErrorCode(code)
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
        update()
        if(mediaSharedCount != "0")
        {
            getMediaFromCloud()
        }
        else
        {
            if(dataSource.count == 0)
            {
                ErrorManager.sharedInstance.mapErorMessageToErrorCode("MEDIA003")
                self.removeOverlay()
            }
        }
    }
    
    func getMediaFromCloud()
    {
        let defaults = NSUserDefaults .standardUserDefaults()
        let userId = defaults.valueForKey(userLoginIdKey) as! String
        let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
        let channelId = channelDict["Archive"] as! NSNumber
        imageUploadManger.getChannelMediaDetails(channelId.stringValue , userName: userId, accessToken: accessToken, limit: mediaSharedCount, offset: "0", success: { (response) -> () in
            self.authenticationSuccessHandlerForFetchMedia(response)
        }) { (error, message) -> () in
            self.authenticationFailureHandlerForFetchMedia(error, code: message)
        }
    }
    func stringToURL( stringURl :String) -> NSURL
    {
        let url : NSString = stringURl
        let urlStr : NSString = url.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
        let searchURL : NSURL = NSURL(string: urlStr as String)!
        return searchURL
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



