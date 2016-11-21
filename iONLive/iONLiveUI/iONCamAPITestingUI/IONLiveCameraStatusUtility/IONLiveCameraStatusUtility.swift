
import UIKit

class IONLiveCameraStatusUtility: NSObject {
    
    let iONLiveCameraStatusManager = iONLiveCameraStatus.sharedInstance
    
    var freememStatus = ""
    var spaceLeftStatus = ""
    var batteryLevelStatus = ""
    var catalogDataSourceStatus : [String]?
    var videoDataSourceStatus : [String]?
    
    func getCatalogStatus() -> [String]?
    {
        return catalogDataSourceStatus
    }
    
    func getVideoStatus() -> [String]?
    {
        return videoDataSourceStatus
    }
    
    func getiONLiveCameraStatus( success: ((_ response: AnyObject?)->())?, failure: ((_ error: NSError?, _ code: String)->())?)
    {
        iONLiveCameraStatusManager.getiONLiveCameraStatus(success: { (response) -> () in
            self.iONLiveCamGetStatusSuccessHandler(response: response)
            if let responseObject = response as? [String:AnyObject]
            {
                //call the success block that was passed with response data
                success?(responseObject as AnyObject?)
            }
            
        }) { (error, code) -> () in
            ErrorManager.sharedInstance.alert(title: "Status Failed", message: "Failure to get status ")
        }
    }
    
    //PRAGMA MARK:- API Handlers
    func iONLiveCamGetStatusSuccessHandler(response:AnyObject?)
    {
        if let json = response as? [String: AnyObject]
        {
            if let freemem = json["freemem"]
            {
                freememStatus = (freemem as? String)!
            }
            if let spaceLeft = json["spaceLeft"]
            {
                spaceLeftStatus = (spaceLeft as? String)!
            }
            if let batteryLevel = json["batteryLevel"]
            {
                batteryLevelStatus = (batteryLevel as? String)!
            }
            if let catalog = json["catalog"]
            {
                catalogDataSourceStatus = catalog as? [String]
            }
            if let video = json["video"]
            {
                videoDataSourceStatus = video as? [String]
            }
        }
    }
}
