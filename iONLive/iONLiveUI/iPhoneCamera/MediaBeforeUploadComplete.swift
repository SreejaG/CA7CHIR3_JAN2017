
import UIKit

class MediaBeforeUploadComplete: NSObject {
    
    class var sharedInstance: MediaBeforeUploadComplete {
        struct Singleton {
            static let instance = MediaBeforeUploadComplete()
        }
        return Singleton.instance
    }
    
    func updateDataSource(dataSourceRow: [String:Any]) {
        GlobalChannelToImageMapping.sharedInstance.mapNewMediasToAllChannels(dataSourceRow: dataSourceRow)
    }
    
    func deleteRowFromDataSource(mediaId: String)  {
        let archiveChanelId = "\(UserDefaults.standard.value(forKey: archiveId) as! Int)"
        if(GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict.count > 0){
            for i in 0 ..< GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[archiveChanelId]!.count
            {
                if(i < GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[archiveChanelId]!.count){
                    let mediaDetailId =  GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[archiveChanelId]![i][mediaIdKey] as! String
                    
                    if(mediaDetailId == mediaId)
                    {
                        GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[archiveChanelId]![i][progressKey] = Float(1.0)
                    }
                }
            }
        }
    }
}
