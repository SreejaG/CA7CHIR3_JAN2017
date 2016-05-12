//
//  MyChannelItemDetailsViewController.swift
//  iONLive
//
//  Created by Gadgeon on 12/23/15.
//  Copyright © 2015 Gadgeon. All rights reserved.
//

import UIKit

class MyChannelItemDetailsViewController: UIViewController {
    
    let imageUploadManger = ImageUpload.sharedInstance
    let requestManager = RequestManager.sharedInstance
    
    var totalMediaCount: Int = Int()
    var channelId:String!
    var channelName:String!
    
    var offset: String = "0"
    var offsetToInt: Int = Int()
    
    var loadingOverlay: UIView?
    var imageDataSource: [[String:AnyObject]] = [[String:AnyObject]]()
    var fullImageDataSource: [[String:AnyObject]] = [[String:AnyObject]]()
    
    let cameraController = IPhoneCameraViewController()
    
    let mediaUrlKey = "mediaUrl"
    let mediaIdKey = "mediaId"
    let mediaTypeKey = "mediaType"
    let actualImageKey = "actualImage"
    let notificationKey = "notification"
    
    var limit : Int = Int()
    var fixedLimit : Int =  0
    var isLimitReached : Bool = true
    var currentLimit : Int = 0
    var limitMediaCount : Int = Int()
    
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
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(true)
        removeOverlay()
    }
    
    @IBAction func backClicked(sender: AnyObject)
    {
        let sharingStoryboard = UIStoryboard(name:"sharing", bundle: nil)
        let sharingVC = sharingStoryboard.instantiateViewControllerWithIdentifier(MySharedChannelsViewController.identifier) as! MySharedChannelsViewController
        sharingVC.navigationController?.navigationBarHidden = true
        self.navigationController?.pushViewController(sharingVC, animated: false)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func inviteContacts(sender: AnyObject) {
        let sharingStoryboard = UIStoryboard(name:"sharing", bundle: nil)
        let inviteContactsVC = sharingStoryboard.instantiateViewControllerWithIdentifier(ContactListViewController.identifier) as! ContactListViewController
        inviteContactsVC.channelId = channelId
        inviteContactsVC.channelName = channelName
        inviteContactsVC.totalMediaCount = totalMediaCount
        inviteContactsVC.navigationController?.navigationBarHidden = true
        self.navigationController?.pushViewController(inviteContactsVC, animated: false)
    }
    
    func initialise()
    {
        channelId = (self.tabBarController as! MyChannelDetailViewController).channelId
        channelName = (self.tabBarController as! MyChannelDetailViewController).channelName
        totalMediaCount = (self.tabBarController as! MyChannelDetailViewController).totalMediaCount
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
        loadingOverlayController.view.frame = CGRectMake(0, 64, self.view.frame.width, self.view.frame.height - (64 + 50))
        loadingOverlayController.startLoading()
        self.loadingOverlay = loadingOverlayController.view
        self.navigationController?.view.addSubview(self.loadingOverlay!)
    }
    
    func removeOverlay(){
        self.loadingOverlay?.removeFromSuperview()
    }
    
    func authenticationSuccessHandler(response:AnyObject?)
    {
        removeOverlay()
        if let json = response as? [String: AnyObject]
        {
            let responseArr = json["MediaDetail"] as! [AnyObject]
            for index in 0 ..< responseArr.count
            {
                let mediaId = responseArr[index].valueForKey("media_detail_id")?.stringValue
                let mediaUrl = responseArr[index].valueForKey("thumbnail_name_SignedUrl") as! String
                let mediaType =  responseArr[index].valueForKey("gcs_object_type") as! String
                let actualUrl =  responseArr[index].valueForKey("gcs_object_name_SignedUrl") as! String
                let notificationType : String = "likes"
                imageDataSource.append([mediaIdKey:mediaId!, mediaUrlKey:mediaUrl, mediaTypeKey:mediaType,actualImageKey:actualUrl,notificationKey:notificationType])
            }
            
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
            completion(result: mediaImage)
        }
        else
        {
            completion(result:UIImage(named: "thumb12")!)
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
        
        for i in limitMediaCount  ..< currentLimit   {
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
                            FileManagerViewController.sharedInstance.saveImageToFilePath(mediaIdForFilePath, mediaImage: result)
                            imageForMedia = result
                        }
                    })
                }
            }
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.fullImageDataSource.append([self.mediaIdKey:self.imageDataSource[i][self.mediaIdKey]!, self.mediaUrlKey:imageForMedia, self.mediaTypeKey:self.imageDataSource[i][self.mediaTypeKey]!,self.actualImageKey:self.imageDataSource[i][self.actualImageKey]!,self.notificationKey:self.imageDataSource[i][self.notificationKey]!])
                self.channelItemsCollectionView.reloadData()
            })
        }
    }
    
}

extension MyChannelItemDetailsViewController : UIScrollViewDelegate{
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let fullyScrolledContentOffset:CGFloat = channelItemsCollectionView.frame.size.width
        
        if (scrollView.contentOffset.x >= fullyScrolledContentOffset)
        {
            if(scrollView.contentOffset.x == fullyScrolledContentOffset)
            {
                
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

extension MyChannelItemDetailsViewController : UICollectionViewDataSource,UICollectionViewDelegateFlowLayout
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
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(MyChannelItemCell.identifier, forIndexPath: indexPath) as! MyChannelItemCell
        
        if fullImageDataSource.count > 0
        {
            let mediaType = fullImageDataSource[indexPath.row][mediaTypeKey] as! String
            let channelImageView = cell.viewWithTag(100) as! UIImageView
            let imageData =  fullImageDataSource[indexPath.row][mediaUrlKey] as! UIImage
            channelImageView.image = imageData
            if mediaType == "video"
            {
                cell.videoPlayIcon.hidden = false
            }
            else{
                cell.videoPlayIcon.hidden = true
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
        let defaults = NSUserDefaults .standardUserDefaults()
        let userId = defaults.valueForKey(userLoginIdKey) as! String
        let vc = MovieViewController.movieViewControllerWithImageVideo(fullImageDataSource[indexPath.row][actualImageKey] as! String, channelName: channelName, userName: userId, mediaType: fullImageDataSource[indexPath.row][mediaTypeKey] as! String, profileImage: UIImage(), videoImageUrl: fullImageDataSource[indexPath.row][mediaUrlKey] as! UIImage, notifType: fullImageDataSource[indexPath.row][notificationKey] as! String,mediaId: fullImageDataSource[indexPath.row][mediaIdKey] as! String) as! MovieViewController
        
        self.presentViewController(vc, animated: false) { () -> Void in
            
        }
        
    }
}
