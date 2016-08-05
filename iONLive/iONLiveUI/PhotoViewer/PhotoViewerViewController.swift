

import UIKit
import MediaPlayer
import Foundation

protocol progressviewDelegate
{
    func ProgresviewUpdate (value : Float)
}

class PhotoViewerViewController: UIViewController,UIGestureRecognizerDelegate,NSURLSessionDelegate, NSURLSessionTaskDelegate,NSURLSessionDataDelegate,NSURLSessionDownloadDelegate,UIScrollViewDelegate
{
    var delegate:progressviewDelegate?
    
    var lastContentOffset: CGPoint = CGPoint()
    
    @IBOutlet var TopView: UIView!
    @IBOutlet var BottomView: UIView!
    
    @IBOutlet var playIconInFullView: UIImageView!
    @IBOutlet weak var fullScrenImageView: UIImageView!
    @IBOutlet var fullScreenZoomView: UIImageView!
    
    @IBOutlet weak var fullScreenScrollView: UIScrollView!
    
    @IBOutlet weak var mediaTimeLabel: UILabel!
    
    @IBOutlet var progressView: UIProgressView!
    
    @IBOutlet weak var photoThumpCollectionView: UICollectionView!
    
    @IBOutlet var doneButton: UIButton!
    @IBOutlet var addToButton: UIButton!
    @IBOutlet var deletButton: UIButton!
    
    static let identifier = "PhotoViewerViewController"
    
    let mediaDetailIdKey = "media_detail_id"
    let thumbImageURLKey = "thumbImage_URL"
    let fullImageURLKey = "fullImage_URL"
    let thumbImageKey = "thumbImage"
    let notificationTypeKey = "notification_type"
    let createdTimeStampKey = "created_timeStamp"
    let mediaTypeKey = "media_type"
    let uploadProgressKey = "upload_progress"
    let channelMediaDetailIdKey = "channel_media_detail_id"
    
    let imageUploadManger = ImageUpload.sharedInstance
    let requestManager = RequestManager.sharedInstance
    let channelManager = ChannelManager.sharedInstance
    
    var moviePlayer : MPMoviePlayerController!
    let defaults = NSUserDefaults .standardUserDefaults()
    
    private var downloadTask: NSURLSessionDownloadTask?
    
    var progressViewDownload: UIProgressView?
    var progressLabelDownload: UILabel?
    
    var loadingOverlay: UIView?
    
    var addToDict : [[String:AnyObject]] = [[String:AnyObject]]()
    var mediaSelected: NSMutableArray = NSMutableArray()
    
    var willEnterFlag : NSInteger = NSInteger()
    var playHandleflag : NSInteger = NSInteger()
    var selectedItem : Int = Int()
    var archiveMediaCount : Int = Int()
    var mediaIdSelected : Int = 0
    var videoDownloadIntex : Int = 0
    var totalCount = 0
    
    var swipeFlag : Bool = false
    var downloadingFlag : Bool = false
    
    var dictMediaId : String = String()
    var userId : String = String()
    var accessToken: String = String()
    var deletedMediaId : String = String()
    
    var dictProgress : Float = Float()
    
    class var sharedInstance: PhotoViewerViewController {
        struct Singleton {
            static let instance = PhotoViewerViewController()
        }
        return Singleton.instance
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.photoThumpCollectionView.alwaysBounceHorizontal = true
        
        progressLabelDownload = UILabel()
        
        progressViewDownload?.hidden = true
        progressLabelDownload?.hidden = true
        
        self.fullScrenImageView.image = UIImage()
        self.fullScreenZoomView.image = UIImage()
        
        playHandleflag = 0
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(PhotoViewerViewController.removeActivityIndicator(_:)), name: "removeActivityIndicatorMyMedia", object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(PhotoViewerViewController.uploadMediaProgress(_:)), name: "upload", object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(PhotoViewerViewController.setFullscreenImage(_:)), name: "setFullscreenImage", object: nil)
        
        showOverlay()
        
        initialise()
        
        if archiveMediaCount == 0{
            self.removeOverlay()
            ErrorManager.sharedInstance.emptyMedia()
        }
        else if GlobalDataRetriever.sharedInstance.globalDataSource.count > 0
        {
            
            let filteredData = GlobalDataRetriever.sharedInstance.globalDataSource.filter(thumbExists)
            totalCount = filteredData.count
            
            print(totalCount)
            if totalCount > 0
            {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    
                    print(GlobalDataRetriever.sharedInstance.globalDataSource)
                    print(GlobalDataRetriever.sharedInstance.globalDataSource[0][self.mediaDetailIdKey] as! String)
                    
                   
                    
                    self.addToButton.hidden = false
                    self.deletButton.hidden = false
                    self.photoThumpCollectionView.reloadData()
                })
                if GlobalDataRetriever.sharedInstance.globalDataSource.count > 0
                {
                    let dict = GlobalDataRetriever.sharedInstance.globalDataSource[0]
                    self.downloadFullImageWhenTapThumb(dict, indexpaths: 0,gestureIdentifier:0)
                }
               
            }
            else{
                var start = 0
                var end = 0
                if GlobalDataRetriever.sharedInstance.globalDataSource.count > 10
                {
                    end = 10
                }
                else{
                    end = GlobalDataRetriever.sharedInstance.globalDataSource.count
                }
                let qualityOfServiceClass = QOS_CLASS_BACKGROUND
                let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
                dispatch_async(backgroundQueue, {
                    GlobalDataRetriever.sharedInstance.downloadMediaFromGCS(start, end: end)
                })
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.addToButton.hidden = true
                    self.deletButton.hidden = true
                })
            }
        }
        
        fullScreenScrollView.delegate = self
        fullScreenScrollView.minimumZoomScale = 1.0
        fullScreenScrollView.maximumZoomScale = 10.0
        fullScreenScrollView.zoomScale = 1.0
        view.addSubview(fullScreenScrollView)
        
        fullScreenScrollView.delaysContentTouches = false;
        
        self.view.bringSubviewToFront(photoThumpCollectionView)
        self.view.bringSubviewToFront(playIconInFullView)
        self.view.bringSubviewToFront(TopView)
        self.view.bringSubviewToFront(BottomView)
        
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(PhotoViewerViewController.handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        self.view.addGestureRecognizer(doubleTap)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(PhotoViewerViewController.handleSwipe(_:)))
        swipeRight.direction = UISwipeGestureRecognizerDirection.Right
        self.view .addGestureRecognizer(swipeRight)
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(PhotoViewerViewController.handleSwipe(_:)))
        swipeLeft.direction = UISwipeGestureRecognizerDirection.Left
        self.view .addGestureRecognizer(swipeLeft)
        
        let enlargeImageViewRecognizer = UITapGestureRecognizer(target: self, action: #selector(PhotoViewerViewController.enlargeImageView(_:)))
        enlargeImageViewRecognizer.numberOfTapsRequired = 1
        fullScrenImageView.addGestureRecognizer(enlargeImageViewRecognizer)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(animated: Bool)
    {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(PhotoViewerViewController.doneButtonClickedToExit(_:)), name: MPMoviePlayerDidExitFullscreenNotification, object: self.moviePlayer)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(PhotoViewerViewController.Trial), name: MPMoviePlayerWillEnterFullscreenNotification, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(true)
        
        if ((playHandleflag == 1) && (willEnterFlag == 1))
        {
        }
        else if (playHandleflag == 1)
        {
            playHandleflag = 0
            self.moviePlayer .stop()
            
            NSNotificationCenter.defaultCenter().removeObserver(self)
        }
        if(downloadTask?.state == .Running)
        {
            downloadTask?.cancel()
        }
    }
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return self.fullScreenZoomView
    }
    
    func handleDoubleTap(recognizer: UITapGestureRecognizer) {
        if GlobalDataRetriever.sharedInstance.globalDataSource.count > 0
        {
            let mediaType = GlobalDataRetriever.sharedInstance.globalDataSource[selectedItem][mediaTypeKey] as! String
        
            if mediaType != "video"
            {
            if (fullScreenScrollView.zoomScale > fullScreenScrollView.minimumZoomScale) {
                fullScreenScrollView.setZoomScale(fullScreenScrollView.minimumZoomScale, animated: true)
            } else {
                let zoomRect = self.zoomRectForScale(fullScreenScrollView.minimumZoomScale+1, center: recognizer.locationInView(recognizer.view))
                self.fullScreenScrollView.zoomToRect(zoomRect, animated: true);
                
            }
        }
        }
    }
    
    func zoomRectForScale(scale : CGFloat, center : CGPoint) -> CGRect {
        var zoomRect = CGRectZero
        if let imageV = self.fullScreenScrollView {
            zoomRect.size.height = imageV.frame.size.height / scale;
            zoomRect.size.width  = imageV.frame.size.width  / scale;
            let newCenter = imageV.convertPoint(center, fromView: self.fullScreenScrollView)
            zoomRect.origin.x = newCenter.x - ((zoomRect.size.width / 2.0));
            zoomRect.origin.y = newCenter.y - ((zoomRect.size.height / 2.0));
        }
        return zoomRect;
    }
    
    func scrollViewWillBeginZooming(scrollView: UIScrollView, withView views: UIView?) {
        if GlobalDataRetriever.sharedInstance.globalDataSource.count > 0
        {
        if(fullScreenZoomView.hidden==true)
        {
            fullScreenZoomView.hidden = false
            fullScrenImageView.alpha = 0.0
            TopView.hidden = true
            BottomView.hidden = true
            photoThumpCollectionView.hidden = true
            playIconInFullView.hidden = true
            scrollView.scrollEnabled=true;
            
            self.view.bringSubviewToFront(photoThumpCollectionView)
            self.view.bringSubviewToFront(playIconInFullView)
            self.view.bringSubviewToFront(TopView)
            self.view.bringSubviewToFront(BottomView)
        }
        }
    }
    
    func scrollViewDidEndZooming(scrollView: UIScrollView, withView view: UIView?, atScale scale: CGFloat) {
        
        if(scale<=1.0)
        {
            fullScreenZoomView.hidden = true
            fullScrenImageView.alpha = 1.0
            TopView.hidden = false
            BottomView.hidden = false
            photoThumpCollectionView.hidden = false
            fullScreenScrollView.scrollEnabled=false;
            self.photoThumpCollectionView.reloadData()
            fullScreenScrollView.bounds = fullScrenImageView.bounds
        }
    }
    
    func enlargeImageView(Recognizer:UITapGestureRecognizer){
        if(GlobalDataRetriever.sharedInstance.globalDataSource.count > 0){
            if GlobalDataRetriever.sharedInstance.globalDataSource[selectedItem][mediaTypeKey] != nil
            {
                let mediaType = GlobalDataRetriever.sharedInstance.globalDataSource[selectedItem][mediaTypeKey] as! String
                
                if mediaType == "video"
                {
                    playIconInFullView.hidden = true
                    downloadVideo(selectedItem)
                }
            }
        }
    }
    
    func removeActivityIndicator(notif : NSNotification)
    {
        if(totalCount <= 10)
        {
            let filteredData = GlobalDataRetriever.sharedInstance.globalDataSource.filter(thumbExists)
            totalCount = filteredData.count
        }
        
        if(totalCount > 0){
            
            GlobalDataRetriever.sharedInstance.globalDataSource.sortInPlace({ p1, p2 in
                let time1 = p1[mediaDetailIdKey] as! String
                let time2 = p2[mediaDetailIdKey] as! String
                return time1 > time2
            })
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                
                
                self.addToButton.hidden = false
                self.deletButton.hidden = false
                self.photoThumpCollectionView.reloadData()
            })
            if GlobalDataRetriever.sharedInstance.globalDataSource.count > 0
            {
                let dict = GlobalDataRetriever.sharedInstance.globalDataSource[0]
                self.downloadFullImageWhenTapThumb(dict, indexpaths: 0,gestureIdentifier:0)
            }
            else{
                removeOverlay()
                ErrorManager.sharedInstance.emptyMedia()
                
            }
//            let dict = GlobalDataRetriever.sharedInstance.globalDataSource[0]
//            self.downloadFullImageWhenTapThumb(dict, indexpaths: 0,gestureIdentifier:0)
            if downloadingFlag == true
            {
                downloadingFlag = false
            }
        }
    }
    
    func thumbExists (item: [String : AnyObject]) -> Bool {
        return item[thumbImageKey] != nil
    }
    
    func scrollViewWillBeginDecelerating(scrollView: UIScrollView) {
        self.lastContentOffset = scrollView.contentOffset
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        if (self.lastContentOffset.x > scrollView.contentOffset.x) {
            if GlobalDataRetriever.sharedInstance.globalDataSource.count > 0
            {
            if(totalCount < GlobalDataRetriever.sharedInstance.globalDataSource.count)
            {
                if self.downloadingFlag == false
                {
                    self.downloadingFlag = true
                    let qualityOfServiceClass = QOS_CLASS_BACKGROUND
                    let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
                    dispatch_async(backgroundQueue, {
                        self.downloadImagesFromGlobalRetriever()
                    })
                }
            }
            }
        }
    }
    
    func downloadImagesFromGlobalRetriever()  {
        let start = totalCount
        var end = 0
        if((totalCount + 10) < GlobalDataRetriever.sharedInstance.globalDataSource.count){
            end = 10
        }
        else{
            end = GlobalDataRetriever.sharedInstance.globalDataSource.count - totalCount
        }
        totalCount = totalCount + end
        end = start + end
        GlobalDataRetriever.sharedInstance.downloadMediaFromGCS(start, end: end)
    }
    
    func convertStringtoURL(url : String) -> NSURL
    {
        let url : NSString = url
        let searchURL : NSURL = NSURL(string: url as String)!
        return searchURL
    }
    
    func downloadMedia(downloadURL : NSURL ,key : String , completion: (result: UIImage) -> Void)
    {
        var mediaImage : UIImage = UIImage()
        let data = NSData(contentsOfURL: downloadURL)
        if let imageData = data as NSData? {
            if let mediaImage1 = UIImage(data: imageData)
            {
                mediaImage = mediaImage1
            }
            completion(result: mediaImage)
        }
        else
        {
            completion(result:UIImage(named: "thumb12")!)
        }
    }
    
    func handleSwipe(gesture: UIGestureRecognizer)
    {
        swipeFlag = true
        self.removeOverlay()
        
        if (playHandleflag == 1)
        {
            playHandleflag = 0
            self.moviePlayer.stop()
            self.moviePlayer.view.removeFromSuperview()
            playIconInFullView.hidden = false
            self.view.userInteractionEnabled = true
        }
        
        downloadTask?.cancel()
        fullScrenImageView.alpha = 1.0
        progressLabelDownload?.removeFromSuperview()
        progressViewDownload?.removeFromSuperview()
        progressLabelDownload?.text=" ";
        progressViewDownload?.hidden=true;
        progressLabelDownload?.hidden=true;
        
        if let swipeGesture = gesture as? UISwipeGestureRecognizer
        {
            switch swipeGesture.direction
            {
            case UISwipeGestureRecognizerDirection.Left:
                if(selectedItem < GlobalDataRetriever.sharedInstance.globalDataSource.count-1)
                {
                    self.showOverlay()
                    let qualityOfServiceClass = QOS_CLASS_BACKGROUND
                    let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
                    dispatch_async(backgroundQueue, {
                        self.selectedItem = self.selectedItem+1
                        let dict = GlobalDataRetriever.sharedInstance.globalDataSource[self.selectedItem]
                        self.downloadFullImageWhenTapThumb(dict, indexpaths: self.selectedItem,gestureIdentifier:1)
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.removeOverlay()
                            self.setLabelValue(self.selectedItem)
                            self.photoThumpCollectionView.reloadData()
                        })
                    })
                }
                else if(selectedItem == GlobalDataRetriever.sharedInstance.globalDataSource.count-1)
                {
                    self.removeOverlay()
                }
                
            case UISwipeGestureRecognizerDirection.Right:
                if(selectedItem != 0)
                {
                    self.showOverlay()
                    let qualityOfServiceClass = QOS_CLASS_BACKGROUND
                    let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
                    dispatch_async(backgroundQueue, {
                        self.selectedItem = self.selectedItem - 1
                        let dict = GlobalDataRetriever.sharedInstance.globalDataSource[self.selectedItem]
                        self.downloadFullImageWhenTapThumb(dict, indexpaths: self.selectedItem,gestureIdentifier: 2)
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.removeOverlay()
                            self.setLabelValue(self.selectedItem)
                            self.photoThumpCollectionView.reloadData()
                        })
                    })
                }
                else if(selectedItem == 0)
                {
                    self.removeOverlay()
                }
                
            default:
                break
            }
        }
    }
    
    func doneButtonClickedToExit(notif2:NSNotification)
    {
        willEnterFlag = 0
        let fullScreenController = notif2.object as! MPMoviePlayerController
        fullScreenController.scalingMode = MPMovieScalingMode.AspectFill
        fullScreenController.play()
    }
    
    func Trial()
    {
        willEnterFlag = 1
    }
    
    func initialise()
    {
        fullScreenZoomView.userInteractionEnabled = true
        fullScreenZoomView.hidden = true
        fullScrenImageView.userInteractionEnabled = true
        playIconInFullView.hidden = true;
        addToButton.hidden = true
        deletButton.hidden = true
        mediaIdSelected = 0
        
        userId = defaults.valueForKey(userLoginIdKey) as! String
        accessToken = defaults.valueForKey(userAccessTockenKey) as! String
        archiveMediaCount = defaults.valueForKey(ArchiveCount) as! Int
    }
    
    @IBAction func deleteButtonAction(sender: AnyObject) {
        
        if(downloadTask?.state == .Running)
        {
            downloadTask?.cancel()
        }
        
        if (playHandleflag == 1)
        {
            playHandleflag = 0
            self.moviePlayer.stop()
            self.moviePlayer.view.removeFromSuperview()
        }
        
        progressLabelDownload?.removeFromSuperview()
        progressViewDownload?.removeFromSuperview()
        progressLabelDownload?.text = " "
        
        let alert = UIAlertController(title: "", message: "Are you sure you want to permanently delete this picture from all your channels?", preferredStyle: UIAlertControllerStyle.Alert)
        
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: {(
            action:UIAlertAction!) in
            if(GlobalDataRetriever.sharedInstance.globalDataSource[self.selectedItem][self.mediaTypeKey] as! String == "video"){
                self.playIconInFullView.hidden = false
            }
            else{
                self.playIconInFullView.hidden = true
            }
            self.mediaSelected.removeAllObjects()
            if self.mediaIdSelected == 0
            {
                self.mediaIdSelected = Int(GlobalDataRetriever.sharedInstance.globalDataSource[0][self.mediaDetailIdKey] as! String)!
                self.deletedMediaId = GlobalDataRetriever.sharedInstance.globalDataSource[0][self.mediaDetailIdKey] as! String
            }
            else{
                self.deletedMediaId = GlobalDataRetriever.sharedInstance.globalDataSource[self.selectedItem][self.mediaDetailIdKey] as! String
            }
            self.mediaSelected.addObject(self.mediaIdSelected)
            
            if(self.mediaSelected.count > 0)
            {
                var channelIds : [Int] = [Int]()
                if let channel = NSUserDefaults.standardUserDefaults().valueForKey("archiveId")
                {
                    let channelIdForApi = channel as! Int
                    channelIds.append(channelIdForApi)
                    
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
                else{
                    ErrorManager.sharedInstance.NoArchiveId()
                }
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler: {
            (action:UIAlertAction!) in print("you have pressed the Cancel button")
            self.fullScrenImageView.alpha = 1.0
            
            if(GlobalDataRetriever.sharedInstance.globalDataSource[self.selectedItem][self.mediaTypeKey] as! String == "video"){
                self.playIconInFullView.hidden = false
            }
            else{
                self.playIconInFullView.hidden = true
            }
            self.progressLabelDownload?.text = " "
        }))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func authenticationSuccessHandlerDelete(response:AnyObject?)
    {
        removeOverlay()
        self.fullScrenImageView.alpha = 1.0
        if let json = response as? [String: AnyObject]
        {
            mediaIdSelected = 0
            mediaSelected.removeAllObjects()
            
            if((GlobalDataRetriever.sharedInstance.globalDataSource.count > selectedItem)&&(GlobalDataRetriever.sharedInstance.globalDataSource.count > 0)){
                GlobalDataRetriever.sharedInstance.globalDataSource.removeAtIndex(selectedItem)
            }
            
            totalCount = totalCount - 1
            
            GlobalDataRetriever.sharedInstance.deleteMediasOnGlobalMyMediaDeletionAction(deletedMediaId)
            
            NSUserDefaults.standardUserDefaults().setInteger(GlobalDataRetriever.sharedInstance.globalDataSource.count - 1, forKey: ArchiveCount)
            
            if(selectedItem - 1 <= 0){
                selectedItem = 0
            }
            else{
                selectedItem = selectedItem - 1
            }
            
            if(GlobalDataRetriever.sharedInstance.globalDataSource.count > 0){
                deletButton.hidden = false
                addToButton.hidden = false
                let dict = GlobalDataRetriever.sharedInstance.globalDataSource[selectedItem]
                downloadFullImageWhenTapThumb(dict, indexpaths: selectedItem,gestureIdentifier: 0)
            }
            else{
                if(selectedItem == 0){
                    removeOverlay()
                    ErrorManager.sharedInstance.emptyMedia()
                }
                else{
                    showOverlay()
                }
                fullScrenImageView.image = UIImage()
                fullScreenZoomView.image = UIImage()
                deletButton.hidden = true
                addToButton.hidden = true
            }
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
    
    func setLabelValue(index: NSInteger)
    {
        if(GlobalDataRetriever.sharedInstance.globalDataSource.count > 0)
        {
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            dateFormatter.timeZone = NSTimeZone(name: "UTC")
            let fromdate = dateFormatter.dateFromString(GlobalDataRetriever.sharedInstance.globalDataSource[index][createdTimeStampKey] as! String)
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
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.mediaTimeLabel.text = dateForDisplay
            })
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
    
    func downloadVideo(index : Int)
    {
        videoDownloadIntex = index
        let videoDownloadUrl = convertStringtoURL(GlobalDataRetriever.sharedInstance.globalDataSource[index][fullImageURLKey] as! String)
        
        let mediaIdForFilePath = "\(GlobalDataRetriever.sharedInstance.globalDataSource[index][mediaDetailIdKey]!)"
        let parentPath = FileManagerViewController.sharedInstance.getParentDirectoryPath()
        let savingPath = "\(parentPath)/\(mediaIdForFilePath)video.mov"
        
        let fileExistFlag = FileManagerViewController.sharedInstance.fileExist(savingPath)
        if fileExistFlag == true
        {
            progressViewDownload?.hidden = true
            progressLabelDownload?.hidden = true
            
            let url = NSURL(fileURLWithPath: savingPath)
            self.moviePlayer = nil
            self.moviePlayer = MPMoviePlayerController.init(contentURL: url)
            
            if let player = self.moviePlayer
            {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(PhotoViewerViewController.playerDidFinish(_:)), name: MPMoviePlayerPlaybackDidFinishNotification, object: self.moviePlayer)
                    self.view.userInteractionEnabled = true
                    self.fullScrenImageView.userInteractionEnabled = true
                    player.view .removeFromSuperview()
                    player.shouldAutoplay = true
                    player.prepareToPlay()
                    player.view.frame = CGRect(x: self.fullScrenImageView.frame.origin.x, y: self.fullScrenImageView.frame.origin.y, width: self.fullScrenImageView.frame.size.width, height: self.fullScrenImageView.frame.size.height)
                    player.view.sizeToFit()
                    player.scalingMode = MPMovieScalingMode.Fill
                    player.movieSourceType = MPMovieSourceType.File
                    player.repeatMode = MPMovieRepeatMode.None
                    self.view.addSubview(player.view)
                    player.play()
                })
                NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(PhotoViewerViewController.playbackStateChange(_:)), name: MPMoviePlayerPlaybackStateDidChangeNotification, object: self.moviePlayer)
            }
        }
        else{
            let downloadRequest = NSMutableURLRequest(URL: videoDownloadUrl)
            let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration(), delegate: self, delegateQueue: NSOperationQueue.mainQueue())
            
            downloadTask = session.downloadTaskWithRequest(downloadRequest)
            progressViewDownload?.hidden = false
            progressLabelDownload?.hidden = false
            
            progressViewDownload = UIProgressView(progressViewStyle: UIProgressViewStyle.Default)
            progressViewDownload?.center = fullScrenImageView.center
            
            view.addSubview(progressViewDownload!)
            
            let frame = CGRectMake(fullScrenImageView.center.x - 100, fullScrenImageView.center.y - 100, 200, 50)
            progressLabelDownload?.frame = frame
            view.addSubview(progressLabelDownload!)
            fullScrenImageView.alpha = 0.2
            downloadTask!.resume()
        }
    }
    
    func playbackStateChange(notif:NSNotification)
    {
        let moviePlayerController = notif.object as! MPMoviePlayerController
        var playbackState: String = "Unknown"
        
        switch moviePlayerController.playbackState {
        case .Stopped:
            playbackState = "Stopped"
        case .Playing:
            playbackState = "Playing"
            playHandleflag = 1
        case .Paused:
            playbackState = "Paused"
            playHandleflag = 1
        case .Interrupted:
            playbackState = "Interrupted"
        case .SeekingForward:
            playbackState = "Seeking Forward"
        case .SeekingBackward:
            playbackState = "Seeking Backward"
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
            let mediaIdForFilePath = "\(GlobalDataRetriever.sharedInstance.globalDataSource[videoDownloadIntex][mediaDetailIdKey]!)"
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
                        
                        self.view.userInteractionEnabled = true
                        self.fullScrenImageView.userInteractionEnabled = true
                        player.view.frame = CGRect(x: self.fullScrenImageView.frame.origin.x, y: self.fullScrenImageView.frame.origin.y, width: self.fullScrenImageView.frame.size.width, height: self.fullScrenImageView.frame.size.height)
                        player.view.sizeToFit()
                        player.scalingMode = MPMovieScalingMode.Fill
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
    
    func uploadMediaProgress(notif:NSNotification)
    {
        let dict = notif.object as! [String:AnyObject]
        dictMediaId = dict[mediaDetailIdKey] as! String
        dictProgress = dict[uploadProgressKey] as! Float
        
        for var i = 0; i < GlobalDataRetriever.sharedInstance.globalDataSource.count; i++
        {
            let mediaIdFromData = GlobalDataRetriever.sharedInstance.globalDataSource[i][mediaDetailIdKey] as! String
            
            if(mediaIdFromData == dictMediaId){
                GlobalDataRetriever.sharedInstance.globalDataSource[i][uploadProgressKey] = dictProgress
            }
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.photoThumpCollectionView.reloadData()
            })
        }
    }
    
    func setFullscreenImage(notif:NSNotification)
    {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            let dict = GlobalDataRetriever.sharedInstance.globalDataSource[0]
            self.downloadFullImageWhenTapThumb(dict, indexpaths: 0,gestureIdentifier:0)
            self.photoThumpCollectionView.reloadData()
        })
    }
    
    @IBAction func didTapAddChannelButton(sender: AnyObject) {
        if(downloadTask?.state == .Running)
        {
            downloadTask?.cancel()
        }
        
        if (playHandleflag == 1)
        {
            playHandleflag = 0
            self.moviePlayer.stop()
            self.moviePlayer.view.removeFromSuperview()
        }
        
        progressLabelDownload?.removeFromSuperview()
        progressViewDownload?.removeFromSuperview()
        
        mediaSelected.removeAllObjects()
        addToDict.removeAll()
        if mediaIdSelected == 0
        {
            mediaIdSelected = Int(GlobalDataRetriever.sharedInstance.globalDataSource[0][mediaDetailIdKey] as! String)!
            addToDict.append(GlobalDataRetriever.sharedInstance.globalDataSource[0])
        }
        else{
            addToDict.append(GlobalDataRetriever.sharedInstance.globalDataSource[selectedItem])
        }
        
        mediaSelected.addObject(mediaIdSelected)
        
        mediaIdSelected = 0
        
        if let channel = NSUserDefaults.standardUserDefaults().valueForKey("archiveId")
        {
            if(mediaSelected.count > 0)
            {
                let channelStoryboard = UIStoryboard(name:"MyChannel", bundle: nil)
                let addChannelVC = channelStoryboard.instantiateViewControllerWithIdentifier(AddChannelViewController.identifier) as! AddChannelViewController
                addChannelVC.mediaDetailSelected = mediaSelected
                addChannelVC.selectedChannelId = channel.stringValue
                addChannelVC.localMediaDict = addToDict
                addChannelVC.navigationController?.navigationBarHidden = true
                self.navigationController?.pushViewController(addChannelVC, animated: false)
            }
        }
        else{
            ErrorManager.sharedInstance.NoArchiveId()
        }
    }
    
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
    
    func downloadFullImageWhenTapThumb(imageDict: [String:AnyObject], indexpaths : Int ,gestureIdentifier:Int) {
        var imageForMedia : UIImage = UIImage()
        print(indexpaths)
        if GlobalDataRetriever.sharedInstance.globalDataSource.count > 0
        {
        if let fullImage = imageDict[thumbImageKey]
        {
            if GlobalDataRetriever.sharedInstance.globalDataSource[indexpaths][mediaTypeKey] as! String == "video"
            {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.photoThumpCollectionView.alpha = 1.0
                    self.removeOverlay()
                    self.playIconInFullView.hidden = false;
                    if(gestureIdentifier==1||gestureIdentifier==2)
                    {
                        let animation = CATransition()
                        animation.duration = 0.4;
                        animation.type = kCATransitionMoveIn;
                        if(gestureIdentifier==1)
                        {
                            animation.subtype = kCATransitionFromRight;
                        }else{
                            animation.subtype = kCATransitionFromLeft;
                            
                        }
                        
                        self.fullScrenImageView.layer.addAnimation(animation, forKey: "imageTransition")
                        self.fullScreenZoomView.layer.addAnimation(animation, forKey: "imageTransition")
                    }
                    
                    
                    self.fullScrenImageView.image = (fullImage as! UIImage)
                    self.fullScreenZoomView.image = (fullImage as! UIImage)
                    self.fullScreenScrollView.hidden=true;
                    
                })
            }
            else
            {
                let mediaIdStr = GlobalDataRetriever.sharedInstance.globalDataSource[indexpaths][mediaDetailIdKey]
                print(GlobalDataRetriever.sharedInstance.globalDataSource[indexpaths][mediaDetailIdKey] as! String)
                print(mediaIdStr)
                let mediaIdForFilePath = "\(mediaIdStr!)full"
                let parentPath = FileManagerViewController.sharedInstance.getParentDirectoryPath()
                let savingPath = "\(parentPath)/\(mediaIdForFilePath )"
                let fileExistFlag = FileManagerViewController.sharedInstance.fileExist(savingPath)
                if fileExistFlag == true{
                    let mediaImageFromFile = FileManagerViewController.sharedInstance.getImageFromFilePath(savingPath)
                    imageForMedia = mediaImageFromFile!
                }
                else{
                    let mediaUrl = GlobalDataRetriever.sharedInstance.globalDataSource[indexpaths][fullImageURLKey] as! String
                    if(mediaUrl != ""){
                        let url: NSURL = convertStringtoURL(mediaUrl)
                        downloadMedia(url, key: "ThumbImage", completion: { (result) -> Void in
                            if(result != UIImage()){
                                let imageDataFromresult = UIImageJPEGRepresentation(result, 0.5)
                                let imageDataFromresultAsNsdata = (imageDataFromresult as NSData?)!
                                let imageDataFromDefault = UIImageJPEGRepresentation(UIImage(named: "thumb12")!, 0.5)
                                let imageDataFromDefaultAsNsdata = (imageDataFromDefault as NSData?)!
                                if(imageDataFromresultAsNsdata.isEqual(imageDataFromDefaultAsNsdata)){
                                    
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
                    self.photoThumpCollectionView.alpha = 1.0
                    self.removeOverlay()
                    if(gestureIdentifier==1||gestureIdentifier==2)
                    {
                        let animation = CATransition()
                        animation.duration = 0.4;
                        animation.type = kCATransitionMoveIn;
                        if(gestureIdentifier==1)
                        {
                            animation.subtype = kCATransitionFromRight;
                        }else{
                            animation.subtype = kCATransitionFromLeft;
                            
                        }
                        
                        self.fullScrenImageView.layer.addAnimation(animation, forKey: "imageTransition")
                        self.fullScreenZoomView.layer.addAnimation(animation, forKey: "imageTransition")
                    }
                   
                    self.playIconInFullView.hidden = true;
                    self.fullScreenScrollView.hidden=false;
                    
                })
            }
        }
        
        self.view.bringSubviewToFront(photoThumpCollectionView)
        self.view.bringSubviewToFront(playIconInFullView)
        self.view.bringSubviewToFront(TopView)
        self.view.bringSubviewToFront(BottomView)
        }
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
}

//PRAGMA MARK:- Collection View Delegates

extension PhotoViewerViewController:UICollectionViewDelegate,UICollectionViewDelegateFlowLayout
{
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return totalCount
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoThumbCollectionViewCell", forIndexPath: indexPath) as! PhotoThumbCollectionViewCell
        
        cell.layer.shouldRasterize = true
        cell.layer.rasterizationScale = UIScreen.mainScreen().scale
        
        if((GlobalDataRetriever.sharedInstance.globalDataSource.count > indexPath.row) && (GlobalDataRetriever.sharedInstance.globalDataSource.count > 0))
        {
            if(indexPath.row == selectedItem){
                if(swipeFlag){
                    photoThumpCollectionView.scrollToItemAtIndexPath(indexPath, atScrollPosition: UICollectionViewScrollPosition.CenteredHorizontally, animated: false)
                }
                cell.layer.borderWidth = 2;
                cell.layer.borderColor = UIColor(red: 44.0/255.0, green: 214.0/255.0, blue: 229.0/255.0, alpha: 0.7).CGColor
            }
            else{
                cell.layer.borderWidth = 0;
                cell.layer.borderColor = UIColor.clearColor().CGColor;
            }
            var dict = GlobalDataRetriever.sharedInstance.globalDataSource[indexPath.row]
            
            if let thumpImage = dict[thumbImageKey]
            {
                if GlobalDataRetriever.sharedInstance.globalDataSource[indexPath.row][mediaTypeKey] as! String == "video"
                {
                    cell.playIcon.hidden = false
                }
                else
                {
                    cell.playIcon.hidden = true
                }
                cell.progressView.hidden = true
                
                cell.thumbImageView.image = (thumpImage as! UIImage)
                
                let progress = GlobalDataRetriever.sharedInstance.globalDataSource[indexPath.row][uploadProgressKey] as! Float
                if((progress == 1.0) || (progress == 0.0))
                {
                    cell.progressView.hidden = true
                    cell.cloudIcon.hidden = false
                }else{
                    cell.progressView.progress = progress
                    cell.progressView.hidden = false
                    cell.cloudIcon.hidden = true
                }
            }
        }
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath)
    {
        swipeFlag = false
        
        if (playHandleflag == 1)
        {
            playHandleflag = 0
            self.moviePlayer.stop()
            self.moviePlayer.view.removeFromSuperview()
        }
        self.selectedItem = indexPath.row
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.photoThumpCollectionView.reloadData()
        })
        
        if GlobalDataRetriever.sharedInstance.globalDataSource.count > indexPath.row
        {
            if(downloadTask?.state == .Running)
            {
                downloadTask?.cancel()
                fullScrenImageView.alpha = 1.0
                progressLabelDownload?.removeFromSuperview()
                progressViewDownload?.removeFromSuperview()
                progressLabelDownload?.text = " "
            }
            setLabelValue(indexPath.row)
        }
        
        self.fullScrenImageView.alpha = 1.0
        self.showOverlay()
        if GlobalDataRetriever.sharedInstance.globalDataSource.count > indexPath.row
        {
            self.mediaIdSelected = Int(GlobalDataRetriever.sharedInstance.globalDataSource[indexPath.row][self.mediaDetailIdKey] as! String)!
            let dict = GlobalDataRetriever.sharedInstance.globalDataSource[indexPath.row]
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.downloadFullImageWhenTapThumb(dict, indexpaths: indexPath.row ,gestureIdentifier:0)
            })
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
}


