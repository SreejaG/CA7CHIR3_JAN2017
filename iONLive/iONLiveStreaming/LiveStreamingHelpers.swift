
import Foundation

class LiveStreamingHelpers: NSObject
{
    let livestreamingManager = LiveStreamingManager()
    let requestManager = RequestManager()
    var currentStreamingTocken:String?
    var streamingStatus:StreamingProtocol?
    var iPhoneLiveStreamingSession:VCSimpleSession?
    
    //PRAGMA MARK:- Create Base Stream
    func getBaseStreamWithToken(streamToken:String , AndUserName userName:String) -> String
    {
        let defaults = UserDefaults .standard
        let userId = defaults.value(forKey: userLoginIdKey) as! String
        
        let baseStream = getProtocol() + "://" + getHost() + ":" + getPort() + "/" + getAppName() +  getUserNameAndToken(streamToken: streamToken, WithUserName: userId)
        
        let streamPath = getProtocol() + "://" + getHost() + ":" + getPort() + "/" + getAppName() + getToken(token: streamToken)
        UserDefaults.standard.set(streamPath, forKey: "LiveStreamUrl")
        return baseStream
    }
    
    func getProtocol() ->String
    {
        return "rtsp"
    }
    
    func getUserNameAndToken(streamToken:String , WithUserName userName:String) ->String
    {
        return "?userName=" + userName + "&token=" + streamToken
    }
    
    func getHost() ->String
    {
        return vowzaIp
    }
    
    func getPort() ->String
    {
        return "1935"
    }
    
    func getAppName() -> String{
        return "live"
    }
    
    func getToken(token:String) -> String{
        return "/" + token
    }
    
    //PRAGMA MARK:- Start Streaming API
    func startStreamingClicked()
    {
        initialiseLiveStreamingToken()
    }
    
    func initialiseLiveStreamingToken()
    {
        let loginId = UserDefaults.standard.object(forKey: userLoginIdKey)
        let accessTocken = UserDefaults.standard.object(forKey: userAccessTockenKey)
        UserDefaults.standard.set(true, forKey: initializingStream)
        
        if let loginId = loginId, let accessTocken = accessTocken
        {
            livestreamingManager.initialiseLiveStreaming(loginId:loginId as! String , tocken:accessTocken as! String, success: { (response) -> () in
                
                if let json = response as? [String: AnyObject]
                {
                    self.currentStreamingTocken = json["streamToken"] as? String
                    self.startLiveStreamingToken(streamTocken: self.currentStreamingTocken)
                }
                else
                {
                    UserDefaults.standard.set(false, forKey: initializingStream)
                    ErrorManager.sharedInstance.inValidResponseError()
                }
                
            }, failure: { (error, message) -> () in
                self.streamingFailed()
                self.handleFailure(message: message)
                return
            })
        }
        else
        {
            UserDefaults.standard.set(false, forKey: initializingStream)
        }
    }
    
    func mapStream()
    {
        self.setDefaultMappingForLiveStream(Tocken: UserDefaults.standard.object(forKey: "streamTocken") as! String)
    }
    
    func startLiveStreamingToken(streamTocken:String?)
    {
        let loginId = UserDefaults.standard.object(forKey: userLoginIdKey)
        let accessTocken = UserDefaults.standard.object(forKey: userAccessTockenKey)
        cleanStreamingToken()
        
        if let loginId = loginId, let accessTocken = accessTocken, let streamTocken = streamTocken
        {
            livestreamingManager.startLiveStreaming(loginId:loginId as! String , accesstocken:accessTocken as! String , streamTocken: streamTocken,success: { (response) -> () in
                
                if let json = response as? [String: AnyObject]
                {
                    let url =  (json["Signed url"]) as! String
                    let defaults = UserDefaults.standard
                    defaults.setValue(url, forKey: "liveStreamURL")
                    let streamToken:String = json["streamToken"] as! String
                    UserDefaults.standard.setValue(streamToken, forKey: "streamTocken")
                    self.updateDefaultsAndStartStreamWithToken(streamToken: streamToken, AndUserName: loginId as! String )
                }
                else
                {
                    self.streamingFailed()
                    ErrorManager.sharedInstance.inValidResponseError()
                }
                
            }, failure: { (error, message) -> () in
                self.streamingFailed()
                self.handleFailure(message: message)
                return
            })
        }
        else
        {
            self.streamingFailed()
        }
    }
    
    func mapLiveStream(){
        let streamToken = UserDefaults.standard.object(forKey: "streamTocken") as! String
        self.setDefaultMappingForLiveStream(Tocken: streamToken)
    }
    
    func setDefaultMappingForLiveStream(Tocken : String)
    {
        let loginId = UserDefaults.standard.object(forKey: userLoginIdKey)as! String
        let accessTocken = UserDefaults.standard.object(forKey: userAccessTockenKey) as! String
        livestreamingManager.defaultStreamMapping(loginId: loginId, accesstocken:accessTocken, streamTockn: Tocken, success: { (response) in
        }) { (error, code) in
        }
    }
    
    //PRAGMA MARK: User Defaults
    func setStreamingDefaults()
    {
        UserDefaults.standard.set(false, forKey: initializingStream)
        UserDefaults.standard.set(true, forKey: startedStreaming)
    }
    
    func streamingFailed()
    {
        UserDefaults.standard.set(false, forKey: initializingStream)
        self.streamingStatus?.updateStreamingStatus!();
    }
    
    func clearStreamingDefaults()
    {
        let defaults = UserDefaults .standard
        defaults.setValue(false, forKey: startedStreaming)
        self.streamingStatus?.updateStreamingStatus!();
    }
    
    func cleanStreamingToken()
    {
        let userDefault = UserDefaults.standard
        userDefault.removeObject(forKey: streamingToken)
        userDefault.removeObject(forKey: startedStreaming)
    }
    
    //PRAGMA MARK:Handlers
    func handleFailure(message:String)
    {
        if !self.requestManager.validConnection() {
            ErrorManager.sharedInstance.noNetworkConnection()
        }
        else if message.isEmpty == false {
            if(message != "STREAM001"){
                if((message == "USER004") || (message == "USER005") || (message == "USER006")){
                    let notificationName = Notification.Name("refreshLogin")
                    NotificationCenter.default.post(name: notificationName, object: self)
                }
                else{
                    ErrorManager.sharedInstance.mapErorMessageToErrorCode(errorCode: message)
                }
            }
        }
        else{
            ErrorManager.sharedInstance.streamingError()
        }
    }
    
    //PRAGMA MARK:- Start iPhone Camera Streaming
    func updateDefaultsAndStartStreamWithToken(streamToken:String , AndUserName userName:String)
    {
        let baseStreamName = self.getBaseStreamWithToken(streamToken: streamToken, AndUserName: userName)
        UserDefaults.standard.setValue(streamToken, forKey: streamingToken)
        self.setStreamingDefaults()
        self.startStreamingWithUrl(url: baseStreamName, andStreamToken: streamToken)
    }
    
    func startStreamingWithUrl(url:String ,andStreamToken streamToken:String)
    {
        if let session = iPhoneLiveStreamingSession
        {
            switch session.rtmpSessionState {
            case .none, .previewStarted, .ended, .error:
                startiPhoneCameraLiveStreamingWithUrl(url: url, andStreamToken: streamToken)
                break
            default:
                stopLiveStreaming()
                break
            }
        }
    }
    
    func startiPhoneCameraLiveStreamingWithUrl(url:String , andStreamToken streamToken:String)
    {
        UIApplication.shared.isIdleTimerDisabled = true
        iPhoneLiveStreamingSession!.startRtmpSession(withURL: url, andStreamKey: streamToken)
    }
    
    //PRAGMA MARK: Stop Live streaming API
    func stopLiveStreaming()
    {
        let iPhoneLiveStreaming = IPhoneLiveStreaming()
        let userDefault = UserDefaults.standard
        let loginId = userDefault.object(forKey: userLoginIdKey)
        let accessTocken = userDefault.object(forKey: userAccessTockenKey)
        let streamTocken = userDefault.object(forKey: streamingToken)
        if let loginId = loginId, let accessTocken = accessTocken, let streamTocken = streamTocken
        {
            livestreamingManager.stopLiveStreaming(loginId:loginId as! String , accesstocken:accessTocken as! String , streamTocken: streamTocken as! String,success: { (response) -> () in
                if (response as? [String: AnyObject]) != nil
                {
                    self.removeStreaming()
                }
                else
                {
                    self.removeStreaming()
                    ErrorManager.sharedInstance.inValidResponseError()
                }
                
            }, failure: { (error, message) -> () in
                if iPhoneLiveStreaming.showAlert
                {
                    self.removeStreaming()
                    self.handleFailure(message: message)
                }
                return
            })
        }
        else
        {
        }
    }
    
    func stopStream()
    {
        if let session = iPhoneLiveStreamingSession
        {
            session.endRtmpSession()
        }
    }
    
    func removeStreaming()
    {
        stopStream()
        clearStreamingDefaults()
    }
}
