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
    
    var streamingStatus:StreamingProtocol?

    override init(){
    }
    
    func startStreamingClicked()
    {
        initialiseLiveStreamingToken()
    }
    
    func stopStreamingClicked()
    {
        stopLiveStreaming()
    }
    
    func initialiseLiveStreamingToken()
    {
        let userDefault = NSUserDefaults.standardUserDefaults()
        let loginId = userDefault.objectForKey(userLoginIdKey)
        let accessTocken = userDefault.objectForKey(userAccessTockenKey)
        userDefault.setBool(true, forKey: initializingStream)
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
                    userDefault.setBool(false, forKey: initializingStream)
                    ErrorManager.sharedInstance.inValidResponseError()
                }
                
                }, failure: { (error, message) -> () in
                    userDefault.setBool(false, forKey: initializingStream)
                    print("message = \(message), error = \(error?.localizedDescription)")
                    if !self.requestManager.validConnection() {
                        ErrorManager.sharedInstance.noNetworkConnection()
                    }
                    else if message.isEmpty == false {
                        ErrorManager.sharedInstance.mapErorMessageToErrorCode(message)
                    }
                    else{
                        ErrorManager.sharedInstance.streamingError()
                    }
                    return
            })
        }
        else
        {
            userDefault.setBool(false, forKey: initializingStream)
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
        let userDefault = NSUserDefaults.standardUserDefaults()
        let loginId = userDefault.objectForKey(userLoginIdKey)
        let accessTocken = userDefault.objectForKey(userAccessTockenKey)
        
        cleanStreamingToken()

        
//        self.steamingStatus?.StreamingStatus("Starting Live Streaming ...");
        if let loginId = loginId, let accessTocken = accessTocken, let streamTocken = streamTocken
        {
            livestreamingManager.startLiveStreaming(loginId:loginId as! String , accesstocken:accessTocken as! String , streamTocken: streamTocken,success: { (response) -> () in

                if let json = response as? [String: AnyObject]
                {
                    print("success = \(json["streamToken"])")
                    let streamToken:String = json["streamToken"] as! String
                    self.InitialiseStream(streamToken)
//                    let baseStreamName = self.getBaseStream(streamToken)
//                    let cameraServerName = self.getCameraServer()
//                    
//                    userDefault.setValue(streamToken, forKey: streamingToken)
//
//                    if (init_streams(cameraServerName, baseStreamName) == 0)
//                    {
//                        userDefault.setBool(false, forKey: streamingInProgress)
//                        userDefault.setBool(true, forKey: startedStreaming)
////                        self.streamingStatus?.StreamingStatus("Success");
//
//                        let queue:dispatch_queue_t = dispatch_queue_create("streaming", DISPATCH_QUEUE_SERIAL)
//                        
//                        dispatch_async(queue, { () -> Void in
//                            self.startStreaming(streamToken)
//                        })
//                    }
//                    else
//                    {
//                        self.stopLiveStreaming()
//                        self.streamingFailed()
////                        userDefault.setBool(false, forKey: streamingInProgress)
////                        self.streamingStatus?.StreamingStatus("Failure");
//                        userDefault.setValue(false, forKey: startedStreaming)
//                        ErrorManager.sharedInstance.alert("Can't Initialise the stream", message: "Can't Initialise the stream")
//                    }
                }
                else
                {
                    self.streamingFailed()

//                    userDefault.setBool(false, forKey: streamingInProgress)
//                    userDefault.removeObjectForKey(streamingToken)
//                    self.streamingStatus?.StreamingStatus("Failure");
                    ErrorManager.sharedInstance.inValidResponseError()
                }
                
                }, failure: { (error, message) -> () in
                    self.streamingFailed()

                    print("message = \(message)")
//                    userDefault.setBool(false, forKey: streamingInProgress)
//                    userDefault.removeObjectForKey(streamingToken)
//                    self.streamingStatus?.StreamingStatus("Failure");
                    if !self.requestManager.validConnection() {
                        ErrorManager.sharedInstance.noNetworkConnection()
                    }
                    else if message.isEmpty == false {
                       ErrorManager.sharedInstance.mapErorMessageToErrorCode(message)
                    }
                    else{
                        ErrorManager.sharedInstance.streamingError()
                    }
                    return
            })
            
        }
        else
        {
            self.streamingFailed()

//            userDefault.setBool(false, forKey: streamingInProgress)
//            userDefault.removeObjectForKey(streamingToken)
//            self.streamingStatus?.StreamingStatus("Failure");
            ErrorManager.sharedInstance.authenticationIssue()
        }
    }
    
    func InitialiseStream(streamToken:String)
    {
        let baseStreamName = self.getBaseStream(streamToken)
        let cameraServerName = self.getCameraServer()
        
        NSUserDefaults.standardUserDefaults().setValue(streamToken, forKey: streamingToken)
        
        if (init_streams(cameraServerName, baseStreamName) == 0)
        {
            NSUserDefaults.standardUserDefaults().setBool(false, forKey: initializingStream)
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: startedStreaming)
            //                        self.streamingStatus?.StreamingStatus("Success");
            
            let queue:dispatch_queue_t = dispatch_queue_create("streaming", DISPATCH_QUEUE_SERIAL)
            
            dispatch_async(queue, { () -> Void in
                self.startStreaming(streamToken)
            })
        }
        else
        {
            self.stopLiveStreaming()
            self.streamingFailed()
            //                        userDefault.setBool(false, forKey: streamingInProgress)
            //                        self.streamingStatus?.StreamingStatus("Failure");
            NSUserDefaults.standardUserDefaults().setValue(false, forKey: startedStreaming)
            ErrorManager.sharedInstance.alert("Can't Initialise the stream", message: "Can't Initialise the stream")
        }
    }
    
    func streamingFailed()
    {
        NSUserDefaults.standardUserDefaults().setBool(false, forKey: initializingStream)
        self.streamingStatus?.StreamingStatus("Failure");
    }
    
    func startStreaming(streamtoken:String)
    {
        let taskId = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler { () -> Void in
            
        }
//        self.streamingStatus?.StreamingStatus("Success");
        let baseStream = self.getBaseStream(streamtoken)
        //        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0))
        //            {
        self.streamingStatus?.StreamingStatus("Success");
        //                            self.steamingStatus?.StreamingStatus("live streaming...");
        let errCode = start_stream(baseStream)
        let defaults = NSUserDefaults .standardUserDefaults()

        if errCode > 0
        {
            defaults.setValue(false, forKey: startedStreaming)
            self.stopLiveStreaming()
        }
        switch errCode
        {
        case 0:
            defaults.setValue(false, forKey: startedStreaming)
            break
        case 1:
//            defaults.setValue(false, forKey: startedStreaming)
            ErrorManager.sharedInstance.alert("Streaming Stopped", message: "Connection error occurs in input stream")
            break
        case 2:
//            defaults.setValue(false, forKey: startedStreaming)
            ErrorManager.sharedInstance.alert("Streaming Stopped", message: "Connection error occurs in output stream")
            break
        default:
//            defaults.setValue(false, forKey: startedStreaming)
            break
        }
        if(taskId != UIBackgroundTaskInvalid)
        {
            UIApplication.sharedApplication().endBackgroundTask(taskId)
            self.clearStreamingDefaults()
        }

    }

    func getBaseStream(streamToken:String) -> UnsafeMutablePointer<CChar>
    {
        var baseStream = "rtsp://ionlive:ion#Ca7hDec11%Live@stream.ioncameras.com:1935/live/"
//        var baseStream = "rtmp://192.168.16.34:1935/live/"
        baseStream.appendContentsOf(streamToken)
        let baseStreamptr = strdup(baseStream.cStringUsingEncoding(NSUTF8StringEncoding)!)
        let baseStreamName: UnsafeMutablePointer<CChar> = UnsafeMutablePointer(baseStreamptr)
        return baseStreamName
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
                    
                    if !self.requestManager.validConnection() {
                        ErrorManager.sharedInstance.noNetworkConnection()
                    }
                    else if message.isEmpty == false {
                        ErrorManager.sharedInstance.mapErorMessageToErrorCode(message)
                    }
                    else{
                        ErrorManager.sharedInstance.streamingError()
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
        self.streamingStatus?.StreamingStatus("");
    }
    
    func removeStreaming()
    {
        clearStreamingDefaults()
        stop_stream()
        print("Live streaming stopped.......")
    }
}