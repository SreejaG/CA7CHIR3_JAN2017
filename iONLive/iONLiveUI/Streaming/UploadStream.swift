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
    
    var steamingStatus:StreamingProtocol?

    override init(){
    }
    
    func startStreamingClicked()
    {
        initialiseLiveStreaming()
    }
    
    func stopStreamingClicked()
    {
        stopLiveStreaming()
    }
    
    func initialiseLiveStreaming()
    {
        let userDefault = NSUserDefaults.standardUserDefaults()
        let loginId = userDefault.objectForKey(userLoginIdKey)
        let accessTocken = userDefault.objectForKey(userAccessTockenKey)
        
        if let loginId = loginId, let accessTocken = accessTocken
        {
            
            livestreamingManager.initialiseLiveStreaming(loginId:loginId as! String , tocken:accessTocken as! String, success: { (response) -> () in
                
                if let json = response as? [String: AnyObject]
                {
                    self.currentStreamingTocken = json["streamToken"] as? String
                    print("success = \(json["streamToken"])")
                    //call start stream api here
                    self.startLiveStreaming(self.currentStreamingTocken)
                }
                else
                {
                    ErrorManager.sharedInstance.inValidResponseError()
                }
                
                }, failure: { (error, message) -> () in
                    
                    print("message = \(message), error = \(error?.localizedDescription)")
                    if !self.requestManager.validConnection() {
                        ErrorManager.sharedInstance.noNetworkConnection()
                    }
                    else if message.isEmpty == false {
                        ErrorManager.sharedInstance.alert("Streaming Error", message:message)
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
    
    func startLiveStreaming(streamTocken:String?)
    {
        let userDefault = NSUserDefaults.standardUserDefaults()
        let loginId = userDefault.objectForKey(userLoginIdKey)
        let accessTocken = userDefault.objectForKey(userAccessTockenKey)
        
        userDefault.removeObjectForKey(streamingToken)
        userDefault.removeObjectForKey(startedStreaming)

//        self.steamingStatus?.StreamingStatus("Starting Live Streaming ...");
        if let loginId = loginId, let accessTocken = accessTocken, let streamTocken = streamTocken
        {
            livestreamingManager.startLiveStreaming(loginId:loginId as! String , accesstocken:accessTocken as! String , streamTocken: streamTocken,success: { (response) -> () in
                
                if let json = response as? [String: AnyObject]
                {
                    print("success = \(json["streamToken"])")
                    let streamToken:String = json["streamToken"] as! String
                    let baseStreamName = self.getBaseStream(streamToken)
                    let cameraServerName = self.getCameraServer()
                    
//                    let defaults = NSUserDefaults .standardUserDefaults()
                    userDefault.setValue(streamToken, forKey: streamingToken)
                    
//                    self.steamingStatus?.StreamingStatus("Initializing Live Streaming...");
                    if (init_streams(cameraServerName, baseStreamName) == 0)
                    {
                        userDefault.setBool(true, forKey: startedStreaming)
                        print("live streaming")
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0))
                        {
                            self.steamingStatus?.StreamingStatus("Success");
//                            self.steamingStatus?.StreamingStatus("live streaming...");
                            start_stream(baseStreamName)
                        }
                    }
                    else
                    {
                        self.steamingStatus?.StreamingStatus("Failure");
                        userDefault.setValue(false, forKey: startedStreaming)
                        ErrorManager.sharedInstance.alert("Can't Initialise the stream", message: "Can't Initialise the stream")
                    }
                    
                }
                else
                {
//                    userDefault.removeObjectForKey(streamingToken)
                    self.steamingStatus?.StreamingStatus("Failure");
                    ErrorManager.sharedInstance.inValidResponseError()
                }
                
                }, failure: { (error, message) -> () in
                    
                    print("message = \(message)")
//                    userDefault.removeObjectForKey(streamingToken)
                    self.steamingStatus?.StreamingStatus("Failure");
                    if !self.requestManager.validConnection() {
                        ErrorManager.sharedInstance.noNetworkConnection()
                    }
                    else if message.isEmpty == false {
                        ErrorManager.sharedInstance.alert("Streaming Error", message:message)
                    }
                    else{
                        ErrorManager.sharedInstance.streamingError()
                    }
                    return
            })
            
        }
        else
        {
//            userDefault.removeObjectForKey(streamingToken)
            self.steamingStatus?.StreamingStatus("Failure");
            ErrorManager.sharedInstance.authenticationIssue()
        }
    }
    
    func getBaseStream(streamToken:String) -> UnsafeMutablePointer<CChar>
    {
        var baseStream = "rtmp://104.197.159.157:1935/live/"
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
                        ErrorManager.sharedInstance.alert("Streaming Error", message:message)
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
    
    func removeStreaming()
    {
        let defaults = NSUserDefaults .standardUserDefaults()
        defaults.setValue(false, forKey: startedStreaming)
        self.steamingStatus?.StreamingStatus("");
        stop_stream()
    }
}