
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
      //  if(GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict.count > 0){
            NSNotificationCenter.defaultCenter().postNotificationName("mapNewMedias", object: nil)
      //  }
        GlobalDataRetriever.sharedInstance.globalDataSource.append(dataSourceRow)
        GlobalDataRetriever.sharedInstance.globalDataSource.sortInPlace({ p1, p2 in
            let time1 = p1[createdTimeStampKey] as! String
            let time2 = p2[createdTimeStampKey] as! String
            return time1 > time2
        })
        NSUserDefaults.standardUserDefaults().setInteger( GlobalDataRetriever.sharedInstance.globalDataSource.count, forKey: ArchiveCount)
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
