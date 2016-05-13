
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
            
          //  rtsp://stream.ioncameras.com:1935/live/
            
      //     let baseStream  = "rtsp://192.168.16.44:1935/live?userName=remya123&token=in7bmn7x14610637429891"
            
            let defaults = NSUserDefaults .standardUserDefaults()
            let userId = defaults.valueForKey(userLoginIdKey) as! String
            
           let baseStream = getProtocol() + "://" + getHost() + ":" + getPort() + "/" + getAppName() +  getUserNameAndToken(streamToken, WithUserName: userId)
            
            let streamPath = getProtocol() + "://" + getHost() + ":" + getPort() + "/" + getAppName() + getToken(streamToken)
            print(streamPath)
            NSUserDefaults.standardUserDefaults().setObject(streamPath, forKey: "LiveStreamUrl")
        
            print("baseStream/", baseStream)
            return baseStream
        }
        
        
        func getProtocol() ->String
        {
            return "rtsp"
        }
        
        func getUserNameAndToken(streamToken:String , WithUserName userName:String) ->String
        {
            //sdfgsdfsfsfsfsdfsdfsf?userName=test3@ionlive.com
            return "?userName=" + userName + "&token=" + streamToken
            
          //  return "?userName=remya123&token=in7bmn7x14610637429891"
        }
        
        func getHost() ->String
        {
         //   return "192.168.16.44"
            
          //  return "104.196.113.133"
            
//            return "104.196.15.240"
            return "104.154.69.174"
            
            //return 192.168.16.12
//            return "stream.ioncameras.com"
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
          //  return "/in7bmn7x14610637429891"
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
            
       //     cleanStreamingToken()
            
            if let loginId = loginId, let accessTocken = accessTocken, let streamTocken = streamTocken
            {
                livestreamingManager.startLiveStreaming(loginId:loginId as! String , accesstocken:accessTocken as! String , streamTocken: streamTocken,success: { (response) -> () in
                    
                    if let json = response as? [String: AnyObject]
                    {
                    
                        print("success = \(json["streamToken"])")
                        
                        let url =  (json["Signed url"]) as! String
                        let defaults = NSUserDefaults .standardUserDefaults()
                        defaults.setValue(url, forKey: "liveStreamURL")
                                        
                        let streamToken:String = json["streamToken"] as! String
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
        func setDefaultMappingForLiveStream(Tocken : String)
        {
            let loginId = NSUserDefaults.standardUserDefaults().objectForKey(userLoginIdKey)as! String
            let accessTocken = NSUserDefaults.standardUserDefaults().objectForKey(userAccessTockenKey) as! String
            livestreamingManager.defaultStreamMapping(loginId: loginId, accesstocken:accessTocken, streamTockn: Tocken, success: { (response) in
               
                }) { (error, code) in
                    
                    
            }
 
        }
        
//        func  saveLiveThumbNailToCloud(url: String, completion: (result: String) -> Void)
//        {
//            var imageForLive : UIImage = UIImage()
//            let defaults = NSUserDefaults .standardUserDefaults()
//            let userId = defaults.valueForKey(userLoginIdKey) as! String
//            let parentPath = FileManagerViewController.sharedInstance.getParentDirectoryPath()
//            let savingPath = "\(parentPath)/\(userId)LiveThumb"
//            print(savingPath)
//            let fileExistFlag = FileManagerViewController.sharedInstance.fileExist(savingPath)
//            if fileExistFlag == true{
//                imageForLive = FileManagerViewController.sharedInstance.getImageFromFilePath(savingPath)!
//                let imageData = UIImageJPEGRepresentation(imageForLive, 0.5)
//                let request = NSMutableURLRequest(URL: NSURL(string: url as String)!)
//                request.HTTPMethod = "PUT"
//                let session = NSURLSession(configuration:NSURLSessionConfiguration.defaultSessionConfiguration(), delegate: self, delegateQueue: NSOperationQueue.mainQueue())
//                request.HTTPBody = imageData
//                let dataTask = session.dataTaskWithRequest(request) { (data, response, error) -> Void in
//                    if error != nil {
//                        //handle error
//                    }
//                    else {
//                        let jsonStr = NSString(data: data!, encoding: NSUTF8StringEncoding)
//                        print("Parsed JSON for thumbanil: '\(jsonStr)'")
//                        let controller = PhotoViewerInstance.iphoneCam as! IPhoneCameraViewController
//                        controller.uploadprogress(1.0)
//                        
//                    }
//                }
//                completion(result:"Success")
//                dataTask.resume()
//            }
//        }


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
            
//            let test = "rtsp://104.196.113.133:1935/live?userName=test3@ionlive.com&token=fdsfsfsdfsdfsdfsdf"
            
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
            
            print(loginId as! String)
            print(accessTocken as! String)
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
