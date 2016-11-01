
import UIKit

@objc class SetUpView: UIViewController {
    let channelManager = ChannelManager.sharedInstance
    let requestManager = RequestManager.sharedInstance
    let imageUploadManger = ImageUpload.sharedInstance
    let profileManager = ProfileManager.sharedInstance
    
    var channelDetails: NSDictionary = NSDictionary()
    var status: Int = Int()
    var userImages : [UIImage] = [UIImage]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func getValue()
    {
        let defaults = NSUserDefaults .standardUserDefaults()
        let userId = defaults.valueForKey(userLoginIdKey) as! String
        let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
        getLoginDetails(userId, token: accessToken)
    }
    
    func getLoginDetails(userName: String, token: String)
    {
        channelManager.getLoggedInDetails(userName, accessToken: token, success: { (response) in
            self.authenticationSuccessHandlerList(response)
        }) { (error, code) in
        }
    }
    
    func authenticationSuccessHandlerList(response:AnyObject?)
    {
        if let json = response as? [String: AnyObject]
        {
            channelDetails = json as NSDictionary
            let qualityOfServiceClass = QOS_CLASS_BACKGROUND
            let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
            dispatch_async(backgroundQueue, {
                self.setChannelDetails()
            })
        }
        else
        {
            ErrorManager.sharedInstance.inValidResponseError()
        }
    }
    
    func convertStringtoURL(url : String) -> NSURL
    {
        let url : NSString = url
        let searchURL : NSURL = NSURL(string: url as String)!
        return searchURL
    }
    
    func setChannelDetails()
    {
        userImages.removeAll()
        let userThumbnailImage = channelDetails["sharedUserThumbnails"] as! NSArray
        let cameraController = IPhoneCameraViewController()
        let sizeThumb = CGSizeMake(30,30)
        for i in 0 ..< userThumbnailImage.count
        {
            if i < userThumbnailImage.count
            {
                var image = UIImage()
                let thumbUrl = UrlManager.sharedInstance.getUserProfileImageBaseURL() + getUserId() + "/" + getAccessTocken() + "/" + (userThumbnailImage[i]["user_name"] as! String)
                if(thumbUrl != "")
                {
                    let url: NSURL = convertStringtoURL(thumbUrl)
                    if let data = NSData(contentsOfURL: url){
                        var convertImage : UIImage = UIImage()
                        let imageDetailsData = (data as NSData?)!
                        convertImage = UIImage(data: imageDetailsData)!
                        let imageAfterConversionThumbnail = cameraController.thumbnaleImage(convertImage, scaledToFillSize: sizeThumb)
                        image = imageAfterConversionThumbnail
                    }
                    else{
                        image = UIImage(named: "dummyUser")!
                    }
                }
                else{
                    image = UIImage(named: "dummyUser")!
                }
                userImages.append(image)
            }
        }
        let controller = PhotoViewerInstance.iphoneCam as! IPhoneCameraViewController
        controller.loggedInDetails(channelDetails as [NSObject : AnyObject], userImages: userImages as NSArray as! [UIImage])
    }
    
    func setMediaLikes(userName: String, accessToken: String, notifType: String, mediaDetailId: String, channelId: String, objects: MovieViewController, typeMedia: String)
    {
        channelManager.postMediaInteractionDetails(userName, accessToken: accessToken, notifType: notifType, mediaDetailId: Int(mediaDetailId)!, channelId: Int(channelId)!, type: typeMedia, success: { (response) in
            self.authenticationSuccessHandlerSetMedia(response,obj: objects)
            
        }) { (error, message) in
            let count = NSUserDefaults.standardUserDefaults().valueForKey("likeCountFlag") as! String
            objects.successFromSetUpView(count)
        }
    }
    func callDelete(obj:MovieViewController, mediaId : NSString)
    {
        obj.checkToCloseViewWhileMediaDelete( mediaId as String)
    }
    func authenticationSuccessHandlerSetMedia(response:AnyObject?,obj: MovieViewController)
    {
        let count = NSUserDefaults.standardUserDefaults().valueForKey("likeCountFlag") as! String
        if let json = response as? [String: AnyObject]
        {
            status = json["status"] as! Int
            let IsLikeSuccess = json["userLikeCountIndicator"] as! String
            var countint : Int = Int()
            if (count != "")
            {
                 countint  = Int(count)!
                if(IsLikeSuccess == "TRUE"){
                    countint = countint + 1
                }
            }
            else{
                countint = 0
            }
            NSUserDefaults.standardUserDefaults().setValue("\(countint)", forKey: "likeCountFlag")
            obj.successFromSetUpView("\(countint)")
        }
        else
        {
            ErrorManager.sharedInstance.inValidResponseError()
            obj.successFromSetUpView(count)
        }
    }
    var profileImageUserForSelectedIndex : UIImage = UIImage()

    func getProfileImageSelectedIndex(userIdKey: String ,objects: MovieViewController)
    {
//        let subUserName = userIdKey
//        let defaults = NSUserDefaults .standardUserDefaults()
//        let userId = defaults.valueForKey(userLoginIdKey) as! String
//        let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
//        profileManager.getSubUserProfileImage(userId, accessToken: accessToken, subscriberUserName: subUserName, success: { (response) in
//            self.successHandlerForProfileImage(response,obj: objects)
//            }, failure: { (error, message) -> () in
//                self.failureHandlerForprofileImage(error, code: message,obj:objects)
//        })
//        
        let profileImageNameBeforeNullChk =  UrlManager.sharedInstance.getProfileURL(userIdKey)
        let profileImageName = self.nullToNil(profileImageNameBeforeNullChk) as! String
        if(profileImageName != "")
        {
            let url: NSURL = self.convertStringtoURL(profileImageName)
            if let data = NSData(contentsOfURL: url){
                let imageDetailsData = (data as NSData?)!
                profileImageUserForSelectedIndex = UIImage(data: imageDetailsData)!
            }
            else{
                profileImageUserForSelectedIndex = UIImage(named: "dummyUser")!
            }
        }
        else{
            profileImageUserForSelectedIndex = UIImage(named: "dummyUser")!
        }
   
       objects.successFromSetUpViewProfileImage(profileImageUserForSelectedIndex)

    }

    func successHandlerForProfileImage(response:AnyObject?,obj: MovieViewController)
    {
//        if let json = response as? [String: AnyObject]
//        {
//            let profileImageNameBeforeNullChk = json["profile_image_thumbnail"]
//            let profileImageName = self.nullToNil(profileImageNameBeforeNullChk) as! String
//            if(profileImageName != "")
//            {
//                let url: NSURL = self.convertStringtoURL(profileImageName)
//                if let data = NSData(contentsOfURL: url){
//                    let imageDetailsData = (data as NSData?)!
//                    profileImageUserForSelectedIndex = UIImage(data: imageDetailsData)!
//                }
//                else{
//                    profileImageUserForSelectedIndex = UIImage(named: "dummyUser")!
//                }
//            }
//            else{
//                profileImageUserForSelectedIndex = UIImage(named: "dummyUser")!
//            }
//            
//        }
//        else{
//            profileImageUserForSelectedIndex = UIImage(named: "dummyUser")!
//        }
//        obj.successFromSetUpViewProfileImage(profileImageUserForSelectedIndex)
    }
    
    func nullToNil(value : AnyObject?) -> AnyObject? {
        if value is NSNull {
            return ""
        } else {
            return value
        }
    }
    
    func failureHandlerForprofileImage(error: NSError?, code: String,obj: MovieViewController)
    {
        profileImageUserForSelectedIndex = UIImage(named: "dummyUser")!
        obj.successFromSetUpViewProfileImage(profileImageUserForSelectedIndex)
    }
    
    func getLikeCount(mediaType : String,mediaId: String, Objects:MovieViewController) {
        
        let mediaTypeSelected : String = mediaType
        let defaults = NSUserDefaults .standardUserDefaults()
        let userId = defaults.valueForKey(userLoginIdKey) as! String
        let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
        channelManager.getMediaLikeCountDetails(userId, accessToken: accessToken, mediaId: mediaId, mediaType: mediaTypeSelected, success: { (response) in
            self.successHandlerForMediaCount(response,obj:Objects)
            }, failure: { (error, message) -> () in
                self.failureHandlerForMediaCount(error, code: message,obj:Objects)
                return
        })
    }
    
    var likeCountSelectedIndex : String = "0"
    
    func successHandlerForMediaCount(response:AnyObject?,obj:MovieViewController)
    {
        if let json = response as? [String: AnyObject]
        {
            likeCountSelectedIndex = "\(json["likeCount"]!)"
        }
        obj.successFromSetUpView("\(likeCountSelectedIndex)")
        
    }
    
    func failureHandlerForMediaCount(error: NSError?, code: String,obj:MovieViewController)
    {
        likeCountSelectedIndex = "0"
        obj.successFromSetUpView("\(likeCountSelectedIndex)")
    }
    
    func getMediaCount(channelId: String) -> Int{
        let filteredData = GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[channelId]!.filter(thumbExists)
        let totalCount = filteredData.count
        return totalCount
    }
    
    func thumbExists (item: [String : AnyObject]) -> Bool {
        return item[tImageKey] != nil
    }
    
    func cleanMyDayCall(obj:MovieViewController, chanelId: String) {
        obj.cleanMyDayComplete(chanelId)
    }
}

