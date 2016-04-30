//
//  OtherChannelViewController.swift
//  iONLive
//
//  Created by Gadgeon Smart Systems  on 4/15/16.
//  Copyright © 2016 Gadgeon. All rights reserved.
//

import UIKit

class OtherChannelViewController: UIViewController {
    let imageUploadManger = ImageUpload.sharedInstance
    let requestManager = RequestManager.sharedInstance
    static let identifier = "OtherChannelViewController"
    let channelIdkey = "ch_detail_id"
    let notificationKey = "notification"

    var totalMediaCount: Int = Int()
    var channelId:String!
    var channelName:String!
    var userName:String!
    
    var offset: String = "0"
    var offsetToInt : Int = Int()
    let isWatched = "isWatched"
    
    var loadingOverlay: UIView?
    var imageDataSource: [[String:AnyObject]] = [[String:AnyObject]]()
    var fullImageDataSource: [[String:AnyObject]] = [[String:AnyObject]]()
    var mediaSharedCountArray:[[String:AnyObject]] = [[String:AnyObject]]()
    
    let cameraController = IPhoneCameraViewController()
    let streamTockenKey = "wowza_stream_token" //"streamToken"

    let mediaUrlKey = "mediaUrl"
    let mediaIdKey = "mediaId"
    let mediaTypeKey = "mediaType"
    
    var limit : Int = Int()
    var fixedLimit : Int =  0
    var isLimitReached : Bool = true
    var currentLimit : Int = 0
    var limitMediaCount : Int = Int()
    let thumbImageKey = "thumbImage"
    let actualImageKey = "actualImage"

    @IBOutlet weak var channelItemsCollectionView: UICollectionView!
    @IBOutlet weak var channelTitleLabel: UILabel!
    
    var dataSource:[String]?
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        initialise()
        initialiseCloudData()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        self.tabBarItem.selectedImage = UIImage(named:"all_media_blue")?.imageWithRenderingMode(.AlwaysOriginal)
        if let channelName = channelName
        {
            channelTitleLabel.text = channelName.uppercaseString
        }
    }
    
    @IBAction func backClicked(sender: AnyObject)
    {
        
        
        let sharingStoryboard = UIStoryboard(name:"Streaming", bundle: nil)
        let sharingVC = sharingStoryboard.instantiateViewControllerWithIdentifier(StreamsGalleryViewController.identifier) as! StreamsGalleryViewController
        sharingVC.navigationController?.navigationBarHidden = true
        self.navigationController?.pushViewController(sharingVC, animated: true)
        // self.navigationController?.popViewControllerAnimated(true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
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
        
        imageUploadManger.getChannelMediaDetails(channelId , userName: userId, accessToken: accessToken, limit: String(limit), offset: offsetString, success: { (response) -> () in
            self.authenticationSuccessHandler(response)
        }) { (error, message) -> () in
            self.authenticationFailureHandler(error, code: message)
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
    func isWatchedTrue(){
        let defaults = NSUserDefaults .standardUserDefaults()
        mediaSharedCountArray = defaults.valueForKey("Shared") as! NSArray as! [[String : AnyObject]]
        
        for i in 0  ..< mediaSharedCountArray.count 
        {
            if  mediaSharedCountArray[i][channelIdkey] as! String == channelId as String
            {
                mediaSharedCountArray[i][isWatched] = "1";
                
                let defaults = NSUserDefaults .standardUserDefaults()
                defaults.setObject(mediaSharedCountArray, forKey: "Shared")
                // return
            }
        }
    }
    func authenticationSuccessHandler(response:AnyObject?)
    {
        removeOverlay()
        
        isWatchedTrue()
        if let json = response as? [String: AnyObject]
        {
            
            let responseArr = json["MediaDetail"] as! [AnyObject]
            print(responseArr)
            for index in 0 ..< responseArr.count
            {
                let mediaId = responseArr[index].valueForKey("media_detail_id")?.stringValue
                let mediaUrl = responseArr[index].valueForKey("thumbnail_name_SignedUrl") as! String
                let mediaType =  responseArr[index].valueForKey("gcs_object_type") as! String
                let actualUrl =  responseArr[index].valueForKey("gcs_object_name_SignedUrl") as! String
                var notificationType : String = String()
                if let notifType =  responseArr[index].valueForKey("notification_type") as? String
                {
                    print(notifType)
                    if notifType != ""
                    {
                        notificationType = (notifType as? String)!.lowercaseString
                    }
                    else{
                        notificationType = "shared"
                    }
                }
                else{
                    notificationType = "shared"
                }
                
                imageDataSource.append([mediaIdKey:mediaId!, mediaUrlKey:mediaUrl, mediaTypeKey:mediaType,actualImageKey:actualUrl,notificationKey:notificationType])
            }
            //    imageDataSource.append([mediaIdKey:mediaId!, mediaUrlKey:mediaUrl, mediaTypeKey:mediaType])
            
        
            let responseArrLive = json["LiveDetail"] as! [AnyObject]
            print(responseArrLive)

            for index in 0 ..< responseArrLive.count
            {
                let streamTocken = responseArrLive[index].valueForKey("wowza_stream_token")as! String

                let mediaUrl = responseArrLive[index].valueForKey("signedUrl") as! String
//                let mediaType =  responseArrLive[index].valueForKey("gcs_object_type") as! String
                if(mediaUrl != ""){
                    let url: NSURL = convertStringtoURL(mediaUrl)
                    downloadMedia(url, key: "ThumbImage", completion: { (result) -> Void in
                        self.fullImageDataSource.append([self.mediaIdKey:"", self.mediaUrlKey:mediaUrl, self.thumbImageKey:result ,self.streamTockenKey:streamTocken,self.actualImageKey:self.imageDataSource[index][self.actualImageKey]!,self.notificationKey:self.imageDataSource[index][self.notificationKey]!,self.mediaTypeKey:"live"])
//                         self.fullImageDataSource.append([self.mediaIdKey:"", self.mediaUrlKey:result, self.mediaTypeKey:self.imageDataSource[i][self.mediaTypeKey]!,self.thumbImageKey:result,self.actualImageKey:self.imageDataSource[i][self.actualImageKey]!,self.notificationKey:self.imageDataSource[i][self.notificationKey]!])
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.channelItemsCollectionView.reloadData()
                        })
                    })
                }

             
                

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
            
            var imageForMedia : UIImage = UIImage()
            let mediaIdForFilePath = "\(imageDataSource[i][mediaIdKey] as! String)thumb"
            print(mediaIdForFilePath)
            let fileExistFlag = FileManagerViewController.sharedInstance.fileExist(mediaIdForFilePath)
            if fileExistFlag == true{
                let mediaImageFromFile = FileManagerViewController.sharedInstance.getImageFromFilePath(mediaIdForFilePath)
                imageForMedia = mediaImageFromFile!
            }
            else{
                let mediaUrl = imageDataSource[i][mediaUrlKey] as! String
                if(mediaUrl != ""){
                    let url: NSURL = convertStringtoURL(mediaUrl)
                    downloadMedia(url, key: "ThumbImage", completion: { (result) -> Void in
                        FileManagerViewController.sharedInstance.saveImageToFilePath(mediaIdForFilePath, mediaImage: result)
                        if(result != UIImage()){
                            imageForMedia = result
                        }
                        else{
                            imageForMedia = UIImage()
                        }
                    })
                    
                }
            }
      
                    
//                    self.fullImageDataSource.append([self.mediaIdKey:self.imageDataSource[i][self.mediaIdKey]!,self.mediaUrlKey:self.imageDataSource[i][self.mediaUrlKey]!, self.thumbImageKey:result,self.streamTockenKey:"", self.mediaTypeKey:self.imageDataSource[i][self.mediaTypeKey]!])
          
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                
                self.fullImageDataSource.append([self.mediaIdKey:self.imageDataSource[i][self.mediaIdKey]!, self.mediaUrlKey:imageForMedia, self.mediaTypeKey:self.imageDataSource[i][self.mediaTypeKey]!,self.thumbImageKey:imageForMedia,self.actualImageKey:self.imageDataSource[i][self.actualImageKey]!,self.streamTockenKey:"",self.notificationKey:self.imageDataSource[i][self.notificationKey]!])
                
                        self.channelItemsCollectionView.reloadData()
            })
        }
        
    }
}

extension OtherChannelViewController : UIScrollViewDelegate{
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let fullyScrolledContentOffset:CGFloat = channelItemsCollectionView.frame.size.width
        
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
    
    func loadLiveStreamView(streamTocken:String)
    {
        let vc = MovieViewController.movieViewControllerWithContentPath("rtsp://104.196.15.240:1935/live/\(streamTocken)", parameters: nil , liveVideo: false) as! UIViewController
        
        self.presentViewController(vc, animated: true) { () -> Void in
            
        }
    }
    
}

extension OtherChannelViewController : UICollectionViewDataSource,UICollectionViewDelegateFlowLayout
{
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        if fullImageDataSource.count > 0
        {
            return fullImageDataSource.count
        }
        else
        {
            return 0
        }
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
    {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("OtherChannelCell", forIndexPath: indexPath) as! OtherChannelCell
        
       // cell.videoView.alpha = 0.4
        if fullImageDataSource.count > 0
        {
            let mediaType = fullImageDataSource[indexPath.row][mediaTypeKey] as! String
          //  let channelImageView = cell.viewWithTag(100) as! UIImageView
            let imageData =  fullImageDataSource[indexPath.row][thumbImageKey] as! UIImage
            if mediaType == "video"
            {
                cell.detailLabel.hidden = false
                cell.detailLabel.text = ""
                cell.videoView.hidden = false
                cell.videoView.image = UIImage(named: "Live_now_off_mode")
                let imageToConvert: UIImage = imageData
                                let sizeThumb = CGSizeMake(150, 150)
                                let imageAfterConversionThumbnail = cameraController.thumbnaleImage(imageToConvert, scaledToFillSize: sizeThumb)

                cell.channelMediaImage.image = imageAfterConversionThumbnail
            }
            else if mediaType == "image" {
                cell.detailLabel.hidden = true
                cell.videoView.hidden = true
                cell.channelMediaImage.image = imageData
            }
            else{
                cell.detailLabel.hidden = false
                cell.detailLabel.text = "LIVE"
                cell.videoView.hidden = false
                cell.videoView.image = UIImage(named: "Live_now")
                cell.channelMediaImage.image = UIImage(named: "thumb1")
            }
          //  cell.insertSubview(cell.videoView, aboveSubview: cell.channelMediaImage)
        }
        return cell
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
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let userId = userName
        let type = fullImageDataSource[indexPath.row][mediaTypeKey] as! String
        if type == "image"
        {
            
            
            let vc = MovieViewController.movieViewControllerWithImageVideo(fullImageDataSource[indexPath.row][actualImageKey] as! String, channelName: channelName, userName: userId, mediaType: fullImageDataSource[indexPath.row][mediaTypeKey] as! String, profileImage: UIImage(),videoImageUrl:self.fullImageDataSource[indexPath.row][mediaUrlKey] as! UIImage, notifType: fullImageDataSource[indexPath.row][notificationKey] as! String, mediaId: fullImageDataSource[indexPath.row][mediaIdKey] as! String) as! MovieViewController

           self.presentViewController(vc, animated: true) { () -> Void in
            }

        }else if type == "video"
        {
            let vc = MovieViewController.movieViewControllerWithImageVideo(fullImageDataSource[indexPath.row][actualImageKey] as! String, channelName: channelName, userName: userId, mediaType: fullImageDataSource[indexPath.row][mediaTypeKey] as! String, profileImage: UIImage(),videoImageUrl:self.fullImageDataSource[indexPath.row][mediaUrlKey] as! UIImage, notifType: fullImageDataSource[indexPath.row][notificationKey] as! String, mediaId: fullImageDataSource[indexPath.row][mediaIdKey] as! String) as! MovieViewController
            
            self.presentViewController(vc, animated: true) { () -> Void in
            }

//            let vc = MovieViewController.movieViewControllerWithImageVideo(fullImageDataSource[indexPath.row][actualImageKey] as! String, channelName: channelName, userName: userId, mediaType: fullImageDataSource[indexPath.row][mediaTypeKey] as! String, profileImage: UIImage(), notifType: fullImageDataSource[indexPath.row][notificationKey] as! String, mediaId: fullImageDataSource[indexPath.row][mediaIdKey] as! String) as! MovieViewController
//            self.presentViewController(vc, animated: true) { () -> Void in
//            }
   
        }else
        {
            if let streamTocken = fullImageDataSource[indexPath.row][streamTockenKey]
            {
                self.loadLiveStreamView(streamTocken as! String)
            }
            else
            {
                ErrorManager.sharedInstance.alert("Streaming error", message: "Not a valid stream tocken")
            }
        }
        
    }
    
    
}
