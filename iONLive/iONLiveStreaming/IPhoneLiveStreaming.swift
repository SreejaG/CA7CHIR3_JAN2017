
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
    
    func mapStream(){
        liveStreamingHelpers.mapStream()
    }
}
