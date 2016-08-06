
import UIKit

class MediaBeforeUploadComplete: NSObject {
    
    class var sharedInstance: MediaBeforeUploadComplete {
        struct Singleton {
            static let instance = MediaBeforeUploadComplete()
        }
        return Singleton.instance
    }
    
    let mediaIdKey = "media_detail_id"
    let uploadProgressKey = "upload_progress"
    let createdTimeStampKey = "created_timeStamp"
    
    var dataSourceFromLocal : [[String:AnyObject]] =  [[String:AnyObject]]()
    
    func updateDataSource(dataSourceRow: [String:AnyObject]) {
        dataSourceFromLocal.append(dataSourceRow)
        NSNotificationCenter.defaultCenter().postNotificationName("mapNewMedias", object: nil)
        NSNotificationCenter.defaultCenter().postNotificationName("setFullscreenImage", object: nil)
        GlobalDataRetriever.sharedInstance.globalDataSource.append(dataSourceRow)
        print( GlobalDataRetriever.sharedInstance.globalDataSource.count)
        GlobalDataRetriever.sharedInstance.globalDataSource.sortInPlace({ p1, p2 in
            let time1 = Int(p1[mediaIdKey] as! String)
            let time2 = Int(p2[mediaIdKey] as! String)
            return time1 > time2
        })
        var archCount : Int = Int()
        if let archivetotal =  NSUserDefaults.standardUserDefaults().valueForKey(ArchiveCount)
        {
            archCount = archivetotal as! Int
        }
        else{
            archCount = 0
        }
        archCount = archCount + 1
        NSUserDefaults.standardUserDefaults().setInteger( archCount, forKey: ArchiveCount)
        
        print(NSUserDefaults.standardUserDefaults().valueForKey(ArchiveCount) as! Int)
    }
    
    func deleteRowFromDataSource(mediaId: String)  {
        for var i = 0; i <  GlobalDataRetriever.sharedInstance.globalDataSource.count; i++
        {
            let mediaDetailId =  GlobalDataRetriever.sharedInstance.globalDataSource[i][mediaIdKey] as! String
            
            if(mediaDetailId == mediaId)
            {
                GlobalDataRetriever.sharedInstance.globalDataSource[i][uploadProgressKey] = 1.0
            }
        }
    }
}
