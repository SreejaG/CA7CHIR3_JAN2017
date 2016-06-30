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
    let channelManager = ChannelManager.sharedInstance
    static let identifier = "OtherChannelViewController"
    let channelIdkey = "ch_detail_id"
    let notificationKey = "notification"
    let channelNameKey = "channel_name"
    let userIdKey = "user_name"
    
    var totalMediaCount: Int = Int()
    var channelId:String!
    var channelName:String!
    var userName:String!
    var profileImage : UIImage!
    var offset: String = "0"
    var offsetToInt : Int = Int()
    let isWatched = "isWatched"
    
    var loadingOverlay: UIView?
    var imageDataSource: [[String:AnyObject]] = [[String:AnyObject]]()
    var fullImageDataSource: [[String:AnyObject]] = [[String:AnyObject]]()
    var mediaSharedCountArray:[[String:AnyObject]] = [[String:AnyObject]]()
    
    let cameraController = IPhoneCameraViewController()
    let streamTockenKey = "wowza_stream_token"
    
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
        channelItemsCollectionView.alpha = 1.0
        self.tabBarItem.selectedImage = UIImage(named:"all_media_blue")?.imageWithRenderingMode(.AlwaysOriginal)
        if let channelName = channelName
        {
            channelTitleLabel.text = channelName.uppercaseString
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(true)
//        removeOverlay()
        channelItemsCollectionView.alpha = 1.0
    }
    
    @IBAction func backClicked(sender: AnyObject)
    {
        let sharingStoryboard = UIStoryboard(name:"Streaming", bundle: nil)
        let sharingVC = sharingStoryboard.instantiateViewControllerWithIdentifier(StreamsGalleryViewController.identifier) as! StreamsGalleryViewController
        sharingVC.navigationController?.navigationBarHidden = true
        self.navigationController?.pushViewController(sharingVC, animated: false)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func initialise()
    {
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
    
    func showOverlay(){
        let loadingOverlayController:IONLLoadingView=IONLLoadingView(nibName:"IONLLoadingOverlay", bundle: nil)
        loadingOverlayController.view.frame = CGRectMake(0, 64, self.view.frame.width, self.view.frame.height - 64)
        loadingOverlayController.startLoading()
        self.loadingOverlay = loadingOverlayController.view
        self.view .addSubview(self.loadingOverlay!)
//        self.navigationController?.view.addSubview(self.loadingOverlay!)
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
            }
        }
    }
    
    func authenticationSuccessHandler(response:AnyObject?)
    {
//        removeOverlay()
        isWatchedTrue()
        if let json = response as? [String: AnyObject]
        {
            let responseArr = json["MediaDetail"] as! [AnyObject]
         
            for index in 0 ..< responseArr.count
            {
                let mediaId = responseArr[index].valueForKey("media_detail_id")?.stringValue
                let mediaUrl = responseArr[index].valueForKey("thumbnail_name_SignedUrl") as! String
                let mediaType =  responseArr[index].valueForKey("gcs_object_type") as! String
                let actualUrl =  responseArr[index].valueForKey("gcs_object_name_SignedUrl") as! String
                var notificationType : String = String()
                let time = responseArr[index].valueForKey("created_time_stamp") as! String
                if let notifType =  responseArr[index].valueForKey("notification_type") as? String
                {
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
                
                imageDataSource.append([mediaIdKey:mediaId!, mediaUrlKey:mediaUrl, mediaTypeKey:mediaType,actualImageKey:actualUrl,notificationKey:notificationType,"createdTime":time])
            }
            let responseArrLive = json["LiveDetail"] as! [AnyObject]
         
            for index in 0 ..< responseArrLive.count
            {
                
                let streamTocken = responseArrLive[index].valueForKey("wowza_stream_token")as! String
                let mediaUrl = responseArrLive[index].valueForKey("signedUrl") as! String
                let mediaId = responseArrLive[index].valueForKey("live_stream_detail_id")?.stringValue
                if(mediaUrl != ""){
                    let url: NSURL = convertStringtoURL(mediaUrl)
                    downloadMedia(url, key: "ThumbImage", completion: { (result) -> Void in
                        self.fullImageDataSource.append([self.mediaIdKey:mediaId!, self.mediaUrlKey:mediaUrl, self.thumbImageKey:result ,self.streamTockenKey:streamTocken,self.actualImageKey:mediaUrl,self.notificationKey:self.imageDataSource[index][self.notificationKey]!,self.mediaTypeKey:"live", self.userIdKey:self.userName, self.channelNameKey:self.channelName])
                        self.channelItemsCollectionView.reloadData()
                    })
                }
            }
            
            if(imageDataSource.count > 0){
                let qualityOfServiceClass = QOS_CLASS_BACKGROUND
                let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
                dispatch_async(backgroundQueue, {
                    self.downloadMediaFromGCS()
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.channelItemsCollectionView.reloadData()
                    })
                })
            }
            
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
//                ErrorManager.sharedInstance.mapErorMessageToErrorCode(code)
                if((code == "USER004") || (code == "USER005") || (code == "USER006")){
                    loadInitialViewController(code)
                }
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
    func downloadMediaFromGCS(){
        for var i = 0; i < imageDataSource.count; i++
        {
            
            var imageForMedia : UIImage = UIImage()
            let mediaIdForFilePath = "\(imageDataSource[i][mediaIdKey] as! String)thumb"
            let parentPath = FileManagerViewController.sharedInstance.getParentDirectoryPath()
            let savingPath = "\(parentPath)/\(mediaIdForFilePath)"
            let fileExistFlag = FileManagerViewController.sharedInstance.fileExist(savingPath)
            if fileExistFlag == true{
                let mediaImageFromFile = FileManagerViewController.sharedInstance.getImageFromFilePath(savingPath)
                imageForMedia = mediaImageFromFile!
            }
            else{
                let mediaUrl = imageDataSource[i][mediaUrlKey] as! String
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
            self.fullImageDataSource.append([self.mediaIdKey:self.imageDataSource[i][self.mediaIdKey]!, self.mediaUrlKey:imageForMedia, self.mediaTypeKey:self.imageDataSource[i][self.mediaTypeKey]!,self.thumbImageKey:imageForMedia,self.actualImageKey:self.imageDataSource[i][self.actualImageKey]!,self.streamTockenKey:"",self.notificationKey:self.imageDataSource[i][self.notificationKey]!,"createdTime":self.imageDataSource[i]["createdTime"] as! String])
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
               self.removeOverlay()
                self.channelItemsCollectionView.reloadData()
            })
            
            
        }
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
            completion(result:UIImage(named:"thumb12")!)
        }
    }
    
    
    func  didSelectExtension(indexPathRow: Int)
    {
          getLikeCountForSelectedIndex(indexPathRow)
    }
    
    func getLikeCountForSelectedIndex(indexpathRow:Int)  {
        let mediaId = fullImageDataSource[indexpathRow][mediaIdKey] as! String
        getLikeCount(mediaId, indexpathRow: indexpathRow)
    }
    
    func getLikeCount(mediaId: String,indexpathRow:Int) {
        let defaults = NSUserDefaults .standardUserDefaults()
        let userId = defaults.valueForKey(userLoginIdKey) as! String
        let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
        let mediaTypeSelected : String = fullImageDataSource[indexpathRow][mediaTypeKey] as! String
        print(mediaTypeSelected)
        channelManager.getMediaLikeCountDetails(userId, accessToken: accessToken, mediaId: mediaId, mediaType: mediaTypeSelected, success: { (response) in
                self.successHandlerForMediaCount(response,indexpathRow:indexpathRow)
            }, failure: { (error, message) -> () in
                self.failureHandlerForMediaCount(error, code: message,indexPathRow:indexpathRow)
                return
        })
    }
    
    var likeCountSelectedIndex : String = "0"
    func successHandlerForMediaCount(response:AnyObject?,indexpathRow:Int)
    {
        if let json = response as? [String: AnyObject]
        {
            likeCountSelectedIndex = json["likeCount"] as! String
        }
        loadmovieViewController(indexpathRow, likeCount: likeCountSelectedIndex)
    }
    
    func failureHandlerForMediaCount(error: NSError?, code: String,indexPathRow:Int)
    {
        likeCountSelectedIndex = "0"
        loadmovieViewController(indexPathRow, likeCount: likeCountSelectedIndex)
    }
    
    func loadmovieViewController(indexPathRow:Int,likeCount:String) {
        
        self.removeOverlay()
        channelItemsCollectionView.alpha = 1.0
        let defaults = NSUserDefaults .standardUserDefaults()
        let type = fullImageDataSource[indexPathRow][mediaTypeKey] as! String
        if((type ==  "image") || (type == "video"))
        {
            let dateString = self.fullImageDataSource[indexPathRow]["createdTime"] as! String
            let imageTakenTime = FileManagerViewController.sharedInstance.getTimeDifference(dateString)
            
            let vc = MovieViewController.movieViewControllerWithImageVideo(self.fullImageDataSource[indexPathRow][self.actualImageKey] as! String, channelName: self.channelName,channelId: self.channelId as String, userName: userName, mediaType: self.fullImageDataSource[indexPathRow][self.mediaTypeKey] as! String, profileImage:self.profileImage,videoImageUrl:self.fullImageDataSource[indexPathRow][self.mediaUrlKey] as! UIImage, notifType: self.fullImageDataSource[indexPathRow][self.notificationKey] as! String, mediaId: self.fullImageDataSource[indexPathRow][self.mediaIdKey] as! String,timeDiff: imageTakenTime,likeCountStr: likeCount) as! MovieViewController
            self.presentViewController(vc, animated: false) { () -> Void in
            }
        }
        else
        {
            let streamTocken = self.fullImageDataSource[indexPathRow][self.streamTockenKey] as! String
            if streamTocken != ""
            {
                let parameters : NSDictionary = ["channelName": self.channelName, "userName":userName ,    "mediaType":type, "profileImage":self.profileImage, "notifType":self.fullImageDataSource[indexPathRow][self.notificationKey] as! String, "mediaId": self.fullImageDataSource[indexPathRow][self.mediaIdKey] as! String,"channelId":self.channelId, "likeCount":likeCount as! String]
                let vc = MovieViewController.movieViewControllerWithContentPath("rtsp://130.211.135.170:1935/live/\(streamTocken)", parameters: parameters as! [NSObject : AnyObject] , liveVideo: false) as! UIViewController
                
                self.presentViewController(vc, animated: false) { () -> Void in
                }
            }
            else
            {
                ErrorManager.sharedInstance.alert("Streaming error", message: "Not a valid stream tocken")
            }
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
        
        if fullImageDataSource.count > 0
        {
            let mediaType = fullImageDataSource[indexPath.row][mediaTypeKey] as! String
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
                cell.channelMediaImage.image = imageData
            }
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
        if  fullImageDataSource.count>0
        {
            if fullImageDataSource.count > indexPath.row
            {
                let userId = userName
                let type = fullImageDataSource[indexPath.row][mediaTypeKey] as! String
                showOverlay()
                channelItemsCollectionView.alpha = 0.4
                didSelectExtension(indexPath.row)
                
                
//                let dateString = self.fullImageDataSource[indexPath.row]["createdTime"] as! String
//                let imageTakenTime = FileManagerViewController.sharedInstance.getTimeDifference(dateString)
//                dispatch_async(dispatch_get_main_queue(), { () -> Void in
//                if type == "image"
//                {
//                    let vc = MovieViewController.movieViewControllerWithImageVideo(self.fullImageDataSource[indexPath.row][self.actualImageKey] as! String, channelName: self.channelName,channelId: self.channelId as String, userName: userId, mediaType: self.fullImageDataSource[indexPath.row][self.mediaTypeKey] as! String, profileImage:self.profileImage,videoImageUrl:self.fullImageDataSource[indexPath.row][self.mediaUrlKey] as! UIImage, notifType: self.fullImageDataSource[indexPath.row][self.notificationKey] as! String, mediaId: self.fullImageDataSource[indexPath.row][self.mediaIdKey] as! String,timeDiff: imageTakenTime,likeCountStr: "0") as! MovieViewController
//                    self.presentViewController(vc, animated: false) { () -> Void in
//                        self.removeOverlay()
//                        self.channelItemsCollectionView.alpha = 1.0
//                    }
//                }else if type == "video"
//                {
//                    let vc = MovieViewController.movieViewControllerWithImageVideo(self.fullImageDataSource[indexPath.row][self.actualImageKey] as! String, channelName: self.channelName, channelId: self.channelId as String, userName: userId, mediaType: self.fullImageDataSource[indexPath.row][self.mediaTypeKey] as! String, profileImage: self.profileImage,videoImageUrl:self.fullImageDataSource[indexPath.row][self.mediaUrlKey] as! UIImage, notifType: self.fullImageDataSource[indexPath.row][self.notificationKey] as! String, mediaId: self.fullImageDataSource[indexPath.row][self.mediaIdKey] as! String,timeDiff: imageTakenTime,likeCountStr: "0") as! MovieViewController
//            
//                    self.presentViewController(vc, animated: false) { () -> Void in
//                        self.removeOverlay()
//                        self.channelItemsCollectionView.alpha = 1.0
//                    }
//                }else
//                {
//                    if let streamTocken = self.fullImageDataSource[indexPath.row][self.streamTockenKey]
//                    {
//                        let userId = self.userName
//                        let type = self.fullImageDataSource[indexPath.row][self.mediaTypeKey] as! String
//                
//                        let parameters : NSDictionary = ["channelName": self.channelName, "userName":userId ,    "mediaType":type, "profileImage":self.profileImage, "notifType":self.fullImageDataSource[indexPath.row][self.notificationKey] as! String, "mediaId": self.fullImageDataSource[indexPath.row][self.mediaIdKey] as! String,"channelId":self.channelId]
//                        let vc = MovieViewController.movieViewControllerWithContentPath("rtsp://130.211.135.170:1935/live/\(streamTocken)", parameters: parameters as! [NSObject : AnyObject] , liveVideo: false) as! UIViewController
//                
//                        self.presentViewController(vc, animated: false) { () -> Void in
//                            self.removeOverlay()
//                            self.channelItemsCollectionView.alpha = 1.0
//                        }
//                    }
//                    else
//                    {
//                        self.removeOverlay()
//                        self.channelItemsCollectionView.alpha = 1.0
//                        ErrorManager.sharedInstance.alert("Streaming error", message: "Not a valid stream tocken")
//                    }
//                }
//                })
           }
        }
    }
}
