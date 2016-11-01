
import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    var photoViewController : PhotoViewerViewController?
    let requestManager = RequestManager.sharedInstance
    
    var mediaShared:[[String:AnyObject]] = [[String:AnyObject]]()
    let sharedMediaCount = "total_no_media_shared"
    var deleteQueue : NSMutableArray = NSMutableArray()

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        if(NSUserDefaults.standardUserDefaults().boolForKey("StartedStreaming"))
        {
            NSUserDefaults.standardUserDefaults().setBool(false, forKey: "StartedStreaming")
        }
        
        
     

//        NSUserDefaults.standardUserDefaults().setBool(false, forKey:"Background")
        NSUserDefaults.standardUserDefaults().setValue("Empty", forKey: "EmptyMedia")
        NSUserDefaults.standardUserDefaults().setValue("Empty", forKey: "EmptyShare")
        let settings : UIUserNotificationSettings = UIUserNotificationSettings(forTypes:[UIUserNotificationType.Alert, UIUserNotificationType.Sound], categories: nil)
        UIApplication.sharedApplication().registerUserNotificationSettings(settings)
        UIApplication.sharedApplication().registerForRemoteNotifications()
        let documentsPath = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0] + "/GCSCA7CH"
        if(NSFileManager.defaultManager().fileExistsAtPath(documentsPath))
        {
        }
        else{
            FileManagerViewController.sharedInstance.createParentDirectory()
        }
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(nil, forKey: "uploaObjectDict")
        defaults.setObject(nil, forKey: "ProgressDict")
        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
        self.window!.backgroundColor = UIColor.whiteColor()
        if let remoteNotification = launchOptions?[UIApplicationLaunchOptionsRemoteNotificationKey] as? NSDictionary {
             NSUserDefaults.standardUserDefaults().setValue(remoteNotification, forKey: "remote")
            GlobalDataChannelList.sharedInstance.initialise()
            ChannelSharedListAPI.sharedInstance.initialisedata()
            let result = remoteNotification["messageFrom"] as! NSDictionary
            if(result["type"] as! String == "liveStream")
            {
                NSNotificationCenter.defaultCenter().postNotificationName("PushNotification", object: result)
                if(result["subType"] as! String == "started"){
                    defaults.setValue("1", forKey: "notificationArrived")
                }
                else{
                    defaults.setValue("0", forKey: "notificationArrived")
                }
            }
            else if (result["type"] as! String == "share")
            {
                defaults.setValue("1", forKey: "notificationArrived")
            }
            else{
               defaults.setValue("0", forKey: "notificationArrived")
            }
            if NSUserDefaults.standardUserDefaults().valueForKey("notificationArrived") as! String == "1"
            {
                loadNotificationView()
            }
            else{
                let defaults = NSUserDefaults .standardUserDefaults()
                defaults.setValue("0", forKey: "notificationArrived")
                initialViewController()
            }
        }
        else{
            let defaults = NSUserDefaults .standardUserDefaults()
            defaults.setValue("0", forKey: "notificationArrived")
            initialViewController()
        }
        
        self.window!.makeKeyAndVisible()
        return true
    }
    
    func applicationWillResignActive(application: UIApplication) {
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
       
    }
    
    func applicationWillEnterForeground(application: UIApplication) {
        NSNotificationCenter.defaultCenter().postNotificationName("enterBackground", object:nil)
        if NSUserDefaults.standardUserDefaults().valueForKey("notificationArrived") != nil{
            if NSUserDefaults.standardUserDefaults().valueForKey("notificationArrived") as! String == "1"
            {
                if(application.applicationState == .Inactive || application.applicationState == .Background)
                {
                    
                    GlobalDataChannelList.sharedInstance.initialise()
                    ChannelSharedListAPI.sharedInstance.initialisedata()
                    loadNotificationView()
                }
            }
        }
        if(deleteQueue.count > 0)
        {
            for i in 0  ..< deleteQueue.count
            {

                NSNotificationCenter.defaultCenter().postNotificationName("MediaDelete", object: deleteQueue[i])
            }
        }
        deleteQueue.removeAllObjects()
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        application.applicationIconBadgeNumber = 0;
    }
    
    func applicationWillTerminate(application: UIApplication) {
        self.saveContext()
         NSUserDefaults.standardUserDefaults().setValue("0", forKey: "notificationArrived")
    }
    
    func initialViewController()
    {
        let defaults = NSUserDefaults .standardUserDefaults()
        defaults.setValue("0", forKey: "notificationFlag")
        var controller : UIViewController = UIViewController()
        NSUserDefaults.standardUserDefaults().setObject(1, forKey: "shutterActionMode");
        if (NSUserDefaults.standardUserDefaults().objectForKey("flashMode") == nil)
        {
            NSUserDefaults.standardUserDefaults().setObject(0, forKey: "flashMode")
        }
        if (NSUserDefaults.standardUserDefaults().objectForKey("SaveToCameraRoll") == nil)
        {
            NSUserDefaults.standardUserDefaults().setObject(1, forKey: "SaveToCameraRoll")
        }
        //Auto login check
        if (NSUserDefaults.standardUserDefaults().objectForKey("userAccessTockenKey") == nil)
        {
            let defaults = NSUserDefaults .standardUserDefaults()
            defaults.setValue("login", forKey: "loadingView")
            let authenticationStoryboard = UIStoryboard(name:"Authentication" , bundle: nil)
            controller = authenticationStoryboard.instantiateViewControllerWithIdentifier("AuthenticateNavigationController")
            self.window!.rootViewController = controller
        }
        else
        {
            loadCameraViewController()
        }
    }
    
    func clearStreamingUserDefaults(defaults:NSUserDefaults)
    {
        defaults.removeObjectForKey(streamingToken)
        defaults.removeObjectForKey(startedStreaming)
        defaults.removeObjectForKey(initializingStream)
    }
    
    func loadCameraViewController()
    {
        let defaults = NSUserDefaults .standardUserDefaults()
        defaults.setValue("appDelegateRedirection", forKey: "viewFromWhichPage")
        var navigationController:UINavigationController?
        let cameraViewStoryboard = UIStoryboard(name:"IPhoneCameraView" , bundle: nil)
        let iPhoneCameraViewController = cameraViewStoryboard.instantiateViewControllerWithIdentifier("IPhoneCameraViewController") as! IPhoneCameraViewController
        
        navigationController = UINavigationController(rootViewController: iPhoneCameraViewController)
        navigationController!.navigationBarHidden = true
        self.window!.rootViewController = navigationController
    }
    
    func loadLiveStreamView()
    {
        var navigationController:UINavigationController?
        let vc = MovieViewController.movieViewControllerWithContentPath("rtsp://192.168.42.1:554/live", parameters: nil , liveVideo: true) as! UIViewController
        
        clearStreamingUserDefaults(NSUserDefaults.standardUserDefaults())
        navigationController = UINavigationController(rootViewController: vc)
        navigationController!.navigationBarHidden = true
        self.window!.rootViewController = navigationController
    }
    
    func  loadNotificationView()  {
        NSUserDefaults.standardUserDefaults().setInteger(1, forKey: "SelectedTab")
        let defaults = NSUserDefaults .standardUserDefaults()
        defaults.setValue("1", forKey: "notificationFlag")
        var navigationController:UINavigationController?
        let notificationStoryboard = UIStoryboard(name:"Streaming" , bundle: nil)
        let notificationViewController = notificationStoryboard.instantiateViewControllerWithIdentifier(StreamsGalleryViewController.identifier) as! StreamsGalleryViewController
        navigationController = UINavigationController(rootViewController: notificationViewController)
        navigationController!.navigationBarHidden = true
        self.window?.rootViewController = navigationController
        
        
//        let defaults = NSUserDefaults .standardUserDefaults()
//        defaults.setValue("1", forKey: "notificationFlag")
//        var navigationController:UINavigationController?
//        let notificationStoryboard = UIStoryboard(name:"MyChannel" , bundle: nil)
//        let notificationViewController = notificationStoryboard.instantiateViewControllerWithIdentifier(MyChannelNotificationViewController.identifier) as! MyChannelNotificationViewController
//        navigationController = UINavigationController(rootViewController: notificationViewController)
//        navigationController!.navigationBarHidden = true
//        self.window?.rootViewController = navigationController
    }
    
    // MARK: - Core Data stack
    lazy var applicationDocumentsDirectory: NSURL = {
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1]
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        let modelURL = NSBundle.mainBundle().URLForResource("GalleryModel", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("SingleViewCoreData.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
        } catch {
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            
            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            abort()
        }
        return coordinator
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    // MARK: - Core Data Saving support
    func saveContext () {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                _ = error as NSError
                abort()
            }
        }
    }
    
    //push notification
    func application(application: UIApplication,didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        
        let characterSet: NSCharacterSet = NSCharacterSet( charactersInString: "<>" )
        let deviceTokenString: String = ( deviceToken.description as NSString )
            .stringByTrimmingCharactersInSet( characterSet )
            .stringByReplacingOccurrencesOfString( " ", withString: "" ) as String
        if(deviceTokenString != ""){
            let defaults = NSUserDefaults .standardUserDefaults()
            defaults.setValue(deviceTokenString, forKey: "deviceToken")
        }
        else{
            ErrorManager.sharedInstance.installFailure()
        }
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        let result = userInfo["messageFrom"] as! NSDictionary
        let defaults = NSUserDefaults .standardUserDefaults()
        var checkFlag : Bool = false
        if( application.applicationState == .Inactive )
        {
            checkFlag = true
        }
        if(result["type"] as! String == "delete" || result["type"] as! String == "media" )
        {
            defaults.setValue("0", forKey: "notificationArrived")
            NSNotificationCenter.defaultCenter().postNotificationName("MediaDelete", object: result)
            
            if ( result["type"] as! String == "media")
            {
                
                if(application.applicationState == .Inactive || application.applicationState == .Background)
                {
                    deleteQueue.addObject(result)
                }
            }
        }
        else if ( (result["type"] as! String == "share") || (result["type"] as! String == "channel") || (result["type"] as! String == "liveStream") || (result["type"] as! String == "My Day Cleaning")){
            
            if (result["type"] as! String == "share"){
                
                NSUserDefaults.standardUserDefaults().setObject("share", forKey: "NotificationText")
                let chid : String = "\(result["channelId"]!)"
                if(!checkFlag)
                {
                    updateCount(chid)
                }
            }
            if (result["type"] as! String == "channel"){
                
                if (result["subType"] as! String == "deleted")
                {
                    let chid : String = "\(result["channelId"]!)"
                    defaults.setValue("0", forKey: "notificationArrived")
                    NSNotificationCenter.defaultCenter().postNotificationName("PushNotification", object: result)
                    removeEntryFromShare(chid)
                    removeEntryFromGlobal(chid)
                }
                if(result["subType"] as! String == "useradded")
                {
                    defaults.setValue("0", forKey: "notificationArrived")
                    
                    NSUserDefaults.standardUserDefaults().setObject(result["messageText"] as! String, forKey: "NotificationChannelText")
                    NSUserDefaults.standardUserDefaults().setObject(result["messageText"] as! String, forKey: "NotificationText")
                }
            }
            else if (result["type"] as! String == "My Day Cleaning")
            {
                let chid : String = "\(result["channelId"]!)"
                myDayCleanUpChannel(chid)
        
            }
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                NSNotificationCenter.defaultCenter().postNotificationName("PushNotificationStream", object: result)
                NSNotificationCenter.defaultCenter().postNotificationName("PushNotificationChannel", object: result)
            })
            
        }
        
        if(result["type"] as! String == "liveStream")
        {
            NSNotificationCenter.defaultCenter().postNotificationName("PushNotification", object: result)
            if(result["subType"] as! String == "started"){
                defaults.setValue("1", forKey: "notificationArrived")
                
            }
            else{
                defaults.setValue("0", forKey: "notificationArrived")
            }
        }
        else if  (result["type"] as! String == "share")
        {
            defaults.setValue("1", forKey: "notificationArrived")
        }
        else if (result["type"] as! String == "like")
        {
            if(result["subType"] as! String != "liveStream"){
                defaults.setValue("2", forKey: "notificationArrived")
            }
            else{
                defaults.setValue("0", forKey: "notificationArrived")
            }
        }
        
        
    }
//    
//    func test()
//    {
//        let chid : String = "\(156)"
//        myDayCleanUpChannel(chid)
//        
//        
//        let result = ["channelId": 156, "type": "My Day Cleaning"]
//
//        NSNotificationCenter.defaultCenter().postNotificationName("PushNotificationStream", object: result)
//        NSNotificationCenter.defaultCenter().postNotificationName("PushNotificationChannel", object: result)
//    }
    func myDayCleanUpChannel(channelId : String)
    {
        let index  = getUpdateIndexChannel(channelId, isCountArray: true)
        if(index != -1)
        {
            if(mediaShared.count > 0)
            {
                let  latestCount : Int = 0
                mediaShared[index][sharedMediaCount]  = "\(latestCount)"
                NSUserDefaults.standardUserDefaults().setObject(mediaShared, forKey: "Shared")
            }
            print(mediaShared[index])
        }
        let indexOfChannelList =  getUpdateIndexChannel(channelId, isCountArray: false)
        if(indexOfChannelList != -1)
        {
            var mediaImage : UIImage?
            mediaImage = UIImage()
         ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource[indexOfChannelList][mediaImageKey] = mediaImage
            
            print(ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource[indexOfChannelList])

        }
        
    }
    func updateCount( channelId : String)
    {
        let index  = getUpdateIndexChannel(channelId, isCountArray: true)
        if(index != -1)
        {
            if(mediaShared.count > 0)
            {
                let sharedCount = mediaShared[index][sharedMediaCount] as! String
                let  latestCount : Int = Int(sharedCount)! + 1
                mediaShared[index][sharedMediaCount]  = "\(latestCount)"
                NSUserDefaults.standardUserDefaults().setObject(mediaShared, forKey: "Shared")
            }
        }
        
        let indexOfChannelList =  getUpdateIndexChannel(channelId, isCountArray: false)
        if(indexOfChannelList != -1)
        {
            if(ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource.count > 0)
            {
                ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource[indexOfChannelList][sharedMediaCount]  = "1"
            }
            let timeStamp = "created_time_stamp"

            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            dateFormatter.timeZone = NSTimeZone(name: "UTC")
            let currentDate = dateFormatter.stringFromDate(NSDate())
            ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource[indexOfChannelList][timeStamp] = currentDate
            let filteredData = ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource.filter(thumbExists)
            let totalCount = filteredData.count
            let itemToMove = ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource[indexOfChannelList]
            ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource.removeAtIndex(indexOfChannelList)
            ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource.insert(itemToMove, atIndex: totalCount)
        }
        
        NSNotificationCenter.defaultCenter().postNotificationName("PushNotificationIphone", object: nil)
        NSNotificationCenter.defaultCenter().postNotificationName("CountIncrementedPushNotification", object: channelId)
    }
    func thumbExists (item: [String : AnyObject]) -> Bool {
        let liveStreamStatus = "liveChannel"
        return item[liveStreamStatus] as! String == "1"
    }
    func removeEntryFromShare(channelId : String)
    {
        let index  = getUpdateIndexChannel(channelId, isCountArray: true)
        if(index != -1)
        {
            if(mediaShared.count > 0)
            {
                mediaShared.removeAtIndex(index)
                NSUserDefaults.standardUserDefaults().setObject(mediaShared, forKey: "Shared")
            }
        }
    }
    
    func removeEntryFromGlobal(channelId : String)
    {
        let index  = getUpdateIndexChannel(channelId, isCountArray: false)
        if(index != -1)
        {
            if(ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource.count > 0)
            {
                ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource.removeAtIndex(index)
            }
        }

    }
    
    func getUpdateIndexChannel(channelIdValue : String , isCountArray : Bool) -> Int
    {
        let channelIdkey = "ch_detail_id"
        var selectedArray : NSArray = NSArray()
        var indexOfRow : Int = -1
        if(isCountArray)
        {
            if (NSUserDefaults.standardUserDefaults().objectForKey("Shared") != nil)
            {
                mediaShared.removeAll()
                mediaShared = NSUserDefaults.standardUserDefaults().valueForKey("Shared") as! NSArray as! [[String : AnyObject]]
                selectedArray = mediaShared as Array
            }
            else{
                indexOfRow = -1
            }
        }
        else{
            selectedArray = ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource
        }
        
        var  checkFlag : Bool = false
        var index : Int =  -1
        
        for i in 0  ..< selectedArray.count 
        {
            let channelId = selectedArray[i][channelIdkey]!
            if "\(channelId!)"  == channelIdValue
            {
                checkFlag = true
                index = i
                break
            }
        }
        if(checkFlag)
        {
            indexOfRow = index
        }
        
        return indexOfRow
    }
    
    func convertStringToDictionary(text: String) -> [String:AnyObject]? {
        if let data = text.dataUsingEncoding(NSUTF8StringEncoding) {
            do {
                return try NSJSONSerialization.JSONObjectWithData(data, options: []) as? [String:AnyObject]
            } catch  _ as NSError {
            }
        }
        return nil
    }
    
    //Called if unable to register for APNS.
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
    }
}

