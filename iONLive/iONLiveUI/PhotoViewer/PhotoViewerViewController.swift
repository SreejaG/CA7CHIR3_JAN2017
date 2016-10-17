
import UIKit
import MediaPlayer
import Foundation
import AVKit

protocol progressviewDelegate
{
    func ProgresviewUpdate (value : Float)
}

class PhotoViewerViewController: UIViewController,UIGestureRecognizerDelegate,NSURLSessionDelegate, NSURLSessionTaskDelegate,NSURLSessionDataDelegate,NSURLSessionDownloadDelegate,UIScrollViewDelegate,AVPlayerViewControllerDelegate
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
    
    @IBOutlet var videoDurationLabel: UILabel!
    
    static let identifier = "PhotoViewerViewController"
    
    let imageUploadManger = ImageUpload.sharedInstance
    let requestManager = RequestManager.sharedInstance
    let channelManager = ChannelManager.sharedInstance
    
    let defaults = NSUserDefaults .standardUserDefaults()
    
    private var downloadTask: NSURLSessionDownloadTask?
    
    var operationQueueObjInMyMediaList = NSOperationQueue()
    var operationInMyMediaList = NSBlockOperation()
    
    var progressViewDownload: UIProgressView?
    var progressLabelDownload: UILabel?
    var NoDatalabelFormyMediaImageList : UILabel = UILabel()
    var loadingOverlay: UIView?
    var addToDict : [[String:AnyObject]] = [[String:AnyObject]]()
    var mediaSelected: NSMutableArray = NSMutableArray()
    var willEnterFlag : NSInteger = NSInteger()
    var playHandleflag : NSInteger = NSInteger()
    var selectedItem : Int = Int()
    var archiveMediaCount : Int = Int()
    var archiveChanelId : String = String()
    var mediaIdSelected : Int = 0
    var videoDownloadIntex : Int = 0
    var totalCount = 0
    var swipeFlag : Bool = false
    var downloadingFlag : Bool = false
    var dictMediaId : String = String()
    var userId : String = String()
    var accessToken: String = String()
    var deletedMediaId : NSMutableArray = NSMutableArray()
    var dictProgress : Float = Float()
    var orientationFlag: Int = Int()
    var Orgimage : UIImage? = UIImage()
    var mediaTypeSelected : String = String()
    let playerViewController = AVPlayerViewController()
    var videoThumbImage : UIImage = UIImage()
    var customView = CustomInfiniteIndicator()
    
    class var sharedInstance: PhotoViewerViewController {
        struct Singleton {
            static let instance = PhotoViewerViewController()
        }
        return Singleton.instance
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        getCurrentOrientaion()
        selectedItem = 0
        self.photoThumpCollectionView.alwaysBounceHorizontal = true
        progressLabelDownload = UILabel()
        progressViewDownload?.hidden = true
        progressLabelDownload?.hidden = true
        self.fullScrenImageView.image = UIImage()
        self.fullScreenZoomView.image = UIImage()
        playHandleflag = 0
        videoDurationLabel.hidden = true
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(PhotoViewerViewController.removeActivityIndicatorMyMedia(_:)), name: "removeActivityIndicatorMyChannel", object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(PhotoViewerViewController.uploadMediaProgress(_:)), name: "upload", object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(PhotoViewerViewController.setFullscreenImage(_:)), name: "setFullscreenImage", object: nil)
        
        showOverlay()
        initialise()
        archiveMediaCount = defaults.valueForKey(ArchiveCount) as! Int
        archiveChanelId = "\(defaults.valueForKey(archiveId) as! Int)"
        
        if((archiveMediaCount == 0) || (GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict.count <= 0)){
            self.removeOverlay()
            addNoDataLabel()
            self.addToButton.hidden = true
            self.deletButton.hidden = true
            self.fullScreenZoomView.image = UIImage()
            self.fullScrenImageView.image = UIImage()
        }
        else if(GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict.count > 0)
        {
            var channelKeys = Array(GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict.keys)
            if(channelKeys.contains(archiveChanelId)){
                let filteredData = GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[archiveChanelId]!.filter(thumbExists)
                totalCount = filteredData.count
                GlobalChannelToImageMapping.sharedInstance.setFilteredCount(totalCount)
            }
            channelKeys.removeAll()
            if totalCount > 0
            {
                removeOverlay()
                let dict = GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[archiveChanelId]![selectedItem]
                downloadFullImageWhenTapThumb(dict, indexpaths: selectedItem,gestureIdentifier: 0)
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.addToButton.hidden = false
                    self.deletButton.hidden = false
                    self.photoThumpCollectionView.reloadData()
                })
                if(GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[archiveChanelId]!.count > totalCount){
                    if(totalCount < 10){
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.photoThumpCollectionView.userInteractionEnabled = false
                            self.customView = CustomInfiniteIndicator(frame: CGRectMake(self.photoThumpCollectionView.layer.frame.width - 50, self.photoThumpCollectionView.layer.frame.height/2 - 10, 20, 20))
                            self.photoThumpCollectionView.addSubview(self.customView)
                            self.customView.startAnimating()
                        })
                    }
                }
            }
            else if totalCount <= 0
            {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.addToButton.hidden = true
                    self.deletButton.hidden = true
                    self.fullScreenZoomView.image = UIImage()
                    self.fullScrenImageView.image = UIImage()
                    self.photoThumpCollectionView.reloadData()
                })
            }
            downloadImagesFromGlobalChannelImageMapping(21)
        }
        
        fullScreenScrollView.delegate = self
        fullScreenScrollView.minimumZoomScale = 1.0
        fullScreenScrollView.maximumZoomScale = 10.0
        fullScreenScrollView.zoomScale = 1.0
        view.addSubview(fullScreenScrollView)
        fullScreenScrollView.delaysContentTouches = false;
        
        self.view.bringSubviewToFront(fullScrenImageView)
        self.view.bringSubviewToFront(photoThumpCollectionView)
        self.view.bringSubviewToFront(playIconInFullView)
        self.view.bringSubviewToFront(TopView)
        self.view.bringSubviewToFront(BottomView)
        
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(PhotoViewerViewController.handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        self.view.addGestureRecognizer(doubleTap)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(PhotoViewerViewController.handleSwipe(_:)))
        swipeRight.direction = UISwipeGestureRecognizerDirection.Right
        self.fullScrenImageView.addGestureRecognizer(swipeRight)
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(PhotoViewerViewController.handleSwipe(_:)))
        swipeLeft.direction = UISwipeGestureRecognizerDirection.Left
        self.fullScrenImageView.addGestureRecognizer(swipeLeft)
        
        swipeRight.delegate = self;
        swipeLeft.delegate = self;
        
        let enlargeImageViewRecognizer = UITapGestureRecognizer(target: self, action: #selector(PhotoViewerViewController.enlargeImageView(_:)))
        enlargeImageViewRecognizer.numberOfTapsRequired = 1
        fullScrenImageView.addGestureRecognizer(enlargeImageViewRecognizer)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(animated: Bool)
    {
        
        if (self.mediaTypeSelected == "video")
        {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                
                self.fullScrenImageView.image = self.setOrientationForVideo()
                self.fullScreenZoomView.image = self.setOrientationForVideo()
            })
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(PhotoViewerViewController.orientaionChanged(_:)), name: UIDeviceOrientationDidChangeNotification, object: UIDevice.currentDevice())
        
        downloadingFlag = false
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(true)
        operationInMyMediaList.cancel()
        NSNotificationCenter.defaultCenter().removeObserver(UIDeviceOrientationDidChangeNotification)
        NSNotificationCenter.defaultCenter().removeObserver(AVPlayerItemDidPlayToEndTimeNotification)
        if ((playHandleflag == 1) && (willEnterFlag == 1))
        {
        }
        else if (playHandleflag == 1)
        {
            playHandleflag = 0
            NSNotificationCenter.defaultCenter().removeObserver(self)
        }
        if(downloadTask?.state == .Running)
        {
            downloadTask?.cancel()
        }
    }
    
    func getCurrentOrientaion()
    {
        let device: UIDevice = UIDevice.currentDevice()
        switch device.orientation {
        case .Portrait,.PortraitUpsideDown:
            orientationFlag = 1;
            break;
        case .LandscapeLeft:
            orientationFlag = 2;
            break;
        case .LandscapeRight:
            orientationFlag = 3;
            break;
        default:
            orientationFlag = 1
            break;
        }
    }
    
    func orientaionChanged(notification:NSNotification)
    {
        var orientedImage = Orgimage
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            if(self.Orgimage != nil && self.totalCount > 0){
                let viewController: UIViewController = (self.navigationController?.visibleViewController)!
                if(viewController.restorationIdentifier == "PhotoViewerViewController"){
                    if(self.mediaTypeSelected != "video")
                    {
                        let transition : CATransition = CATransition()
                        transition.duration = 0.3;
                        transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
                        transition.type = kCATransitionFade;
                        transition.delegate = self;
                        self.fullScrenImageView.layer.addAnimation(transition, forKey: nil)
                        
                        let device: UIDevice = notification.object as! UIDevice
                        switch device.orientation {
                        case .Portrait,.PortraitUpsideDown:
                            self.orientationFlag = 1;
                            if self.Orgimage!.size.width > self.Orgimage!.size.height
                            {
                                self.fullScrenImageView.contentMode = .ScaleAspectFit
                            }
                            else{
                                self.fullScrenImageView.contentMode = .ScaleAspectFill
                            }
                            orientedImage = self.Orgimage
                            break;
                        case .LandscapeLeft:
                            self.orientationFlag = 2;
                            if self.Orgimage!.size.width > self.Orgimage!.size.height
                            {
                                self.fullScrenImageView.contentMode = .ScaleAspectFit
                                orientedImage = UIImage(CGImage: self.Orgimage!.CGImage!, scale: CGFloat(1.0),
                                    orientation: .Right)
                            }
                            else{
                                self.fullScrenImageView.contentMode = .ScaleAspectFit
                                orientedImage = UIImage(CGImage: self.Orgimage!.CGImage!, scale: CGFloat(1.0),
                                    orientation: .Down)
                            }
                            break;
                        case .LandscapeRight:
                            self.orientationFlag = 3;
                            if self.Orgimage!.size.width > self.Orgimage!.size.height
                            {
                                self.fullScrenImageView.contentMode = .ScaleAspectFit
                                orientedImage = UIImage(CGImage: self.Orgimage!.CGImage!, scale: CGFloat(1.0),
                                    orientation: .Left)
                            }
                            else{
                                self.fullScrenImageView.contentMode = .ScaleAspectFit
                                orientedImage = UIImage(CGImage: self.Orgimage!.CGImage!, scale: CGFloat(1.0),
                                    orientation: .Up)
                            }
                            break;
                        default:
                            self.orientationFlag = 1
                            break;
                        }
                        
                    }
                    else{
                        orientedImage = self.setOrientationForVideo()
                    }
                    self.fullScrenImageView.image = orientedImage! as UIImage
                    self.fullScreenZoomView.image = orientedImage! as UIImage
                    
                }
            }
        })
    }
    
    func downloadImagesFromGlobalChannelImageMapping(limit:Int)  {
        operationInMyMediaList.cancel()
        let start = totalCount
        var end = 0
        
        if GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[archiveChanelId] != nil
        {
            if((totalCount + limit) <= GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[archiveChanelId]!.count){
                end = limit
            }
            else{
                end = GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[archiveChanelId]!.count - totalCount
            }
            end = start + end
            if end <= GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[archiveChanelId]!.count
            {
                
                operationInMyMediaList  = NSBlockOperation (block: {
                    GlobalChannelToImageMapping.sharedInstance.downloadMediaFromGCS(self.archiveChanelId, start: start, end: end, operationObj: self.operationInMyMediaList)
                })
                self.operationQueueObjInMyMediaList.addOperation(operationInMyMediaList)
            }
        }
        GlobalChannelToImageMapping.sharedInstance.setFilteredCount(end)
        
    }
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return self.fullScreenZoomView
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func handleDoubleTap(recognizer: UITapGestureRecognizer) {
        if(GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict.count > 0){
            if GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[archiveChanelId]!.count > 0
            {
                let mediaType = GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[archiveChanelId]![selectedItem][mediaTypeKey] as! String
                
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
        if GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[archiveChanelId]!.count > 0
        {
            if(fullScreenZoomView.hidden==true)
            {
                downloadingFlag = true
                fullScreenZoomView.hidden = false
                fullScrenImageView.alpha = 0.0
                TopView.hidden = true
                BottomView.hidden = true
                photoThumpCollectionView.hidden = true
                playIconInFullView.hidden = true
                scrollView.scrollEnabled=true;
                fullScrenImageView.userInteractionEnabled = false
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
            downloadingFlag = false
            fullScreenZoomView.hidden = true
            fullScrenImageView.alpha = 1.0
            TopView.hidden = false
            BottomView.hidden = false
            photoThumpCollectionView.hidden = false
            fullScreenScrollView.scrollEnabled=false;
            self.photoThumpCollectionView.reloadData()
            fullScrenImageView.userInteractionEnabled = true
            fullScreenScrollView.bounds = fullScrenImageView.bounds
        }
    }
    
    func enlargeImageView(Recognizer:UITapGestureRecognizer){
        if(GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[archiveChanelId]!.count > 0){
            if GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[archiveChanelId]![selectedItem][mediaTypeKey] != nil
            {
                let mediaType = GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[archiveChanelId]![selectedItem][mediaTypeKey] as! String
                if mediaType == "video"
                {
                    downloadVideo(selectedItem)
                }
            }
        }
    }
    
    func addNoDataLabel()
    {
        self.NoDatalabelFormyMediaImageList = UILabel(frame: CGRectMake((self.view.frame.width/2) - 100,(self.view.frame.height/2) - 35, 200, 70))
        self.NoDatalabelFormyMediaImageList.textAlignment = NSTextAlignment.Center
        self.NoDatalabelFormyMediaImageList.text = "No Media Available"
        self.view.addSubview(self.NoDatalabelFormyMediaImageList)
    }
    
    func removeActivityIndicatorMyMedia(notif : NSNotification){
        operationInMyMediaList.cancel()
        let filteredData = GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[archiveChanelId]!.filter(thumbExists)
        totalCount = filteredData.count
        if GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[self.archiveChanelId]!.count > 0
        {
            let dict =  GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[self.archiveChanelId]![0]
            self.downloadFullImageWhenTapThumb(dict, indexpaths: selectedItem,gestureIdentifier:0)
        }
        else{
            removeOverlay()
            addNoDataLabel()
        }
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.photoThumpCollectionView.userInteractionEnabled = true
            self.customView.stopAnimationg()
            self.customView.removeFromSuperview()
            self.addToButton.hidden = false
            self.deletButton.hidden = false
            self.photoThumpCollectionView.reloadData()
        })
        
        if downloadingFlag == true
        {
            downloadingFlag = false
        }
    }
    
    func thumbExists (item: [String : AnyObject]) -> Bool {
        return item[tImageKey] != nil
    }
    
    func scrollViewWillBeginDecelerating(scrollView: UIScrollView) {
        self.lastContentOffset = scrollView.contentOffset
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        if (self.lastContentOffset.x > scrollView.contentOffset.x) {
            if totalCount > 0
            {
                if(totalCount < GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[archiveChanelId]!.count)
                {
                    if self.downloadingFlag == false
                    {
                        self.downloadingFlag = true
                        downloadImagesFromGlobalChannelImageMapping(12)
                    }
                }
            }
        }
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
        do {
            let data = try NSData(contentsOfURL: downloadURL,options: NSDataReadingOptions())
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
            
        } catch {
            completion(result:UIImage(named: "thumb12")!)
        }
    }
    
    func handleSwipe(gesture: UIGestureRecognizer)
    {
        if GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[archiveChanelId]!.count == 0
        {
        }
        else
        {
            if totalCount > 0
            {
                swipeFlag = true
                self.removeOverlay()
                fullScrenImageView.userInteractionEnabled = true
                if (playHandleflag == 1)
                {
                    playHandleflag = 0
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
                        if(selectedItem < totalCount - 1)
                        {
                            let qualityOfServiceClass = QOS_CLASS_BACKGROUND
                            let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
                            dispatch_async(backgroundQueue, {
                                self.selectedItem = self.selectedItem+1
                                let dict = GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[self.archiveChanelId]![self.selectedItem]
                                self.downloadFullImageWhenTapThumb(dict, indexpaths: self.selectedItem,gestureIdentifier:1)
                                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                    self.removeOverlay()
                                    self.setLabelValue(self.selectedItem)
                                    self.photoThumpCollectionView.reloadData()
                                })
                            })
                        }
                        else if(selectedItem == totalCount - 1)
                        {
                            self.removeOverlay()
                        }
                        
                    case UISwipeGestureRecognizerDirection.Right:
                        if(selectedItem != 0)
                        {
                            let qualityOfServiceClass = QOS_CLASS_BACKGROUND
                            let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
                            dispatch_async(backgroundQueue, {
                                self.selectedItem = self.selectedItem - 1
                                let dict = GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[self.archiveChanelId]![self.selectedItem]
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
        }
    }
    
    func doneButtonClickedToExit(notif2:NSNotification)
    {
        willEnterFlag = 0
        let fullScreenController = notif2.object as! MPMoviePlayerController
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            fullScreenController.scalingMode = MPMovieScalingMode.AspectFit
        })
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
    }
    
    @IBAction func deleteButtonAction(sender: AnyObject) {
        
        if(downloadTask?.state == .Running)
        {
            downloadTask?.cancel()
            downloadTask = nil
        }
        
        if (playHandleflag == 1)
        {
            playHandleflag = 0
        }
        
        progressLabelDownload?.removeFromSuperview()
        progressViewDownload?.removeFromSuperview()
        progressLabelDownload?.text = " "
        
        let alert = UIAlertController(title: "", message: "Are you sure you want to permanently delete this picture from all your channels?", preferredStyle: UIAlertControllerStyle.Alert)
        
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: {(
            action:UIAlertAction!) in
            self.deletedMediaId.removeAllObjects()
            self.mediaSelected.removeAllObjects()
            
            if(GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[self.archiveChanelId]![self.selectedItem][mediaIdKey] as! String == "video"){
                self.playIconInFullView.hidden = false
            }
            else{
                self.playIconInFullView.hidden = true
            }
            let mediaIdChecked : String = GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[self.archiveChanelId]![self.selectedItem][mediaIdKey] as! String
            
            self.mediaIdSelected = Int(mediaIdChecked)!
            self.deletedMediaId.addObject(mediaIdChecked)
            self.mediaSelected.addObject(self.mediaIdSelected)
            
            if(self.mediaSelected.count > 0)
            {
                var channelIds : [Int] = [Int]()
                if let channel = NSUserDefaults.standardUserDefaults().valueForKey(archiveId)
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
                channelIds.removeAll()
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler: {
            (action:UIAlertAction!) in print("you have pressed the Cancel button")
            self.fullScrenImageView.alpha = 1.0
            if(GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[self.archiveChanelId]![self.selectedItem][mediaTypeKey] as! String == "video"){
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
        if let _ = response as? [String: AnyObject]
        {
            mediaIdSelected = 0
            mediaSelected.removeAllObjects()
            GlobalChannelToImageMapping.sharedInstance.deleteMediasFromChannel(archiveChanelId, mediaIds: deletedMediaId)
            totalCount = totalCount - 1
            archiveMediaCount = archiveMediaCount - 1
            downloadImagesFromGlobalChannelImageMapping(1)
            
            if(selectedItem - 1 <= 0){
                selectedItem = 0
            }
            else{
                selectedItem = selectedItem - 1
            }
            
            if(GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[archiveChanelId]!.count > 0){
                deletButton.hidden = false
                addToButton.hidden = false
                let dict = GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[archiveChanelId]![selectedItem]
                downloadFullImageWhenTapThumb(dict, indexpaths: selectedItem,gestureIdentifier: 0)
            }
            else{
                if(GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[archiveChanelId]!.count <= 0){
                    removeOverlay()
                    addNoDataLabel()
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
        if( GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[archiveChanelId]!.count > 0)
        {
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            dateFormatter.timeZone = NSTimeZone(name: "UTC")
            let fromdate = dateFormatter.dateFromString(GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[archiveChanelId]![index][createdTimeKey] as! String)
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
                    dateFormatterDisplay.dateFormat = "   MMM d, yyyy"
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
        
        let mediaIdForFilePath = "\( GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[archiveChanelId]![index][mediaIdKey]!)"
        
        let videoUrl = UrlManager.sharedInstance.getFullImageForMedia(mediaIdForFilePath, userName: userId, accessToken: accessToken)
        let videoDownloadUrl = convertStringtoURL(videoUrl)
        
        let parentPath = FileManagerViewController.sharedInstance.getParentDirectoryPath()
        let savingPath = "\(parentPath)/\(mediaIdForFilePath)video.mov"
        
        let fileExistFlag = FileManagerViewController.sharedInstance.fileExist(savingPath)
        if fileExistFlag == true
        {
            progressViewDownload?.hidden = true
            progressLabelDownload?.hidden = true
            let url1 = NSURL(fileURLWithPath: savingPath)
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                
                self.view.userInteractionEnabled = true
                self.fullScrenImageView.userInteractionEnabled = true
                
                self.playHandleflag = 1
                let player1 = AVPlayer(URL: url1)
                if #available(iOS 9.0, *) {
                    self.playerViewController.delegate = self
                } else {
                    // Fallback on earlier versions
                }
                self.playerViewController.view.frame = CGRectMake(0, 64, 320, 420)
                self.playerViewController.showsPlaybackControls = true
                player1.actionAtItemEnd = .None
                
                if #available(iOS 9.0, *) {
                    self.playerViewController.allowsPictureInPicturePlayback = true
                } else {
                    // Fallback on earlier versions
                }
                self.playerViewController.videoGravity = AVLayerVideoGravityResizeAspect;
                self.playerViewController.player = player1
                self.presentViewController(self.playerViewController, animated: true, completion: {
                    self.playerViewController.player!.play()
                    NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(PhotoViewerViewController.playerDidFinishPlaying(_:)), name: AVPlayerItemDidPlayToEndTimeNotification, object: player1.currentItem)
                })
            })
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
            self.playIconInFullView.hidden = true
            let frame = CGRectMake(fullScrenImageView.center.x - 100, fullScrenImageView.center.y - 100, 200, 50)
            progressLabelDownload?.frame = frame
            view.addSubview(progressLabelDownload!)
            fullScrenImageView.alpha = 0.2
            downloadTask!.resume()
        }
    }
    func playerDidFinishPlaying(notif: NSNotification) {
        self.playerViewController.removeFromParentViewController()
        self.playerViewController.dismissViewControllerAnimated(true, completion: nil)
        
        self.fullScrenImageView.image = self.setOrientationForVideo()
        self.fullScreenZoomView.image = self.setOrientationForVideo()
    }
    func playbackStateChange(notif:NSNotification)
    {
        let moviePlayerController = notif.object as! MPMoviePlayerController
        
        switch moviePlayerController.playbackState {
        case .Stopped: break
        case .Playing:
            playHandleflag = 1
        case .Paused:
            playHandleflag = 1
        case .Interrupted: break
        case .SeekingForward: break
        case .SeekingBackward: break
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
            self.playIconInFullView.hidden = false
            
            progressLabelDownload?.removeFromSuperview()
            progressViewDownload?.removeFromSuperview()
        }
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        let data = NSData(contentsOfURL: location)
        if let imageData = data as NSData? {
            let mediaIdForFilePath = "\( GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[archiveChanelId]![videoDownloadIntex][mediaIdKey]!)"
            let parentPath = FileManagerViewController.sharedInstance.getParentDirectoryPath().absoluteString
            let savingPath = "\(parentPath)/\(mediaIdForFilePath)video.mov"
            let url = NSURL(fileURLWithPath: savingPath)
            let writeFlag = imageData.writeToURL(url, atomically: true)
            if(writeFlag){
                videoDownloadIntex = 0
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.view.userInteractionEnabled = true
                    self.fullScrenImageView.userInteractionEnabled = true
                    self.playHandleflag = 1
                    self.view.userInteractionEnabled = true
                    self.fullScrenImageView.userInteractionEnabled = true
                    self.playHandleflag = 1
                    let player1 = AVPlayer(URL: url)
                    if #available(iOS 9.0, *) {
                        self.playerViewController.delegate = self
                    } else {
                        // Fallback on earlier versions
                    }
                    self.playerViewController.view.frame = CGRectMake(0, 64, 320, 420)
                    self.playerViewController.showsPlaybackControls = true
                    player1.actionAtItemEnd = .None
                    
                    if #available(iOS 9.0, *) {
                        self.playerViewController.allowsPictureInPicturePlayback = true
                    } else {
                        // Fallback on earlier versions
                    }
                    self.playerViewController.videoGravity = AVLayerVideoGravityResizeAspect;
                    self.playerViewController.player = player1
                    self.presentViewController(self.playerViewController, animated: true, completion: {
                        self.playerViewController.player!.play()
                        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(PhotoViewerViewController.playerDidFinishPlaying(_:)), name: AVPlayerItemDidPlayToEndTimeNotification, object: player1.currentItem)
                    })
                    
                })
            }
        }
    }
    
    func playerDidFinish(notif:NSNotification)
    {
        playIconInFullView.hidden = false
        self.view.userInteractionEnabled = true
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
    }
    
    func uploadMediaProgress(notif:NSNotification)
    {
        let dict = notif.object as! [String:AnyObject]
        dictMediaId = dict[mediaIdKey] as! String
        dictProgress = dict[progressKey] as! Float
        
        for i in 0 ..<  GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[archiveChanelId]!.count
        {
            let mediaIdFromData =  GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[archiveChanelId]![i][mediaIdKey] as! String
            
            if(mediaIdFromData == dictMediaId){
                GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[archiveChanelId]![i][progressKey] = dictProgress
            }
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.photoThumpCollectionView.reloadData()
            })
        }
    }
    
    func setFullscreenImage(notif:NSNotification)
    {
        if GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict.count > 0
        {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.archiveMediaCount = self.defaults.valueForKey(ArchiveCount) as! Int
                let filteredData =  GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[self.archiveChanelId]!.filter(self.thumbExists)
                self.totalCount = filteredData.count
                self.addToButton.hidden = false
                self.deletButton.hidden = false
                
                let dict =  GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[self.archiveChanelId]![0]
                self.downloadFullImageWhenTapThumb(dict, indexpaths: 0,gestureIdentifier:0)
                self.photoThumpCollectionView.reloadData()
            })
        }
    }
    
    @IBAction func didTapAddChannelButton(sender: AnyObject) {
        if(downloadTask?.state == .Running)
        {
            downloadTask?.cancel()
        }
        
        if (playHandleflag == 1)
        {
            playHandleflag = 0
        }
        
        progressLabelDownload?.removeFromSuperview()
        progressViewDownload?.removeFromSuperview()
        
        mediaSelected.removeAllObjects()
        addToDict.removeAll()
        if mediaIdSelected == 0
        {
            mediaIdSelected = Int( GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[archiveChanelId]![0][mediaIdKey] as! String)!
            addToDict.append( GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[archiveChanelId]![0])
        }
        else{
            addToDict.append( GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[archiveChanelId]![selectedItem])
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
        if(playHandleflag == 0)
        {
            let cameraViewStoryboard = UIStoryboard(name:"IPhoneCameraView" , bundle: nil)
            let iPhoneCameraViewController = cameraViewStoryboard.instantiateViewControllerWithIdentifier("IPhoneCameraViewController") as! IPhoneCameraViewController
            self.navigationController?.navigationBarHidden = true
            self.navigationController?.pushViewController(iPhoneCameraViewController, animated: false)
        }
        else if(playHandleflag == 1)
        {
            playHandleflag = 0;
            playIconInFullView.hidden = false
            self.view.userInteractionEnabled = true
        }
    }
    func setOrientationForVideo() -> UIImage
    {
        getCurrentOrientaion()
        var orientedImage : UIImage = UIImage()
        switch self.orientationFlag {
        case 1:
            self.fullScrenImageView.contentMode = .ScaleAspectFill
            orientedImage = self.videoThumbImage;
            self.playIconInFullView.image = UIImage(named: "Circled Play")
            break;
        case 2:
            self.fullScrenImageView.contentMode = .ScaleAspectFit
            orientedImage = UIImage(CGImage: self.videoThumbImage.CGImage!, scale: CGFloat(1.0),
                                    orientation: .Right)
            self.playIconInFullView.image = UIImage(CGImage:  UIImage(named: "Circled Play")!.CGImage!, scale: CGFloat(1.0),
                                                    orientation: .Right)
            
            break;
        case 3:
            self.fullScrenImageView.contentMode = .ScaleAspectFit
            orientedImage = UIImage(CGImage: self.videoThumbImage.CGImage!, scale: CGFloat(1.0),
                                    orientation: .Left)
            self.playIconInFullView.image =   UIImage(CGImage:  UIImage(named: "Circled Play")!.CGImage!, scale: CGFloat(1.0),
                                                      orientation: .Left)
            
            break;
        default:
            break;
        }
        return orientedImage
    }
    func downloadFullImageWhenTapThumb(imageDict: [String:AnyObject], indexpaths : Int ,gestureIdentifier:Int) {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.removeOverlay()
        })
        var imageForMedia : UIImage = UIImage()
        if GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[archiveChanelId]!.count > 0
        {
            mediaTypeSelected = GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[archiveChanelId]![indexpaths][mediaTypeKey] as! String
            if let fullImage = imageDict[tImageKey]
            {
                if  GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[archiveChanelId]![indexpaths][mediaTypeKey] as! String == "video"
                {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.photoThumpCollectionView.alpha = 1.0
                        self.removeOverlay()
                        self.videoDurationLabel.hidden = false
                        self.view.bringSubviewToFront(self.videoDurationLabel)
                        self.videoDurationLabel.text = ""
                        if let vDuration =  GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[self.archiveChanelId]![indexpaths][videoDurationKey]
                        {
                            self.videoDurationLabel.text = vDuration as? String
                        }
                        self.playIconInFullView.hidden = false;
                        self.fullScrenImageView.contentMode = .ScaleAspectFill
                        if(gestureIdentifier==1||gestureIdentifier==2)
                        {
                            let animation = CATransition()
                            animation.duration = 0.2;
                            animation.type = kCATransitionMoveIn;
                            if(gestureIdentifier==1)
                            {
                                animation.subtype = kCATransitionFromRight;
                            }else{
                                animation.subtype = kCATransitionFromLeft;
                            }
                            self.fullScrenImageView.layer.addAnimation(animation, forKey: "imageTransition")
                        }
                        self.videoThumbImage = fullImage as! UIImage
                        
                        self.fullScrenImageView.image = (self.setOrientationForVideo())
                        self.fullScreenZoomView.image = (self.setOrientationForVideo())
                        
                        self.fullScreenScrollView.hidden=true;
                    })
                }
                else
                {
                    let mediaIdStr =  GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[archiveChanelId]![indexpaths][mediaIdKey]
                    let mediaIdForFilePath = "\(mediaIdStr!)full"
                    let parentPath = FileManagerViewController.sharedInstance.getParentDirectoryPath()
                    let savingPath = "\(parentPath)/\(mediaIdForFilePath )"
                    let fileExistFlag = FileManagerViewController.sharedInstance.fileExist(savingPath)
                    if fileExistFlag == true{
                        let mediaImageFromFile = FileManagerViewController.sharedInstance.getImageFromFilePath(savingPath)
                        imageForMedia = mediaImageFromFile!
                    }
                    else{
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.showOverlay()
                        })
                        let mediaUrl =  UrlManager.sharedInstance.getFullImageForMedia(mediaIdStr as! String, userName: userId, accessToken: accessToken)
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
                        var orientedImage = UIImage()
                        orientedImage = self.setGuiBasedOnOrientation(imageForMedia)
                        self.fullScrenImageView.image = orientedImage as UIImage
                        self.fullScreenZoomView.image = orientedImage as UIImage
                        self.photoThumpCollectionView.alpha = 1.0
                        self.removeOverlay()
                        if(gestureIdentifier==1||gestureIdentifier==2)
                        {
                            let animation = CATransition()
                            animation.duration = 0.2;
                            animation.type = kCATransitionMoveIn;
                            if(gestureIdentifier==1)
                            {
                                animation.subtype = kCATransitionFromRight;
                            }else{
                                animation.subtype = kCATransitionFromLeft;
                            }
                            self.fullScrenImageView.layer.addAnimation(animation, forKey: "imageTransition")
                        }
                        self.playIconInFullView.hidden = true;
                        self.fullScreenScrollView.hidden=false;
                        self.videoDurationLabel.hidden = true
                    })
                }
            }
            
            self.view.bringSubviewToFront(photoThumpCollectionView)
            self.view.bringSubviewToFront(playIconInFullView)
            self.view.bringSubviewToFront(TopView)
            self.view.bringSubviewToFront(BottomView)
        }
    }
    func setGuiBasedOnOrientation(image : UIImage) -> UIImage
    {
        self.getCurrentOrientaion()
        self.Orgimage = image
        var orientedImage = UIImage()
        
        switch self.orientationFlag
        {
        case 1:
            //portrait
            if self.Orgimage!.size.width > self.Orgimage!.size.height
            {
                self.fullScrenImageView.contentMode = .ScaleAspectFit
            }
            else{
                self.fullScrenImageView.contentMode = .ScaleAspectFill
            }
            orientedImage = self.Orgimage!
            break
            
        case 2:
            //landscape left
            if self.Orgimage!.size.width > self.Orgimage!.size.height
            {
                self.fullScrenImageView.contentMode = .ScaleAspectFit
                self.fullScrenImageView.startAnimating()
                orientedImage = UIImage(CGImage: self.Orgimage!.CGImage!, scale: CGFloat(1.0),
                                        orientation: .Right)
            }
            else{
                self.fullScrenImageView.contentMode = .ScaleAspectFit
                orientedImage = UIImage(CGImage: self.Orgimage!.CGImage!, scale: CGFloat(1.0),
                                        orientation: .Down)
            }
            break
        case 3:
            //landscape right
            if self.Orgimage!.size.width > self.Orgimage!.size.height
            {
                self.fullScrenImageView.contentMode = .ScaleAspectFit
                orientedImage = UIImage(CGImage: self.Orgimage!.CGImage!, scale: CGFloat(1.0),
                                        orientation: .Left)
            }
            else{
                self.fullScrenImageView.contentMode = .ScaleAspectFit
                orientedImage = UIImage(CGImage: self.Orgimage!.CGImage!, scale: CGFloat(1.0),
                                        orientation: .Up)
            }
            break
        default:
            break
        }
        
        return orientedImage
        
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
                catch _ as NSError {
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
        
        if(( GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[archiveChanelId]!.count > indexPath.row) && ( GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[archiveChanelId]!.count > 0))
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
            var dict =  GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[archiveChanelId]![indexPath.row]
            
            if let thumpImage = dict[tImageKey]
            {
                
                if  GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[archiveChanelId]![indexPath.row][mediaTypeKey] as! String == "video"
                {
                    cell.playIcon.hidden = false
                }
                else
                {
                    cell.playIcon.hidden = true
                }
                cell.progressView.hidden = true
                
                cell.thumbImageView.image = (thumpImage as! UIImage)
                
                let progress =  GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[archiveChanelId]![indexPath.row][progressKey] as! Float
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
        }
        self.selectedItem = indexPath.row
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.photoThumpCollectionView.reloadData()
        })
        
        if GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[archiveChanelId]!.count > indexPath.row
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
        
        if  GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[archiveChanelId]!.count > indexPath.row
        {
            self.mediaIdSelected = Int( GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[archiveChanelId]![indexPath.row][mediaIdKey] as! String)!
            let dict =  GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[archiveChanelId]![indexPath.row]
            
            let qualityOfServiceClass = QOS_CLASS_BACKGROUND
            let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
            dispatch_async(backgroundQueue, {
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


