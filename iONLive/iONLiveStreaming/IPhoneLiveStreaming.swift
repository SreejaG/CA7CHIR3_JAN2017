
import UIKit

class IPhoneLiveStreaming: NSObject {
    
    var showAlert : Bool = true;
    let liveStreamingHelpers = LiveStreamingHelpers()
    let streamTockenID : String = String()
    
    class var sharedInstance: IPhoneLiveStreaming {
        struct Singleton {
            static let instance = IPhoneLiveStreaming()
            private init(){}
        }
        return Singleton.instance
    }
    func startLiveStreaming(session:VCSimpleSession)
    {
        liveStreamingHelpers.iPhoneLiveStreamingSession = session
        liveStreamingHelpers.startStreamingClicked()
    }
    
    func stopStreamingClicked()
    {
        showAlert = true;
        liveStreamingHelpers.stopLiveStreaming()
    }
    
//    func mapStream(){
//        let loginId = NSUserDefaults.standardUserDefaults().objectForKey(userLoginIdKey) as! String
//        let streamToken = NSUserDefaults.standardUserDefaults().objectForKey("streamTocken") as! String
//       
//        liveStreamingHelpers.setDefaultMappingForLiveStream(streamToken)
//
////        liveStreamingHelpers.mapStream()
//    }
}
