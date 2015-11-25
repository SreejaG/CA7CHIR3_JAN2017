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
    
    func initialize()
    {
        self.title = "LIVE STREAM"
        streamingStatuslabel.hidden = true
        activityIndicator.hidden = true
        currentStreamingTocken = nil
        
        startStreamingButon.enabled = true
        startStreamingButon.backgroundColor = UIColor(red: 51.0/225, green: 207.0/225, blue: 224.0/225, alpha: 1.0)
        stopStreamingButton.enabled = false
        stopStreamingButton.backgroundColor = UIColor(red: 240.0/225, green: 53.0/225, blue: 61.0/225, alpha: 0.5)
        
    }
    
    func modifyButtonEnability(inout button:UIButton,enability:Bool)
    {
        button.enabled = enability
        if(enability)
        {
            button.alpha = 1.0
        }
        else
        {
            button.alpha = 0.5
        }
    }
    
    //PRAGMA MARK:- button actions
    @IBAction func startStreamingClicked(sender: AnyObject)
    {
       //startStreamingButon.userInteractionEnabled = false
       stopStreamingButton.enabled = true
       stopStreamingButton.alpha = 1.0
        
        startStreamingButon.enabled = false
        startStreamingButon.alpha = 0.5
       initialiseLiveStreaming()
    }

    @IBAction func stopStreamingClicked(sender: AnyObject)
    {
        //startStreamingButon.userInteractionEnabled = true
        streamingStatuslabel.hidden = true
        
        stopStreamingButton.enabled = false
        stopStreamingButton.alpha = 0.5
        
        startStreamingButon.enabled = false
        startStreamingButon.alpha = 0.5
        stopLiveStreaming(self.currentStreamingTocken)
    }
    
    
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
                    self.activityIndicator.hidden = true
                    self.streamingStatuslabel.hidden = true
                    ErrorManager.sharedInstance.inValidResponseError()
                    self.stopStreamingButton.enabled = false
                    self.stopStreamingButton.alpha = 0.5
                    
                    self.startStreamingButon.enabled = true
                    self.startStreamingButon.alpha = 1.0
                }
                
                }, failure: { (error, message) -> () in
                    
                    self.activityIndicator.hidden = true
                    self.streamingStatuslabel.hidden = true
                    self.stopStreamingButton.enabled = false
                    self.stopStreamingButton.alpha = 0.5
                    
                    self.startStreamingButon.enabled = true
                    self.startStreamingButon.alpha = 1.0
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
            stopStreamingButton.enabled = false
            stopStreamingButton.alpha = 0.5
            
            startStreamingButon.enabled = true
            startStreamingButon.alpha = 1.0
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
                
                //TODO :- when uploading to wowza completed or camera connection lost etc hide the indicators
                
                if let json = response as? [String: AnyObject]
                {
                    print("success = \(json["streamToken"])")
                }
                else
                {
                    self.stopStreamingButton.enabled = false
                    self.stopStreamingButton.alpha = 0.5
                    
                    self.startStreamingButon.enabled = true
                    self.startStreamingButon.alpha = 1.0
                    self.activityIndicator.hidden = true
                    self.streamingStatuslabel.hidden = true
                    ErrorManager.sharedInstance.inValidResponseError()
                }
                
                }, failure: { (error, message) -> () in
                    
                    self.activityIndicator.hidden = true
                    self.streamingStatuslabel.hidden = true
                    self.stopStreamingButton.enabled = false
                    self.stopStreamingButton.alpha = 0.5
                    
                    self.startStreamingButon.enabled = true
                    self.startStreamingButon.alpha = 1.0
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
            self.activityIndicator.hidden = true
            self.streamingStatuslabel.hidden = true
            self.stopStreamingButton.enabled = false
            self.stopStreamingButton.alpha = 0.5
            
            self.startStreamingButon.enabled = true
            self.startStreamingButon.alpha = 1.0
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
                    self.stopStreamingButton.enabled = false
                    self.stopStreamingButton.alpha = 0.5
                    self.startStreamingButon.enabled = true
                    self.startStreamingButon.alpha = 1.0
                    
                    print("success = \(json["streamToken"])")
                }
                else
                {
                    ErrorManager.sharedInstance.inValidResponseError()
                    
                    self.stopStreamingButton.enabled = true
                    self.stopStreamingButton.alpha = 1.0
                    self.startStreamingButon.enabled = false
                    self.startStreamingButon.alpha = 0.5
                }
                
                }, failure: { (error, message) -> () in
                    
                    self.stopStreamingButton.enabled = true
                    self.stopStreamingButton.alpha = 1.0
                    self.startStreamingButon.enabled = false
                    self.startStreamingButon.alpha = 0.5
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
            self.stopStreamingButton.enabled = true
            self.stopStreamingButton.alpha = 1.0
            self.startStreamingButon.enabled = false
            self.startStreamingButon.alpha = 0.5
            ErrorManager.sharedInstance.authenticationIssue()
        }
    }
    
    deinit
    {
        currentStreamingTocken = nil
    }
}
