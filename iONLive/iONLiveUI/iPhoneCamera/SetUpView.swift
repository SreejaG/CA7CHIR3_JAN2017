
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
        let defaults = UserDefaults.standard
        let userId = defaults.value(forKey: userLoginIdKey) as! String
        let accessToken = defaults.value(forKey: userAccessTockenKey) as! String
        getLoginDetails(userName: userId, token: accessToken)
    }
    
    func getLoginDetails(userName: String, token: String)
    {
        channelManager.getLoggedInDetails(userName: userName, accessToken: token, success: { (response) in
            self.authenticationSuccessHandlerList(response: response)
        }) { (error, code) in
            if((code == "USER004") || (code == "USER005") || (code == "USER006")){
                if let tokenValid = UserDefaults.standard.value(forKey: "tokenValid")
                {
                    if tokenValid as! String == "true"
                    {
                        let notificationName = Notification.Name("refreshLogin")
                        NotificationCenter.default.post(name: notificationName, object: self)
                    }
                }
            }
        }
    }
    
    func authenticationSuccessHandlerList(response:Any?)
    {
        if let json = response as? [String: Any]
        {
            channelDetails = json as NSDictionary
            let backgroundQueue = DispatchQueue(label: "com.app.queue",
                                                qos: .background,
                                                target: nil)
            backgroundQueue.async {
                self.setChannelDetails()
            }
        }
        else
        {
            ErrorManager.sharedInstance.inValidResponseError()
        }
    }
    
    func convertStringtoURL(url : String) -> NSURL
    {
        let url : NSString = url as NSString
        let searchURL : NSURL = NSURL(string: url as String)!
        return searchURL
    }
    
    func setChannelDetails()
    {
        userImages.removeAll()
        let userThumbnailImage = channelDetails["sharedUserThumbnails"] as! [[String:Any?]]
        let cameraController = IPhoneCameraViewController()
        let sizeThumb = CGSize(width:30, height:30)
        for i in 0 ..< userThumbnailImage.count
        {
            if i < userThumbnailImage.count
            {
                var image = UIImage()
                let userNames : String = userThumbnailImage[i][usernameKey] as! String
                let thumbUrl = UrlManager.sharedInstance.getUserProfileImageBaseURL() + getUserId() + "/" + getAccessTocken() + "/" + userNames
                if(thumbUrl != "")
                {
                    let url: NSURL = convertStringtoURL(url: thumbUrl)
                    if let data = NSData(contentsOf: url as URL){
                        let imageDetailsData = (data as NSData?)!
                        if let convertImage = UIImage(data: imageDetailsData as Data)
                        {
                            let imageAfterConversionThumbnail = cameraController.thumbnaleImage(convertImage, scaledToFill: sizeThumb)
                            image = imageAfterConversionThumbnail!
                        }
                        else{
                            image = UIImage(named: "dummyUser")!
                        }
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
        controller.logged(inDetails: channelDetails as! [NSObject : Any], userImages: userImages as NSArray as! [UIImage])
    }
    
    func setMediaLikes(userName: String, accessToken: String, notifType: String, mediaDetailId: String, channelId: String, objects: MovieViewController, typeMedia: String)
    {
        channelManager.postMediaInteractionDetails(userName: userName, accessToken: accessToken, notifType: notifType, mediaDetailId: Int(mediaDetailId)!, channelId: Int(channelId)!, type: typeMedia, success: { (response) in
            self.authenticationSuccessHandlerSetMedia(response: response,obj: objects)
            
        }) { (error, message) in
            if((message == "USER004") || (message == "USER005") || (message == "USER006")){
                if let tokenValid = UserDefaults.standard.value(forKey: "tokenValid")
                {
                    if tokenValid as! String == "true"
                    {
                        let notificationName = Notification.Name("tokenExpiredInMovie")
                        NotificationCenter.default.post(name: notificationName, object: self)
                    }
                }
            }
            let count = UserDefaults.standard.value(forKey: "likeCountFlag") as! String
            objects.success(fromSetUpView: count)
        }
    }
    
    func callDelete(obj:MovieViewController, mediaId : String)
    {
        obj.check( toCloseViewWhileMediaDelete: mediaId as String)
    }
    
    func callDeleteWhileMyDayCleanUp(obj:MovieViewController, channelId : String)
    {
        obj.check (toCloseWhileMyDayCleanUp: channelId as String)
    }
    
    func cleanMyDayCall(obj:MovieViewController, chanelId: String) {
        obj.cleanMyDayComplete(chanelId)
    }
    
    func authenticationSuccessHandlerSetMedia(response:Any?,obj: MovieViewController)
    {
        let count = UserDefaults.standard.value(forKey: "likeCountFlag") as! String
        if let json = response as? [String: Any]
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
            UserDefaults.standard.setValue("\(countint)", forKey: "likeCountFlag")
            obj.success(fromSetUpView: "\(countint)")
        }
        else
        {
            ErrorManager.sharedInstance.inValidResponseError()
            obj.success(fromSetUpView: count)
        }
    }
    
    var profileImageUserForSelectedIndex : UIImage = UIImage()
    
    func getProfileImageSelectedIndex(userIdKey: String ,objects: MovieViewController, operObj: BlockOperation)
    {
        if operObj.isCancelled == true{
            return
        }
        let profileImageNameBeforeNullChk =  UrlManager.sharedInstance.getProfileURL(userId: userIdKey)
        let profileImageName = self.nullToNil(value: profileImageNameBeforeNullChk)
        if("\(profileImageName)" != "")
        {
            let url: NSURL = self.convertStringtoURL(url: profileImageName! as! String)
            if let data = NSData(contentsOf: url as URL){
                if let imageDetailsData = UIImage(data: data as Data)
                {
                    profileImageUserForSelectedIndex = imageDetailsData
                    objects.success(fromSetUpViewProfileImage: profileImageUserForSelectedIndex)
                }
                else{
                    let failedString = String(data: data as Data, encoding: String.Encoding.utf8)
                    let fullString = failedString?.components(separatedBy: ",")
                    let errorString = fullString?[1].components(separatedBy: ":")
                    var orgString = errorString?[1]
                    orgString = orgString?.trimmingCharacters(in: NSCharacterSet.alphanumerics.inverted)
                    if((orgString == "USER004") || (orgString == "USER005") || (orgString == "USER006")){
                        if let tokenValid = UserDefaults.standard.value(forKey: "tokenValid")
                        {
                            if tokenValid as! String == "true"
                            {
                                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "tokenExpiredInMovie"), object:nil)
                            }
                        }
                    }
                }
            }
            else{
                profileImageUserForSelectedIndex = UIImage(named: "dummyUser")!
                objects.success(fromSetUpViewProfileImage: profileImageUserForSelectedIndex)
            }
        }
        else{
            profileImageUserForSelectedIndex = UIImage(named: "dummyUser")!
            objects.success(fromSetUpViewProfileImage: profileImageUserForSelectedIndex)
        }
        
    }
    
    func successHandlerForProfileImage(response:Any?,obj: MovieViewController)
    {
    }
    
    func nullToNil(value : Any?) -> Any? {
        if value is NSNull {
            return ""
        } else {
            return value
        }
    }
    
    func failureHandlerForprofileImage(error: NSError?, code: String,obj: MovieViewController)
    {
        profileImageUserForSelectedIndex = UIImage(named: "dummyUser")!
        obj.success(fromSetUpViewProfileImage: profileImageUserForSelectedIndex)
    }
    
    func getLikeCount(mediaType : String,mediaId: String, Objects:MovieViewController, operObjs: BlockOperation) {
        if operObjs.isCancelled == true{
            return
        }
        let mediaTypeSelected : String = mediaType
        let defaults = UserDefaults.standard
        let userId = defaults.value(forKey: userLoginIdKey) as! String
        let accessToken = defaults.value(forKey: userAccessTockenKey) as! String
        channelManager.getMediaLikeCountDetails(userName: userId, accessToken: accessToken, mediaId: mediaId, mediaType: mediaTypeSelected, success: { (response) in
            self.successHandlerForMediaCount(response: response,obj:Objects)
        }, failure: { (error, message) -> () in
            self.failureHandlerForMediaCount(error: error, code: message,obj:Objects)
            return
        })
    }
    
    var likeCountSelectedIndex : String = "0"
    
    func successHandlerForMediaCount(response:Any?,obj:MovieViewController)
    {
        if let json = response as? [String: Any]
        {
            likeCountSelectedIndex = "\(json["likeCount"]!)"
        }
        obj.success(fromSetUpView: "\(likeCountSelectedIndex)")
    }
    
    func failureHandlerForMediaCount(error: NSError?, code: String,obj:MovieViewController)
    {
        likeCountSelectedIndex = "0"
        obj.success(fromSetUpView: "\(likeCountSelectedIndex)")
    }
    
    func getMediaCount(channelId: String) -> Int{
        let filteredData = GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[channelId]!.filter(thumbExists)
        let totalCount = filteredData.count
        return totalCount
    }
    
    func thumbExists (item: [String : Any]) -> Bool {
        return item[tImageKey] != nil
    }
}

