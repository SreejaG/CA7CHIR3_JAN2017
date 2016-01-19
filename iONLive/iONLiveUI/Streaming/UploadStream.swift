//
//  UploadStream.swift
//  iONLive
//
//  Created by Vinitha on 12/2/15.
//  Copyright © 2015 Gadgeon. All rights reserved.
//

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
        let loginId = NSUserDefaults.standardUserDefaults().objectForKey(userLoginIdKey)
        let accessTocken = NSUserDefaults.standardUserDefaults().objectForKey(userAccessTockenKey)
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: initializingStream)
        
        if let loginId = loginId, let accessTocken = accessTocken
        {
            
            livestreamingManager.initialiseLiveStreaming(loginId:loginId as! String , tocken:accessTocken as! String, success: { (response) -> () in
                
                if let json = response as? [String: AnyObject]
                {
                    self.currentStreamingTocken = json["streamToken"] as? String
                    print("success = \(json["streamToken"])")
                    //call start stream api here
                    self.startLiveStreamingToken(self.currentStreamingTocken)
                }
                else
                {
                    NSUserDefaults.standardUserDefaults().setBool(false, forKey: initializingStream)
                    ErrorManager.sharedInstance.inValidResponseError()
                }
                
                }, failure: { (error, message) -> () in
                    self.streamingFailed()
                    print("message = \(message), error = \(error?.localizedDescription)")
                    self.handleFailure(message)
                    return
            })
        }
        else
        {
            NSUserDefaults.standardUserDefaults().setBool(false, forKey: initializingStream)
            ErrorManager.sharedInstance.authenticationIssue()
        }
    }
    
    func cleanStreamingToken()
    {
        let userDefault = NSUserDefaults.standardUserDefaults()
        userDefault.removeObjectForKey(streamingToken)
        userDefault.removeObjectForKey(startedStreaming)
    }
    
    func startLiveStreamingToken(streamTocken:String?)
    {
        let loginId = NSUserDefaults.standardUserDefaults().objectForKey(userLoginIdKey)
        let accessTocken = NSUserDefaults.standardUserDefaults().objectForKey(userAccessTockenKey)
        
        cleanStreamingToken()

        if let loginId = loginId, let accessTocken = accessTocken, let streamTocken = streamTocken
        {
            livestreamingManager.startLiveStreaming(loginId:loginId as! String , accesstocken:accessTocken as! String , streamTocken: streamTocken,success: { (response) -> () in

                if let json = response as? [String: AnyObject]
                {
                    print("success = \(json["streamToken"])")
                    let streamToken:String = json["streamToken"] as! String
                    self.InitialiseStreamWithToken(streamToken)
                }
                else
                {
                    self.streamingFailed()

                    ErrorManager.sharedInstance.inValidResponseError()
                }
                
                }, failure: { (error, message) -> () in
                    
                    self.streamingFailed()

                    print("message = \(message)")
                    self.handleFailure(message)
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
            ErrorManager.sharedInstance.mapErorMessageToErrorCode(message)
        }
        else{
            ErrorManager.sharedInstance.streamingError()
        }
    }
    
    func InitialiseStreamWithToken(streamToken:String)
    {
        let baseStreamName = self.getBaseStream(streamToken)
        let cameraServerName = self.getCameraServer()
        
        NSUserDefaults.standardUserDefaults().setValue(streamToken, forKey: streamingToken)
        
        if (init_streams(cameraServerName, baseStreamName) == 0)
        {
            self.setStreamingDefaults()
            let queue:dispatch_queue_t = dispatch_queue_create("streaming", DISPATCH_QUEUE_SERIAL)
            
            dispatch_async(queue, { () -> Void in
                self.startStreamingWithToken(streamToken)
            })
        }
        else
        {
            showAlert = false
            self.stopLiveStreaming()
            self.streamingFailed()
            
            NSUserDefaults.standardUserDefaults().setValue(false, forKey: startedStreaming)
            ErrorManager.sharedInstance.alert("Can't Initialise the stream", message: "Can't Initialise the stream")
        }
    }
    
    func setStreamingDefaults()
    {
        NSUserDefaults.standardUserDefaults().setBool(false, forKey: initializingStream)
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: startedStreaming)
    }
    
    func streamingFailed()
    {
        NSUserDefaults.standardUserDefaults().setBool(false, forKey: initializingStream)
        self.streamingStatus?.updateStreamingStatus!();
    }
    
    func startStreamingWithToken(streamtoken:String)
    {
        let taskId = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler { () -> Void in
            
        }
        
        self.startStreamAndHandleInterruption(streamtoken)
        if(taskId != UIBackgroundTaskInvalid)
        {
            UIApplication.sharedApplication().endBackgroundTask(taskId)
            self.clearStreamingDefaults()
        }

    }

    func startStreamAndHandleInterruption(streamtoken:String)
    {
        self.streamingStatus?.updateStreamingStatus!();

        let errCode = start_stream()
        let defaults = NSUserDefaults .standardUserDefaults()
        
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
            ErrorManager.sharedInstance.alert("Streaming Stopped", message: "Connection error occurs in input stream")
            break
        case 2:
            ErrorManager.sharedInstance.alert("Streaming Stopped", message: "Connection error occurs in output stream")
            break
        default:
            break
        }
    }
    
    func getBaseStream(streamToken:String) -> UnsafeMutablePointer<CChar>
    {
//        var baseStream = "rtsp://ionlive:ion#Ca7hDec11%Live@stream.ioncameras.com:1935/live/"
        var baseStream = getProtocol() + "://" + getUserName() + ":" + getPassword() + "@" + getMainStream() + "." + getSubStream() + ".com" + ":" + getRTSPPort() + "/live/"
        
        print("baseStream/", baseStream)
        
        baseStream.appendContentsOf(streamToken)
        let baseStreamptr = strdup(baseStream.cStringUsingEncoding(NSUTF8StringEncoding)!)
        let baseStreamName: UnsafeMutablePointer<CChar> = UnsafeMutablePointer(baseStreamptr)
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
        let cameraServer = "rtsp://192.168.42.1:554/live"
        let cameraServerPtr = strdup(cameraServer.cStringUsingEncoding(NSUTF8StringEncoding)!)
        let cameraServerName :UnsafeMutablePointer<CChar> = UnsafeMutablePointer(cameraServerPtr)
        return cameraServerName
    }
    
    func stopLiveStreaming()
    {
        let userDefault = NSUserDefaults.standardUserDefaults()
        let loginId = userDefault.objectForKey(userLoginIdKey)
        let accessTocken = userDefault.objectForKey(userAccessTockenKey)
        let streamTocken = userDefault.objectForKey(streamingToken) 
        print("LoginId \(loginId)")
        print("accessTocken \(accessTocken)")
        print("streamTocken \(streamTocken)")
        
        if let loginId = loginId, let accessTocken = accessTocken, let streamTocken = streamTocken
        {
            livestreamingManager.stopLiveStreaming(loginId:loginId as! String , accesstocken:accessTocken as! String , streamTocken: streamTocken as! String,success: { (response) -> () in
                
                if let json = response as? [String: AnyObject]
                {
                    self.removeStreaming()
                    print("success = \(json["streamToken"])")
                }
                else
                {
                    ErrorManager.sharedInstance.inValidResponseError()
                }
                
                }, failure: { (error, message) -> () in
                    
                    print("message = \(message)")
                    if self.showAlert
                    {
                        self.handleFailure(message)
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
        let defaults = NSUserDefaults .standardUserDefaults()
        defaults.setValue(false, forKey: startedStreaming)
        self.streamingStatus?.updateStreamingStatus!();
    }
    
    func removeStreaming()
    {
        clearStreamingDefaults()
        stop_stream()
        print("Live streaming stopped.......")
    }
}