//
//  UploadStreamViewController.swift
//  iON_Live
//
//  Created by Gadgeon on 11/18/15.
//  Copyright © 2015 Gadgeon. All rights reserved.
//

import UIKit

class UploadStreamViewController: UIViewController {
    static let identifier = "UploadStreamViewController"
    
    @IBOutlet weak var streamingStatuslabel: UILabel!
    @IBOutlet weak var startStreamingButon: UIButton!
    @IBOutlet weak var stopStreamingButton: UIButton!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    let livestreamingManager = LiveStreamingManager()
    let requestManager = RequestManager()
    var currentStreamingTocken:String?
    
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        initialize()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        self.navigationController?.navigationBarHidden = false
    }
    
    func initialize()
    {
        self.title = "LIVE STREAM"
        streamingStatuslabel.hidden = true
        activityIndicator.hidden = true
        currentStreamingTocken = nil
        
        setStartStreamingButtonEnability(true)
        setStopStreamingButtonEnability(false)
    }
    
    //PRAGMA MARK:- button actions
    @IBAction func startStreamingClicked(sender: AnyObject)
    {
        setStartStreamingButtonEnability(false)
        setStopStreamingButtonEnability(true)
        initialiseLiveStreaming()
        
    }

    @IBAction func stopStreamingClicked(sender: AnyObject)
    {
        streamingStatuslabel.hidden = true
        setStartStreamingButtonEnability(false)
        setStopStreamingButtonEnability(false)
        stopLiveStreaming(self.currentStreamingTocken)
    }
    
   //PRAGMA MARK :- API Helper
    
    func initialiseLiveStreaming()
    {
        let userDefault = NSUserDefaults.standardUserDefaults()
        let loginId = userDefault.objectForKey(userLoginIdKey)
        let accessTocken = userDefault.objectForKey(userAccessTockenKey)
        
        if let loginId = loginId, let accessTocken = accessTocken
        {
            streamingStatuslabel.hidden = false
            activityIndicator.hidden = false
            streamingStatuslabel.text = "Initializing Live Streaming.."
            
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
                    self.streamingFailureUIUpdatesHandler()
                    ErrorManager.sharedInstance.inValidResponseError()
                }
                
                }, failure: { (error, message) -> () in
                     self.streamingFailureUIUpdatesHandler()
                    
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
            setStartStreamingButtonEnability(true)
            setStopStreamingButtonEnability(false)
            ErrorManager.sharedInstance.authenticationIssue()
        }
    }
    
    func startLiveStreaming(streamTocken:String?)
    {
        let userDefault = NSUserDefaults.standardUserDefaults()
        let loginId = userDefault.objectForKey(userLoginIdKey)
        let accessTocken = userDefault.objectForKey(userAccessTockenKey)

        if let loginId = loginId, let accessTocken = accessTocken, let streamTocken = streamTocken
        {
            streamingStatuslabel.text = "Starting Live Streaming.."
            livestreamingManager.startLiveStreaming(loginId:loginId as! String , accesstocken:accessTocken as! String , streamTocken: streamTocken,success: { (response) -> () in
                
                self.streamingStatuslabel.text = "Live Streaming.."
                
                if let json = response as? [String: AnyObject]
                {
                    print("success = \(json["streamToken"])")
                    let streamToken:String = json["streamToken"] as! String
                    var baseStream = "rtmp://104.197.159.157:1935/live/"
                    baseStream.appendContentsOf(streamToken)
                    print("baseStream\(baseStream)")
                    
                    let fromServer = "rtsp://192.168.42.1:554/live"
                    let fromServerPtr = strdup(fromServer.cStringUsingEncoding(NSUTF8StringEncoding)!)
                    let fromServerName :UnsafeMutablePointer<CChar> = UnsafeMutablePointer(fromServerPtr)
                    
                    let baseStreamptr = strdup(baseStream.cStringUsingEncoding(NSUTF8StringEncoding)!)
                    let baseStreamName: UnsafeMutablePointer<CChar> = UnsafeMutablePointer(baseStreamptr)
                    


                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0))
                    {
                        if (init_streams(fromServerName, baseStreamName) == 0)
                        {
                            start_stream(baseStreamName)
                        }
                        else
                        {
                            ErrorManager.sharedInstance.alert("Can't Initialise the stream", message: "Can't Initialise the stream")
                        }
                        
                    }
                }
                else
                {
                    self.streamingFailureUIUpdatesHandler()
                    ErrorManager.sharedInstance.inValidResponseError()
                }
                
                }, failure: { (error, message) -> () in
                     self.streamingFailureUIUpdatesHandler()
                    
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
            self.streamingFailureUIUpdatesHandler()
            ErrorManager.sharedInstance.authenticationIssue()
        }
    }
    
    func stopLiveStreaming(streamTocken:String?)
    {
        let userDefault = NSUserDefaults.standardUserDefaults()
        let loginId = userDefault.objectForKey(userLoginIdKey)
        let accessTocken = userDefault.objectForKey(userAccessTockenKey)
        
        if let loginId = loginId, let accessTocken = accessTocken, let streamTocken = streamTocken
        {
            self.activityIndicator.hidden = false
            livestreamingManager.stopLiveStreaming(loginId:loginId as! String , accesstocken:accessTocken as! String , streamTocken: streamTocken,success: { (response) -> () in
                
                self.activityIndicator.hidden = true
                if let json = response as? [String: AnyObject]
                {
                    self.setStartStreamingButtonEnability(true)
                    self.setStopStreamingButtonEnability(false)
                    
                    stop_stream()
                    
                    print("success = \(json["streamToken"])")
                }
                else
                {
                    ErrorManager.sharedInstance.inValidResponseError()
                    self.setStartStreamingButtonEnability(false)
                    self.setStopStreamingButtonEnability(true)
                }
                
                }, failure: { (error, message) -> () in
                    self.setStartStreamingButtonEnability(false)
                    self.setStopStreamingButtonEnability(true)
                    
                    self.activityIndicator.hidden = true
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
            self.setStartStreamingButtonEnability(false)
            self.setStopStreamingButtonEnability(true)
            ErrorManager.sharedInstance.authenticationIssue()
        }
    }
    
// PRAGMA MARK :- Helper functions
    
    func setStartStreamingButtonEnability(enability:Bool)
    {
        if enability
        {
            startStreamingButon.enabled = true
            startStreamingButon.alpha = 1.0
        }
        else
        {
            startStreamingButon.enabled = false
            startStreamingButon.alpha = 5.0
        }
    }
    
    func setStopStreamingButtonEnability(enability:Bool)
    {
        if enability
        {
            stopStreamingButton.enabled = true
            stopStreamingButton.alpha = 1.0
        }
        else
        {
            stopStreamingButton.enabled = false
            stopStreamingButton.alpha = 5.0
        }
    }
    
    func streamingFailureUIUpdatesHandler()
    {
        self.activityIndicator.hidden = true
        self.streamingStatuslabel.hidden = true
        self.setStartStreamingButtonEnability(true)
        self.setStopStreamingButtonEnability(false)
    }
    
    
    deinit
    {
        currentStreamingTocken = nil
    }
}
