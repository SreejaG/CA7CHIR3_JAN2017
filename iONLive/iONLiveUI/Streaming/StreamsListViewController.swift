//
//  StreamsListViewController.swift
//  iON_Live
//
//  Created by Gadgeon on 11/18/15.
//  Copyright © 2015 Gadgeon. All rights reserved.
//

import UIKit

class StreamsListViewController: UIViewController{
    
    let streamTockenKey = "wowza_stream_token" //"streamToken"
    let imageKey = "image"
    let typeKey = "type"
    let imageType = "imageType"
    static let identifier = "StreamsListViewController"
    let imageUploadManger = ImageUpload.sharedInstance

    var totalMediaCount: Int = Int()
    var channelId:String!
    var channelName:String!
    
    var offset: String = "0"
    var offsetToInt : Int = Int()
    let isWatched = "isWatched"
    
    var loadingOverlay: UIView?
    var imageDataSource: [[String:AnyObject]] = [[String:AnyObject]]()
    var fullImageDataSource: [[String:AnyObject]] = [[String:AnyObject]]()
    var mediaSharedCountArray:[[String:AnyObject]] = [[String:AnyObject]]()
    
    let cameraController = IPhoneCameraViewController()
    
    let mediaUrlKey = "mediaUrl"
    let mediaIdKey = "mediaId"
    let mediaTypeKey = "mediaType"
    
    var limit : Int = Int()
    var fixedLimit : Int =  0
    var isLimitReached : Bool = true
    var currentLimit : Int = 0
    var limitMediaCount : Int = Int()

    //var loadingOverlay: UIView?
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    let livestreamingManager = LiveStreamingManager()
    let requestManager = RequestManager()
    var dataSource:[[String:String]]?
    var refreshControl:UIRefreshControl!
    var pullToRefreshActive = false
    
    //for temp image along with streams and stream thumbanes
    var dummyImagesArray:[String] = ["thumb1","thumb2","thumb3","thumb4","thumb5","thumb6" , "thumb7","thumb8","thumb9","thumb10","thumb11","thumb12"]
    var dummyImageListingDataSource = [[String:String]]()
    
    @IBOutlet weak var streamListCollectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.refreshControl = UIRefreshControl()
        self.refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        self.refreshControl.addTarget(self, action: "pullToRefresh", forControlEvents: UIControlEvents.ValueChanged)
        self.streamListCollectionView.addSubview(refreshControl)
        self.streamListCollectionView.alwaysBounceVertical = true
        self.view.bringSubviewToFront(activityIndicator)
        initialise()
        initialiseCloudData()
//        dummyImageListingDataSource = [[imageKey:dummyImagesArray[0],typeKey:imageType],[imageKey:dummyImagesArray[1],typeKey:imageType],[imageKey:dummyImagesArray[2],typeKey:imageType],[imageKey:dummyImagesArray[3],typeKey:imageType],[imageKey:dummyImagesArray[4],typeKey:imageType],[imageKey:dummyImagesArray[5],typeKey:imageType],[imageKey:dummyImagesArray[6],typeKey:imageType],[imageKey:dummyImagesArray[7],typeKey:imageType],[imageKey:dummyImagesArray[8],typeKey:imageType],[imageKey:dummyImagesArray[9],typeKey:imageType],[imageKey:dummyImagesArray[10],typeKey:imageType],[imageKey:dummyImagesArray[11],typeKey:imageType]]
//        self.dataSource = dummyImageListingDataSource
//        getAllLiveStreams()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        self.navigationController?.navigationBarHidden = true
        activityIndicator.hidden = true
        self.view.bringSubviewToFront(activityIndicator)
        
        self.tabBarItem.selectedImage = UIImage(named:"all_media_blue")?.imageWithRenderingMode(.AlwaysOriginal)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //    override func viewWillDisappear(animated: Bool) {
    //
    //        if let viewControllers = self.navigationController?.viewControllers as [UIViewController]! {
    //
    //            if viewControllers.contains(self) == false{
    //
    //                let vc:MovieViewController = self.navigationController?.topViewController as! MovieViewController
    //
    //                vc.initialiseDecoder()
    //            }
    //        }
    //    }
    
    
    
    
    func initialise()
    {
        //  channelId = (self.tabBarController as! //MyChannelDetailViewController).channelId
        //  channelName = (self.tabBarController as! MyChannelDetailViewController).channelName
        //  totalMediaCount = (self.tabBarController as! MyChannelDetailViewController).totalMediaCount
        if totalMediaCount > 6
        {
            fixedLimit = 6
        }
        else{
            fixedLimit = totalMediaCount
        }
        
        limit = totalMediaCount
        
        imageDataSource.removeAll()
        fullImageDataSource.removeAll()
        offsetToInt = Int(offset)!
    }
    
    func initialiseCloudData(){
        
        let defaults = NSUserDefaults .standardUserDefaults()
        let userId = defaults.valueForKey(userLoginIdKey) as! String
        let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
        showOverlay()
        
        let offsetString : String = String(offsetToInt)
      //  print(channelId)
        imageUploadManger.getSubscribedChannelMediaDetails(userId, accessToken: accessToken, limit: String(limit), offset: offsetString, success: { (response) in
            self.authenticationSuccessHandler(response)
            }) { (error, message) in
                self.authenticationFailureHandler(error, code: message)
        }
        
        
        
//        getChannelMediaDetails(channelId , userName: userId, accessToken: accessToken, limit: String(limit), offset: offsetString, success: { (response) -> () in
//            self.authenticationSuccessHandler(response)
//        }) { (error, message) -> () in
//            self.authenticationFailureHandler(error, code: message)
//        }
    }
    func authenticationSuccessHandler(response:AnyObject?)
    {
        removeOverlay()
        if let json = response as? [String: AnyObject]
        {
            let responseArr = json["objectJson"] as! [AnyObject]
            
            print(responseArr)
            for index in 0 ..< responseArr.count
            {
                let mediaId = responseArr[index].valueForKey("media_detail_id")?.stringValue
                let mediaUrl = responseArr[index].valueForKey("thumbnail_name_SignedUrl") as! String
                let mediaType =  responseArr[index].valueForKey("gcs_object_type") as! String
                imageDataSource.append([mediaIdKey:mediaId!, mediaUrlKey:mediaUrl, mediaTypeKey:mediaType])
            }
            
            
            print(responseArr)
            downloadCloudData(15, scrolled: false)
        }
        else
        {
            ErrorManager.sharedInstance.inValidResponseError()
        }
    }
    
    func authenticationFailureHandler(error: NSError?, code: String)
    {
        removeOverlay()
        if(offsetToInt <= totalMediaCount){
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
            completion(result: UIImage(data: imageData)!)
        }
        else
        {
            print("null Image")
            completion(result:mediaImage)
        }
    }
    func downloadCloudData(limitMedia : Int , scrolled : Bool)
    {
        
        if(imageDataSource.count <  (currentLimit +  limitMedia))
        {
            limitMediaCount = currentLimit
            currentLimit = currentLimit + (imageDataSource.count - currentLimit)
            isLimitReached = false
        }
        else if (imageDataSource.count > (currentLimit +  limitMedia))
        {
            limitMediaCount = currentLimit
            let count = imageDataSource.count - currentLimit
            if count > 15
            {
                currentLimit = currentLimit + 15
            }
            else{
                currentLimit = currentLimit + count
            }
            isLimitReached = true
        }
        else if(currentLimit == imageDataSource.count)
        {
            isLimitReached = false
            return
        }
        
        for i in limitMediaCount  ..< currentLimit
        {
            let mediaUrl = imageDataSource[i][mediaUrlKey] as! String
            if(mediaUrl != ""){
                let url: NSURL = convertStringtoURL(mediaUrl)
                downloadMedia(url, key: "ThumbImage", completion: { (result) -> Void in
                    self.fullImageDataSource.append([self.mediaIdKey:self.imageDataSource[i][self.mediaIdKey]!, self.mediaUrlKey:result, self.mediaTypeKey:self.imageDataSource[i][self.mediaTypeKey]!])
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.streamListCollectionView.reloadData()
                    })
                })
                
            }
        }
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
    func loadLiveStreamView(streamTocken:String)
    {
        let vc = MovieViewController.movieViewControllerWithContentPath("rtsp://104.196.15.240:1935/live/\(streamTocken)", parameters: nil , liveVideo: false) as! UIViewController
        
        self.presentViewController(vc, animated: true) { () -> Void in
            
        }
    }
    
    func pullToRefresh()
    {
        pullToRefreshActive = true
        getAllLiveStreams()
    }
    
    //PRAGMA MARK:- API Handlers
    func getAllLiveStreams()
    {
        let userDefault = NSUserDefaults.standardUserDefaults()
        let loginId = userDefault.objectForKey(userLoginIdKey)
        let accessTocken = userDefault.objectForKey(userAccessTockenKey)
        
        if let loginId = loginId, let accessTocken = accessTocken
        {
            if pullToRefreshActive == false
            {
              //  activityIndicator.hidden = false
            }
            else
            {
              //  activityIndicator.hidden = true
            }
            
            livestreamingManager.getAllLiveStreams(loginId:loginId as! String , accesstocken:accessTocken as! String ,success: { (response) -> () in
                self.getAllStreamSuccessHandler(response)
                }, failure: { (error, message) -> () in
                    self.getAllStreamFailureHandler(error, message: message)
                    return
            })
        }
        else
        {
            ErrorManager.sharedInstance.authenticationIssue()
        }
    }
    
    
    func getAllStreamSuccessHandler(response:AnyObject?)
    {
        activityIndicator.hidden = true
        self.refreshControl.endRefreshing()
        pullToRefreshActive = false
        if let json = response as? [String: AnyObject]
        {
            print("success = \(json["liveStreams"])")
            let liveStreamDataSource = json["liveStreams"] as? [[String:String]]
            self.createDataSource(liveStreamDataSource)
            self.streamListCollectionView.reloadData()
        }
        else
        {
            ErrorManager.sharedInstance.inValidResponseError()
        }
    }
    
    func getAllStreamFailureHandler(error: NSError?, message: String)
    {
        activityIndicator.hidden = true
        self.refreshControl.endRefreshing()
        pullToRefreshActive = false
        // self.streamListCollectionView.reloadData()
        print("message = \(message)")
        
        if !self.requestManager.validConnection() {
            //clearing all live streams
            loadStaticImagesOnly()
            ErrorManager.sharedInstance.noNetworkConnection()
        }
        else if message.isEmpty == false
        {
            if message == "WOWZA001"  // live stream list empty
            {
                loadStaticImagesOnly()
            }
            else
            {
                ErrorManager.sharedInstance.mapErorMessageToErrorCode(message)
            }
        }
        else{
            ErrorManager.sharedInstance.liveStreamFetchingError()
        }
    }
    
    func loadStaticImagesOnly()
    {
        self.dataSource = dummyImageListingDataSource
        self.streamListCollectionView.reloadData()
    }
    
    @IBAction func customBackButtonClicked(sender: AnyObject)
    {
        let cameraViewStoryboard = UIStoryboard(name:"IPhoneCameraView" , bundle: nil)
        let iPhoneCameraVC = cameraViewStoryboard.instantiateViewControllerWithIdentifier("IPhoneCameraViewController") as! IPhoneCameraViewController
        iPhoneCameraVC.navigationController?.navigationBarHidden = true
        self.navigationController?.pushViewController(iPhoneCameraVC, animated: false)
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent;
    }
    
    //PRAGMA MARK:- dummy image helper functions
    
    func createDataSource(liveStreamDataSource:[[String:String]]?)
    {
        self.dataSource = dummyImageListingDataSource
        if let liveStreams = liveStreamDataSource
        {
            var count = 0
            for eachLiveStream in liveStreams
            {
                if dataSource?.count > count
                {
                    dataSource?[count] = eachLiveStream
                    count = count + 1
                }
            }
        }
    }
}

extension StreamsListViewController : UIScrollViewDelegate{
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let fullyScrolledContentOffset:CGFloat = streamListCollectionView.frame.size.width
        
        if (scrollView.contentOffset.x >= fullyScrolledContentOffset)
        {
            if(scrollView.contentOffset.x == fullyScrolledContentOffset)
            {
                print("End of scroll view")
                
            }
            
        }
        if offsetY > contentHeight - scrollView.frame.size.height {
            
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
            
        }
    }
    
    
    
}


extension StreamsListViewController:UICollectionViewDataSource,UICollectionViewDelegateFlowLayout
{
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        if let dataSource = dataSource
        {
            return dataSource.count
        }
        else
        {
            return 0
        }
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("StreamListCollectionViewCell", forIndexPath: indexPath) as! StreamListCollectionViewCell
        
        //cell for live streams
        
        if let dataSource = dataSource
        {
            if dataSource.count > indexPath.row
            {
                //image stream cell
                var dict = dataSource[indexPath.row]
                if let streamType = dict[typeKey]
                {
                    if streamType == imageType
                    {
                        cell.liveStatusLabel.hidden = true
                        cell.liveNowIcon.hidden = true
                        if let imageName = dict[imageKey]
                        {
                            cell.streamThumbnaleImageView.image = UIImage(named: imageName)
                        }
                    }
                }
                else   //live stream cell
                {
                    cell.liveStatusLabel.hidden = false
                    cell.liveNowIcon.hidden = false
                    
                    var imageIndexPath = 0
                    if dummyImagesArray.count > indexPath.row
                    {
                        imageIndexPath = indexPath.row
                    }
                    cell.streamThumbnaleImageView.image = UIImage(named: dummyImagesArray[imageIndexPath])
                }
            }
        }
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath)
    {
        if let dataSource = dataSource
        {
            if dataSource.count > indexPath.row
            {
                var dict = dataSource[indexPath.row]
                if let _ = dict[typeKey]
                {
                    //not clickable as of now
                }
                else
                {
                    //live stream click
                    if let streamTocken = dict[streamTockenKey]
                    {
                        self.loadLiveStreamView(streamTocken)
                    }
                    else
                    {
                        ErrorManager.sharedInstance.alert("Streaming error", message: "Not a valid stream tocken")
                    }
                }
            }
        }
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(1, 1, 0, 1)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize
    {
        return CGSizeMake((UIScreen.mainScreen().bounds.width/3)-2, 100)
    }
}

