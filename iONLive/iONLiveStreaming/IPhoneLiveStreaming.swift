
//
//  IPhoneLiveStreaming.swift
//  iONLive
//
//  Created by Vinitha on 2/10/16.
//  Copyright © 2016 Gadgeon. All rights reserved.
//

import UIKit

class IPhoneLiveStreaming: NSObject {
    
    var showAlert : Bool = true;
    let liveStreamingHelpers = LiveStreamingHelpers()
    
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
    
    class LiveStreamingHelpers
    {
        let livestreamingManager = LiveStreamingManager()
        let requestManager = RequestManager()
        var currentStreamingTocken:String?
        var streamingStatus:StreamingProtocol?
        var iPhoneLiveStreamingSession:VCSimpleSession?
        
        //PRAGMA MARK:- Create Base Stream
        func getBaseStreamWithToken(streamToken:String , AndUserName userName:String) -> String
        {
            let defaults = NSUserDefaults .standardUserDefaults()
            let userId = defaults.valueForKey(userLoginIdKey) as! String
            
            let baseStream = getProtocol() + "://" + getHost() + ":" + getPort() + "/" + getAppName() +  getUserNameAndToken(streamToken, WithUserName: userId)
            
            let streamPath = getProtocol() + "://" + getHost() + ":" + getPort() + "/" + getAppName() + getToken(streamToken)
            NSUserDefaults.standardUserDefaults().setObject(streamPath, forKey: "LiveStreamUrl")
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
            return "104.154.69.174"
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
            let loginId = NSUserDefaults.standardUserDefaults().objectForKey(userLoginIdKey)
            let accessTocken = NSUserDefaults.standardUserDefaults().objectForKey(userAccessTockenKey)
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: initializingStream)
            
            if let loginId = loginId, let accessTocken = accessTocken
            {
                livestreamingManager.initialiseLiveStreaming(loginId:loginId as! String , tocken:accessTocken as! String, success: { (response) -> () in
                    
                    if let json = response as? [String: AnyObject]
                    {
                        self.currentStreamingTocken = json["streamToken"] as? String
                        print(self.currentStreamingTocken)
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
        
        func startLiveStreamingToken(streamTocken:String?)
        {
            let loginId = NSUserDefaults.standardUserDefaults().objectForKey(userLoginIdKey)
            let accessTocken = NSUserDefaults.standardUserDefaults().objectForKey(userAccessTockenKey)
             print(streamTocken)
                 cleanStreamingToken()
           
            if let loginId = loginId, let accessTocken = accessTocken, let streamTocken = streamTocken
            {
                livestreamingManager.startLiveStreaming(loginId:loginId as! String , accesstocken:accessTocken as! String , streamTocken: streamTocken,success: { (response) -> () in
                    
                    if let json = response as? [String: AnyObject]
                    {
                        let url =  (json["Signed url"]) as! String
                        let defaults = NSUserDefaults .standardUserDefaults()
                        defaults.setValue(url, forKey: "liveStreamURL")
                        
                        let streamToken:String = json["streamToken"] as! String
                         print(streamTocken)
                        NSUserDefaults.standardUserDefaults().setValue(streamToken, forKey: "streamTocken")
                        self.updateDefaultsAndStartStreamWithToken(streamToken, AndUserName: loginId as! String)
                        
                        self.setDefaultMappingForLiveStream(streamTocken)
                    }
                    else
                    {
                        self.streamingFailed()
                        
                        ErrorManager.sharedInstance.inValidResponseError()
                    }
                    
                    }, failure: { (error, message) -> () in
                        
                        self.streamingFailed()
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
        
        func setDefaultMappingForLiveStream(Tocken : String)
        {
            let loginId = NSUserDefaults.standardUserDefaults().objectForKey(userLoginIdKey)as! String
            let accessTocken = NSUserDefaults.standardUserDefaults().objectForKey(userAccessTockenKey) as! String
            livestreamingManager.defaultStreamMapping(loginId: loginId, accesstocken:accessTocken, streamTockn: Tocken, success: { (response) in
                
            }) { (error, code) in
            }
        }
        
        //PRAGMA MARK: User Defaults
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
        
        func clearStreamingDefaults()
        {
            let defaults = NSUserDefaults .standardUserDefaults()
            defaults.setValue(false, forKey: startedStreaming)
            self.streamingStatus?.updateStreamingStatus!();
        }
        
        func cleanStreamingToken()
        {
            let userDefault = NSUserDefaults.standardUserDefaults()
            userDefault.removeObjectForKey(streamingToken)
            userDefault.removeObjectForKey(startedStreaming)
        }
        
        //PRAGMA MARK:Handlers
        func handleFailure(message:String)
        {
            if !self.requestManager.validConnection() {
                ErrorManager.sharedInstance.noNetworkConnection()
            }
            else if message.isEmpty == false {
                if(message != "STREAM001"){
                    ErrorManager.sharedInstance.mapErorMessageToErrorCode(message)
                }
            }
            else{
                ErrorManager.sharedInstance.streamingError()
            }
        }
        
        //PRAGMA MARK:- Start iPhone Camera Streaming
        func updateDefaultsAndStartStreamWithToken(streamToken:String , AndUserName userName:String)
        {
            let baseStreamName = self.getBaseStreamWithToken(streamToken, AndUserName: userName)
            
            NSUserDefaults.standardUserDefaults().setValue(streamToken, forKey: streamingToken)
            
            self.setStreamingDefaults()
            self.startStreamingWithUrl(baseStreamName, andStreamToken: streamToken)
        }
        
        func startStreamingWithUrl(url:String ,andStreamToken streamToken:String)
        {
            
            if let session = iPhoneLiveStreamingSession
            {
                switch session.rtmpSessionState {
                    
                case .None, .PreviewStarted, .Ended, .Error:
                    startiPhoneCameraLiveStreamingWithUrl(url, andStreamToken: streamToken)
                    break
                default:
                    stopLiveStreaming()
                    break
                }
            }
        }
        
        func startiPhoneCameraLiveStreamingWithUrl(url:String , andStreamToken streamToken:String)
        {
            UIApplication.sharedApplication().idleTimerDisabled = true
            iPhoneLiveStreamingSession!.startRtmpSessionWithURL(url, andStreamKey: streamToken)
        }
        
        //PRAGMA MARK: Stop Live streaming API
        func stopLiveStreaming()
        {
            let iPhoneLiveStreaming = IPhoneLiveStreaming()
            let userDefault = NSUserDefaults.standardUserDefaults()
            let loginId = userDefault.objectForKey(userLoginIdKey)
            let accessTocken = userDefault.objectForKey(userAccessTockenKey)
            let streamTocken = userDefault.objectForKey(streamingToken)
            if let loginId = loginId, let accessTocken = accessTocken, let streamTocken = streamTocken
            {
                livestreamingManager.stopLiveStreaming(loginId:loginId as! String , accesstocken:accessTocken as! String , streamTocken: streamTocken as! String,success: { (response) -> () in
                    if let json = response as? [String: AnyObject]
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
                            self.handleFailure(message)
                        }
                        return
                })
            }
            else
            {
//                self.removeStreaming()
                ErrorManager.sharedInstance.authenticationIssue()
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
            print("Live streaming stopped.......")
        }
    }
}
