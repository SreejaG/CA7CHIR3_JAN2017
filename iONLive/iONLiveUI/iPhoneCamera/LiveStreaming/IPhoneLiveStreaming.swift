
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
//        liveStreamingHelpers.startiPhoneCameraLiveStreamingWithUrl("", andStreamToken: "")
        liveStreamingHelpers.startStreamingClicked()
    }
    
    func stopStreamingClicked()
    {
        showAlert = true;
//        liveStreamingHelpers.removeStreaming()
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
        func getBaseStream() -> String
        {
            //        var baseStream = rtmp://ipaddress/applname/streamname?username
            //rtsp://localhost:1935/live/sdfgsdfsfsfsfsdfsdfsf?userName=test3@ionlive.com
            let baseStream = getProtocol() + "://" + getHost() + ":" + getPort() + "/" + getAppName()
            
            print("baseStream/", baseStream)
            return baseStream
        }
        
        
        func getProtocol() ->String
        {
            return "rtsp"
        }
        
        func updateStreamName(streamToken:String , WithUserName userName:String) ->String
        {
            //sdfgsdfsfsfsfsdfsdfsf?userName=test3@ionlive.com
            return streamToken + "?userName=" + userName
        }
        
        func getHost() ->String
        {
            //return 192.168.16.12
            return "192.168.16.33"
        }
        
        func getPort() ->String
        {
            return "1935"
        }
        
        func getAppName() -> String{
            return "live"
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
                print(loginId as! String)
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
                        self.updateDefaultsAndStartStreamWithToken(streamToken)
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
                ErrorManager.sharedInstance.mapErorMessageToErrorCode(message)
            }
            else{
                ErrorManager.sharedInstance.streamingError()
            }
        }
        
        //PRAGMA MARK:- Start iPhone Camera Streaming
        func updateDefaultsAndStartStreamWithToken(streamToken:String)
        {
            let baseStreamName = self.getBaseStream()
            
            //rtsp://localhost:1935/live/sdfgsdfsfsfsfsdfsdfsf?userName=test3@ionlive.com
            
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
            
//            let testUrl  = "rtsp://192.168.16.33:1935/live";
            let test = "rtsp://192.168.16.12:1935/live?userName=test3@ionlive.com_fdsfsfsdfsdfsdfsdf"
            
//            let updatedStreamName = streamToken + "?" + getUserName()
//            print("Updated Stream Name = \(updatedStreamName)")
            iPhoneLiveStreamingSession!.startRtmpSessionWithURL(test, andStreamKey: "fdsfsfsdfsdfsdfsdf-")
        }

        //PRAGMA MARK: Handle Interruption
        func startStreamAndHandleInterruption(streamtoken:String)
        {
            self.streamingStatus?.updateStreamingStatus!();
            let iPhoneLiveStreaming = IPhoneLiveStreaming()
            let errCode = start_stream()
            let defaults = NSUserDefaults .standardUserDefaults()
            
            if errCode > 0
            {
                defaults.setValue(false, forKey: startedStreaming)
                iPhoneLiveStreaming.showAlert = false
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
                        print("success = \(json["streamToken"])")
                    }
                    else
                    {
                        ErrorManager.sharedInstance.inValidResponseError()
                    }
                    
                    }, failure: { (error, message) -> () in
                        
                        print("message = \(message)")
                        if iPhoneLiveStreaming.showAlert
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
        
        func stopStream()
        {
            if let session = iPhoneLiveStreamingSession
            {
                session.endRtmpSession()
            }
        }
        
        func removeStreaming()
        {
            clearStreamingDefaults()
            stopStream()
            print("Live streaming stopped.......")
        }
    }
}
