
import Foundation

class UploadStream : NSObject
{
    let livestreamingManager = LiveStreamingManager()
    let requestManager = RequestManager()
    var currentStreamingTocken:String?
    var showAlert : Bool = true;
    var streamingStatus:StreamingProtocol?
    
    override init(){
    }
    
    func startStreamingClicked()
    {
        initialiseLiveStreamingToken()
    }
    
    func stopStreamingClicked()
    {
        showAlert = true;
        stopLiveStreaming()
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
            ErrorManager.sharedInstance.authenticationIssue()
        }
    }
    
    func cleanStreamingToken()
    {
        let userDefault = UserDefaults.standard
        userDefault.removeObject(forKey: streamingToken)
        userDefault.removeObject(forKey: startedStreaming)
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
                    let streamToken:String = json["streamToken"] as! String
                    self.InitialiseStreamWithToken(streamToken: streamToken)
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
            ErrorManager.sharedInstance.authenticationIssue()
        }
    }
    
    func handleFailure(message:String)
    {
        if !self.requestManager.validConnection() {
            ErrorManager.sharedInstance.noNetworkConnection()
        }
        else if message.isEmpty == false {
            ErrorManager.sharedInstance.mapErorMessageToErrorCode(errorCode: message)
        }
        else{
            ErrorManager.sharedInstance.streamingError()
        }
    }
    
    func InitialiseStreamWithToken(streamToken:String)
    {
        let baseStreamName = self.getBaseStream(streamToken: streamToken)
        let cameraServerName = self.getCameraServer()
        
        UserDefaults.standard.setValue(streamToken, forKey: streamingToken)
        
        if (init_streams(cameraServerName, baseStreamName) == 0)
        {
            
            self.setStreamingDefaults()
            let queue = DispatchQueue(label: "streaming")
            queue.async {
                self.startStreamingWithToken(streamtoken: streamToken)
            }
        }
        else
        {
            showAlert = false
            self.stopLiveStreaming()
            self.streamingFailed()
            UserDefaults.standard.setValue(false, forKey: startedStreaming)
            ErrorManager.sharedInstance.alert(title: "Can't Initialise the stream", message: "Can't Initialise the stream")
        }
    }
    
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
    
    func startStreamingWithToken(streamtoken:String)
    {
        let taskId = UIApplication.shared.beginBackgroundTask {
            
        }
        self.startStreamAndHandleInterruption(streamtoken: streamtoken)
        if(taskId != UIBackgroundTaskInvalid)
        {
            UIApplication.shared.endBackgroundTask(taskId)
            self.clearStreamingDefaults()
        }
    }
    
    func startStreamAndHandleInterruption(streamtoken:String)
    {
        self.streamingStatus?.updateStreamingStatus!();
        
        let errCode = start_stream()
        let defaults = UserDefaults.standard
        
        if errCode > 0
        {
            defaults.setValue(false, forKey: startedStreaming)
            showAlert = false
            self.stopLiveStreaming()
        }
        switch errCode
        {
        case 0:
            defaults.setValue(false, forKey: startedStreaming)
            break
        case 1:
            ErrorManager.sharedInstance.alert(title: "Streaming Stopped", message: "Connection error occurs in input stream")
            break
        case 2:
            ErrorManager.sharedInstance.alert(title: "Streaming Stopped", message: "Connection error occurs in output stream")
            break
        default:
            break
        }
    }
    
    func getBaseStream(streamToken:String) -> UnsafeMutablePointer<CChar>
    {
        var baseStream = getProtocol() + "://" + getUserName() + ":" + getPassword() + "@" + getMainStream() + "." + getSubStream() + ".com" + ":" + getRTSPPort() + "/live/"
        baseStream.append(streamToken)
        let baseStreamptr = strdup(baseStream.cString(using: String.Encoding.utf8)!)
        let baseStreamName: UnsafeMutablePointer<CChar> = UnsafeMutablePointer(baseStreamptr!)
        return baseStreamName
    }
    
    func getProtocol()->String
    {
        return "rtsp"
    }
    
    func getUserName()->String
    {
        return "ionlive"
    }
    
    func getPassword()->String
    {
        return "ion#Ca7hDec11%Live"
    }
    
    func getRTSPPort()->String
    {
        return "1935"
    }
    
    func getMainStream()->String
    {
        return "stream"
    }
    
    func getSubStream()->String
    {
        return "ioncameras"
    }
    
    func getCameraServer() -> UnsafeMutablePointer<CChar>
    {
        let cameraServer = "rtsp://\(vowzaIp):1935/live"
        let cameraServerPtr = strdup(cameraServer.cString(using: String.Encoding.utf8)!)
        let cameraServerName :UnsafeMutablePointer<CChar> = UnsafeMutablePointer(cameraServerPtr!)
        return cameraServerName
    }
    
    func stopLiveStreaming()
    {
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
                    ErrorManager.sharedInstance.inValidResponseError()
                }
                
            }, failure: { (error, message) -> () in
                if self.showAlert
                {
                    self.handleFailure(message: message)
                }
                return
            })
        }
        else
        {
            ErrorManager.sharedInstance.authenticationIssue()
        }
    }
    
    func clearStreamingDefaults()
    {
        let defaults = UserDefaults.standard
        defaults.setValue(false, forKey: startedStreaming)
        self.streamingStatus?.updateStreamingStatus!();
    }
    
    func removeStreaming()
    {
        clearStreamingDefaults()
        stop_stream()
    }
}
