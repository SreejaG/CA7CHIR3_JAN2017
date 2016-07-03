
import UIKit

class MediaBeforeUploadComplete: NSObject {
    
    class var sharedInstance: MediaBeforeUploadComplete {
        struct Singleton {
            static let instance = MediaBeforeUploadComplete()
        }
        return Singleton.instance
    }
    
    let mediaIdKey = "media_detail_id"
    
    var dataSourceFromLocal : [[String:AnyObject]] =  [[String:AnyObject]]()

    func updateDataSource(dataSourceRow: [String:AnyObject]) {
        dataSourceFromLocal.append(dataSourceRow)
    }
    
    func getDataSource() -> [[String:AnyObject]]{
        return dataSourceFromLocal
    }
    
    func deleteRowFromDataSource(mediaId: String)  {
        for var i = 0; i < dataSourceFromLocal.count; i++
        {
            let mediaDetailId = dataSourceFromLocal[i][mediaIdKey] as! Int
            if(mediaDetailId == Int(mediaId)){
                dataSourceFromLocal.removeAtIndex(i)
            }
        }
    }
}
